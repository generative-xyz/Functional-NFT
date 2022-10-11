// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../lib/helpers/Errors.sol";
import "../lib/configurations/GenerativeBoilerplateNFTConfiguration.sol";
import "../lib/helpers/Random.sol";
import "../lib/helpers/StringUtils.sol";
import "../lib/helpers/BoilerplateParam.sol";
import "../governance/ParameterControl.sol";
import "./GenerativeNFT.sol";

contract GenerativeBoilerplateNFT is Initializable, ERC721PresetMinterPauserAutoIdUpgradeable, ReentrancyGuardUpgradeable, IERC2981Upgradeable {
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
        BoilerplateParam.projectParams _paramsTemplate;
    }

    struct MintRequest {
        uint256 _fromProjectId;
        address _mintTo;
        string[] _uris;
        BoilerplateParam.projectParams[] _paramTemplateValues;
    }

    mapping(uint256 => ProjectInfo) public _projects;

    // owner generated NFT -> projectId -> deployed generated NFT
    struct MinterInfo {
        mapping(uint256 => bytes32[]) _seeds;
        mapping(uint256 => address) _mintedNFTAddr;
    }

    mapping(address => MinterInfo)  _minterInfos;

    struct SeedToProject {
        uint256 _projectId;
        address _minter;
    }

    mapping(bytes32 => SeedToProject) public _seedToProjects;

    modifier adminOnly() {
        require(_msgSender() == _admin, Errors.ONLY_ADMIN_ALLOWED);
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), Errors.ONLY_ADMIN_ALLOWED);
        _;
    }

    modifier creatorOnly(uint256 _id) {
        require(_projects[_id]._creator == msg.sender, Errors.ONLY_CREATOR);
        _;
    }

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
        grantRole(PAUSER_ROLE, _admin);

        // revoke role for sender
        revokeRole(PAUSER_ROLE, msg.sender);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function changeAdmin(address newAdm) public adminOnly {
        address _previousAdmin = _admin;
        _admin = newAdm;

        grantRole(DEFAULT_ADMIN_ROLE, _admin);
        grantRole(PAUSER_ROLE, _admin);

        revokeRole(DEFAULT_ADMIN_ROLE, _previousAdmin);
        revokeRole(PAUSER_ROLE, _previousAdmin);
    }

    // disable old mint
    function mint(address to) public override {}
    // disable pause
    function pause() public override {}

    // disable unpause
    function unpause() public override {}

    // mint a Project token id
    // to: owner
    // name: name of project
    // maxSupply: max available nft supply which minted from this project
    // uri: metadata of project info
    // fee: fee mint nft from this project
    // feeAdd: currency for mint nft fee
    // paramsTemplate: json format string for render view template
    function mint(
        address to,
        string memory projectName,
        uint256 maxSupply,
        string memory script,
        uint32 scriptType,
        string memory uri,
        uint256 fee,
        address feeAdd,
        BoilerplateParam.projectParams calldata paramsTemplate
    ) public nonReentrant payable returns (uint256) {
        bytes memory nameChecked = bytes(projectName);
        require(nameChecked.length > 0, Errors.MISSING_NAME);
        _nextProjectId.increment();
        uint256 currentTokenId = _nextProjectId.current();

        ParameterControl _p = ParameterControl(_paramsAddress);
        uint256 operationFee = _p.getUInt256(GenerativeBoilerplateNFTConfiguration.CREATE_PROJECT_FEE);
        if (operationFee > 0) {
            address operationFeeToken = _p.getAddress(GenerativeBoilerplateNFTConfiguration.FEE_TOKEN);
            bool isNative = operationFeeToken == address(0x0);
            if (!isNative) {
                ERC20Upgradeable tokenERC20 = ERC20Upgradeable(operationFeeToken);
                require(tokenERC20.allowance(msg.sender, address(this)) >= operationFee, Errors.NOT_ALLOWANCE);
                require(tokenERC20.balanceOf(msg.sender) >= operationFee, Errors.INSUFF);
                // tranfer erc-20 token to this contract
                bool success = tokenERC20.transferFrom(
                    msg.sender,
                    address(this),
                    operationFee
                );
                require(success == true, Errors.TRANSFER_FAIL_ERC_20);
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

        _safeMint(to, currentTokenId);

        return currentTokenId;
    }

    // preMintUniqueNFT - random seed from chain in case project require
    function preMintUniqueNFT(uint256 projectId, uint256 amount) external {
        require(!_projects[projectId]._clientSeed, Errors.SEED_CLIENT);
        for (uint256 i = _minterInfos[msg.sender]._seeds[projectId].length; i < _minterInfos[msg.sender]._seeds[projectId].length + amount; i++) {
            _minterInfos[msg.sender]._seeds[projectId].push(Random.randomSeed(msg.sender, projectId, i));
        }
    }

    // mintBatchUniqueNFT
    // from projectId -> get algo and minting an batch unique nfr on GenerativeNFT contract collection
    function mintBatchUniqueNFT(
        MintRequest memory mintBatch
    ) public nonReentrant payable returns (address newContract) {
        ProjectInfo memory project = _projects[mintBatch._fromProjectId];
        require(mintBatch._uris.length > 0, Errors.EMPTY_LIST);
        require(mintBatch._uris.length == mintBatch._paramTemplateValues.length, Errors.INV_PARAMS);
        require(project._mintMaxSupply == 0 || project._mintTotalSupply + mintBatch._uris.length <= project._mintMaxSupply, Errors.REACH_MAX);
        ParameterControl _p = ParameterControl(_paramsAddress);

        // get payable
        bool success;
        uint256 _mintFee = project._fee;
        if (_mintFee > 0) {
            _mintFee *= mintBatch._uris.length;
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
                ERC20Upgradeable tokenERC20 = ERC20Upgradeable(project._feeToken);
                require(tokenERC20.allowance(msg.sender, address(this)) >= _mintFee, Errors.NOT_ALLOWANCE);
                require(tokenERC20.balanceOf(msg.sender) >= _mintFee, Errors.INSUFF);

                // transfer all fee erc-20 token to this contract
                success = tokenERC20.transferFrom(
                    msg.sender,
                    address(this),
                    _mintFee
                );
                require(success == true, Errors.TRANSFER_FAIL_ERC_20);

                // pay for owner project
                success = tokenERC20.transfer(ownerOf(mintBatch._fromProjectId), _mintFee - (_mintFee * operationFee / 10000));
                require(success == true, Errors.TRANSFER_FAIL_ERC_20);
            }
        }

        address generativeNFTAdd = _minterInfos[msg.sender]._mintedNFTAddr[mintBatch._fromProjectId];
        GenerativeNFT nft;
        for (uint256 i = 0; i < mintBatch._paramTemplateValues.length; i++) {
            BoilerplateParam.projectParams memory projectParams = mintBatch._paramTemplateValues[i];
            bytes32 seed = _minterInfos[msg.sender]._seeds[mintBatch._fromProjectId][projectParams.seedIndex];
            require((project._clientSeed // trust client seed
            || seed == mintBatch._paramTemplateValues[i].seed) // get seed from contract
                && _seedToProjects[seed]._projectId == 0 // seed not already used
            , Errors.SEED_INV);
            if (generativeNFTAdd == address(0x0)) {
                // deploy new by clone from template address
                generativeNFTAdd = ClonesUpgradeable.clone(_p.getAddress(GenerativeBoilerplateNFTConfiguration.GENERATIVE_NFT_TEMPLATE));
                _minterInfos[msg.sender]._mintedNFTAddr[mintBatch._fromProjectId] = generativeNFTAdd;

                nft = GenerativeNFT(generativeNFTAdd);
                nft.init(StringUtils.generateCollectionName(project._projectName, msg.sender),
                    "",
                    msg.sender,
                    address(this),
                    mintBatch._fromProjectId);

            } else {
                nft = GenerativeNFT(generativeNFTAdd);
            }
            nft.mint(seed, mintBatch._mintTo, msg.sender, mintBatch._uris[i], projectParams, project._clientSeed);
            _seedToProjects[seed] = SeedToProject(mintBatch._fromProjectId, msg.sender);
            project._mintTotalSupply += 1;
        }
        return generativeNFTAdd;
    }

    // 
    function burn(uint256 tokenId) public override {
        //        _projects[tokenId]._creator = address(0x0);
        //        super.burn(tokenId);
    }

    function _setCreator(address _to, uint256 _id) internal creatorOnly(_id) {
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
        uint256 _tokenId,
        string memory _newURI
    ) public creatorOnly(_tokenId) {
        _projects[_tokenId]._customUri = _newURI;
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return _baseURI();
    }

    function mintMaxSupply(uint256 _tokenID) public view returns (uint256) {
        return _projects[_tokenID]._mintMaxSupply;
    }

    function mintTotalSupply(uint256 _tokenID) public view returns (uint256) {
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
    ) public adminOnly {
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
    function withdraw(address receiver, address erc20Addr, uint256 amount) external nonReentrant adminOnly {
        bool success = false;
        if (erc20Addr == address(0x0)) {
            require(address(this).balance >= amount, Errors.INSUFF);
            (success,) = receiver.call{value : amount}("");
            require(success, Errors.TRANSFER_FAIL_NATIVE);
        } else {
            ERC20Upgradeable tokenERC20 = ERC20Upgradeable(erc20Addr);
            require(tokenERC20.balanceOf(address(this)) > amount, Errors.INSUFF);
            // transfer erc-20 token
            success = tokenERC20.transfer(receiver, amount);
            require(success == true, Errors.TRANSFER_FAIL_ERC_20);
        }
    }
}