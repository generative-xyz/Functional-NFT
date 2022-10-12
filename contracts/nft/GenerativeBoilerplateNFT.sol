// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../lib/helpers/Errors.sol";
import "../lib/configurations/GenerativeBoilerplateNFTConfiguration.sol";
import "../lib/helpers/Random.sol";
import "../lib/helpers/StringUtils.sol";
import "../lib/helpers/BoilerplateParam.sol";
import "../interfaces/IGenerativeBoilerplateNFT.sol";
import "../interfaces/IGenerativeNFT.sol";
import "../interfaces/IParameterControl.sol";

contract GenerativeBoilerplateNFT is Initializable, ERC721PresetMinterPauserAutoIdUpgradeable, ReentrancyGuardUpgradeable, IERC2981Upgradeable, IGenerativeBoilerplateNFT {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using ClonesUpgradeable for *;
    using SafeMathUpgradeable for uint256;

    // super admin
    address public _admin;
    // parameter control address
    address public _paramsAddress;

    // projectId is tokenID of project nft
    CountersUpgradeable.Counter private _nextProjectId;

    struct ProjectInfo {
        uint256 _fee; // default frees
        address _feeToken;// default is native token
        uint256 _mintMaxSupply; // max supply can be minted on project
        uint256 _mintTotalSupply; // total supply minted on project
        string _script; // script render: 1/ simplescript 2/ ipfs:// protocol
        uint32 _scriptType; // script type: python, js, ....
        address _creator; // creator list for project, using for royalties
        string _customUri; // project info nft view
        string _projectName;
        bool _clientSeed;
        BoilerplateParam.ParamsOfProject _paramsTemplate;
    }

    struct MintRequest {
        uint256 _fromProjectId;
        address _mintTo;
        string[] _uriBatch;
        BoilerplateParam.ParamsOfProject[] _paramsBatch;
    }

    mapping(uint256 => ProjectInfo) public _projects;

    // map user address -> projectId ->  NFT collection address mint from project
    mapping(address => mapping(uint256 => address)) public  _minterNFTInfos;

    // mapping seed -> project -> owner
    mapping(bytes32 => mapping(uint256 => address)) _seedOwners;

    // mapping seed already minting
    mapping(bytes32 => mapping(uint256 => uint256)) _seedToTokens;

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseUri,
        address admin,
        address paramsAddress
    ) initializer public {
        require(admin != address(0x0), Errors.INV_ADD);
        require(paramsAddress != address(0x0), Errors.INV_ADD);
        __ERC721PresetMinterPauserAutoId_init(name, symbol, baseUri);
        _paramsAddress = paramsAddress;
        _admin = admin;
        // set role for admin address
        grantRole(DEFAULT_ADMIN_ROLE, _admin);

        // revoke role for sender
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function changeAdmin(address newAdm) external {
        require(_msgSender() == _admin, Errors.ONLY_ADMIN_ALLOWED);
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), Errors.ONLY_ADMIN_ALLOWED);

        address _previousAdmin = _admin;
        _admin = newAdm;

        grantRole(DEFAULT_ADMIN_ROLE, _admin);

        revokeRole(DEFAULT_ADMIN_ROLE, _previousAdmin);
    }

    // disable old mint
    function mint(address to) public override {}
    // disable pause
    function pause() public override {}
    // disable unpause
    function unpause() public override {}
    // disable burn
    function burn(uint256 tokenId) public override {}

    // mint a Project token id
    // to: owner
    // name: name of project
    // maxSupply: max available nft supply which minted from this project
    // uri: metadata of project info
    // fee: fee mint nft from this project
    // feeAdd: currency for mint nft fee
    // paramsTemplate: json format string for render view template
    function mintProject(
        address to,
        string memory projectName,
        uint256 maxSupply,
        string memory script,
        uint32 scriptType,
        bool clientSeed,
        string memory uri,
        uint256 fee,
        address feeAdd,
        BoilerplateParam.ParamsOfProject calldata paramsTemplate
    ) public nonReentrant payable returns (uint256) {
        require(bytes(projectName).length > 0, Errors.MISSING_NAME);
        _nextProjectId.increment();
        uint256 currentTokenId = _nextProjectId.current();
        require(!_exists(currentTokenId), Errors.INVALID_PROJECT);
        IParameterControl _p = IParameterControl(_paramsAddress);
        uint256 operationFee = _p.getUInt256(GenerativeBoilerplateNFTConfiguration.CREATE_PROJECT_FEE);
        if (operationFee > 0) {
            address operationFeeToken = _p.getAddress(GenerativeBoilerplateNFTConfiguration.FEE_TOKEN);
            bool isNative = operationFeeToken == address(0x0);
            if (!isNative) {
                IERC20Upgradeable tokenERC20 = IERC20Upgradeable(operationFeeToken);
                // transfer erc-20 token to this contract
                require(tokenERC20.transferFrom(
                        msg.sender,
                        address(this),
                        operationFee
                    ), Errors.TRANSFER_FAIL_ERC_20);
            } else {
                require(msg.value >= operationFee, Errors.TRANSFER_FAIL_NATIVE);
            }
        }


        if (bytes(uri).length > 0) {
            _projects[currentTokenId]._customUri = uri;
        }
        if (bytes(projectName).length > 0) {
            _projects[currentTokenId]._projectName = projectName;
        }
        _projects[currentTokenId]._creator = msg.sender;
        _projects[currentTokenId]._mintMaxSupply = maxSupply;
        require(fee >= 0, Errors.INV_FEE_PROJECT);
        _projects[currentTokenId]._fee = fee;
        _projects[currentTokenId]._feeToken = feeAdd;
        _projects[currentTokenId]._paramsTemplate = paramsTemplate;
        _projects[currentTokenId]._script = script;
        _projects[currentTokenId]._scriptType = scriptType;
        _projects[currentTokenId]._clientSeed = clientSeed;

        _safeMint(to, currentTokenId);

        return currentTokenId;
    }

    // generateSeeds - random seed from chain in case project require
    function generateSeeds(uint256 projectId, uint256 amount) external {
        require(!_projects[projectId]._clientSeed && _exists(projectId));
        bytes32 seed;
        bytes32[] memory seeds = new bytes32[](amount);
        for (uint256 i = 0; i < amount; i++) {
            seed = Random.randomSeed(msg.sender, projectId, i);
            require(_seedOwners[seed][projectId] == address(0));
            _seedOwners[seed][projectId] = msg.sender;
            seeds[i] = seed;
        }
        emit GenerateSeeds(msg.sender, projectId, seeds);
    }

    // registerSeed
    // set seed to chain from client
    function registerSeeds(uint256 projectId, bytes32[] memory seeds) external {
        require(_projects[projectId]._clientSeed && _exists(projectId));
        for (uint256 i = 0; i < seeds.length; i++) {
            require(_seedOwners[seeds[i]][projectId] == address(0x0));
            _seedOwners[seeds[i]][projectId] = msg.sender;
        }
    }

    // mintBatchUniqueNFT
    // from projectId -> get algo and minting an batch unique nfr on GenerativeNFT contract collection
    function mintBatchUniqueNFT(
        MintRequest memory mintBatch
    ) public nonReentrant payable returns (address newContract) {
        ProjectInfo memory project = _projects[mintBatch._fromProjectId];
        require(mintBatch._uriBatch.length > 0 && mintBatch._uriBatch.length == mintBatch._paramsBatch.length, Errors.INV_PARAMS);
        require(project._mintMaxSupply == 0 || project._mintTotalSupply + mintBatch._uriBatch.length <= project._mintMaxSupply, Errors.REACH_MAX);
        IParameterControl _p = IParameterControl(_paramsAddress);

        // get payable
        bool success;
        uint256 _mintFee = project._fee;
        if (_mintFee > 0) {
            _mintFee *= mintBatch._uriBatch.length;
            uint256 operationFee = _p.getUInt256(GenerativeBoilerplateNFTConfiguration.MINT_NFT_FEE);
            if (operationFee == 0) {
                operationFee = 500;
                // default 5% getting, 95% pay for owner of project
            }
            if (project._feeToken == address(0x0)) {
                require(msg.value >= _mintFee, Errors.TRANSFER_FAIL_NATIVE);

                // pay for owner project
                (success,) = ownerOf(mintBatch._fromProjectId).call{value : _mintFee - (_mintFee * operationFee / 10000)}("");
                require(success, Errors.TRANSFER_FAIL_NATIVE);
            } else {
                IERC20Upgradeable tokenERC20 = IERC20Upgradeable(project._feeToken);
                // transfer all fee erc-20 token to this contract
                require(tokenERC20.transferFrom(
                        msg.sender,
                        address(this),
                        _mintFee
                    ), Errors.TRANSFER_FAIL_ERC_20);

                // pay for owner project
                require(tokenERC20.transfer(ownerOf(mintBatch._fromProjectId), _mintFee - (_mintFee * operationFee / 10000)), Errors.TRANSFER_FAIL_ERC_20);
            }
        }

        address generativeNFTAdd = _minterNFTInfos[msg.sender][mintBatch._fromProjectId];
        for (uint256 i = 0; i < mintBatch._paramsBatch.length; i++) {
            BoilerplateParam.ParamsOfProject memory projectParams = mintBatch._paramsBatch[i];
            bytes32 seed = mintBatch._paramsBatch[i]._seed;
            require(ownerOfSeed(seed, mintBatch._fromProjectId) == msg.sender // owner of seed
                && _seedToTokens[seed][mintBatch._fromProjectId] == 0 // seed not already used
            , Errors.SEED_INV);
            IGenerativeNFT nft;
            if (generativeNFTAdd == address(0x0)) {
                // deploy new by clone from template address
                generativeNFTAdd = ClonesUpgradeable.clone(_p.getAddress(GenerativeBoilerplateNFTConfiguration.GENERATIVE_NFT_TEMPLATE));
                _minterNFTInfos[msg.sender][mintBatch._fromProjectId] = generativeNFTAdd;

                nft = IGenerativeNFT(generativeNFTAdd);
                nft.init(StringUtils.generateCollectionName(project._projectName, msg.sender),
                    "",
                    msg.sender,
                    address(this),
                    mintBatch._fromProjectId);

            } else {
                nft = IGenerativeNFT(generativeNFTAdd);
            }
            nft.mint(seed, mintBatch._mintTo, msg.sender, mintBatch._uriBatch[i], projectParams, project._clientSeed);
            project._mintTotalSupply += 1;
            _seedToTokens[seed][mintBatch._fromProjectId] = project._mintTotalSupply;
        }
        return generativeNFTAdd;
    }

    function transferSeed(
        address from,
        address to,
        bytes32 seed, uint256 projectId
    ) external {
        require(ownerOfSeed(seed, projectId) != from, Errors.INV_ADD);
        require(to == address(0), Errors.INV_ADD);
        _seedOwners[seed][projectId] = to;
    }

    function ownerOfSeed(bytes32 seed, uint256 projectId) public view returns (address) {
        address explicitOwner = _seedOwners[seed][projectId];
        if (explicitOwner == address(0)) {
            return address(bytes20(seed));
        }
        return explicitOwner;
    }

    function _setCreator(address _to, uint256 _id) internal {
        require(_projects[_id]._creator == msg.sender, Errors.ONLY_CREATOR);
        _projects[_id]._creator = _to;
    }

    function setCreator(
        address _to,
        uint256[] memory _ids
    ) public {
        require(_to != address(0), Errors.INV_ADD);
        for (uint256 i = 0; i < _ids.length; i++) {
            _setCreator(_to, _ids[i]);
        }
    }

    function totalSupply() public view override returns (uint256) {
        return _nextProjectId.current() - 1;
    }

    function setCustomURI(
        uint256 _id,
        string memory _newURI
    ) public {
        require(_projects[_id]._creator == msg.sender, Errors.ONLY_CREATOR);
        _projects[_id]._customUri = _newURI;
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return _baseURI();
    }

    function mintMaxSupply(uint256 _tokenID) external view returns (uint256) {
        return _projects[_tokenID]._mintMaxSupply;
    }

    function mintTotalSupply(uint256 _tokenID) external view returns (uint256) {
        return _projects[_tokenID]._mintTotalSupply;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        if (bytes(_projects[_tokenId]._customUri).length > 0) {
            return _projects[_tokenId]._customUri;
        } else {
            return string(abi.encodePacked(baseTokenURI(), StringsUpgradeable.toString(_tokenId)));
        }
    }

    function exists(
        uint256 _id
    ) external view returns (bool) {
        return _exists(_id);
    }

    /** @dev EIP2981 royalties implementation. */
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
        bool isValue;
    }

    mapping(uint256 => RoyaltyInfo) public royalties;

    function setTokenRoyalty(
        uint256 _tokenId,
        address _recipient,
        uint256 _value
    ) external {
        require(_msgSender() == _admin, Errors.ONLY_ADMIN_ALLOWED);
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), Errors.ONLY_ADMIN_ALLOWED);
        require(_value <= 10000, Errors.REACH_MAX);
        royalties[_tokenId] = RoyaltyInfo(_recipient, uint24(_value), true);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalty = royalties[_tokenId];
        if (royalty.isValue) {
            receiver = royalty.recipient;
            royaltyAmount = (_salePrice * royalty.amount) / 10000;
        } else {
            receiver = _projects[_tokenId]._creator;
            royaltyAmount = (_salePrice * 500) / 10000;
        }
    }

    // withdraw
    // only Admin can withdraw operation fee on this contract
    // receiver: receiver address
    // erc20Addr: currency address
    // amount: amount
    function withdraw(address receiver, address erc20Addr, uint256 amount) external nonReentrant {
        require(_msgSender() == _admin, Errors.ONLY_ADMIN_ALLOWED);
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), Errors.ONLY_ADMIN_ALLOWED);
        bool success;
        if (erc20Addr == address(0x0)) {
            require(address(this).balance >= amount, Errors.INSUFF);
            (success,) = receiver.call{value : amount}("");
            require(success, Errors.TRANSFER_FAIL_NATIVE);
        } else {
            IERC20Upgradeable tokenERC20 = IERC20Upgradeable(erc20Addr);
            // transfer erc-20 token
            require(tokenERC20.transfer(receiver, amount), Errors.TRANSFER_FAIL_ERC_20);
        }
    }
}