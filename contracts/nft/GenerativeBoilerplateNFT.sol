// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../lib/helpers/Errors.sol";
import "../lib/configurations/GenerativeBoilerplateNFTConfiguration.sol";
import "../lib/helpers/Random.sol";
import "../lib/helpers/BoilerplateParam.sol";
import "../lib/helpers/StringUtils.sol";
import "../interfaces/IGenerativeBoilerplateNFT.sol";
import "../interfaces/IGenerativeNFT.sol";
import "../interfaces/IGenerativeNFT2.sol";
import "../interfaces/IParameterControl.sol";

contract GenerativeBoilerplateNFT is Initializable, ERC721PausableUpgradeable, ReentrancyGuardUpgradeable, IERC2981Upgradeable, IGenerativeBoilerplateNFT {
    using ClonesUpgradeable for *;
    using SafeMathUpgradeable for uint256;

    // super admin
    address public _admin;
    // parameter control address
    address public _paramsAddress;

    // projectId is tokenID of project nft
    uint256 private _currentProjectId;

    mapping(uint256 => BoilerplateParam.ProjectInfo) public _projects;

    // mapping seed -> project -> owner
    mapping(bytes32 => mapping(uint256 => address)) _seedOwners;

    // mapping seed already minting
    mapping(bytes32 => mapping(uint256 => bool)) _seedToTokens;

    function initialize(
        string memory name,
        string memory symbol,
        address admin,
        address paramsAddress
    ) initializer public {
        require(admin != address(0), Errors.INV_ADD);
        require(paramsAddress != address(0), Errors.INV_ADD);
        __ERC721_init(name, symbol);
        _paramsAddress = paramsAddress;
        _admin = admin;
    }

    function changeAdmin(address newAdm, address newParam) external {
        require(msg.sender == _admin && newAdm != address(0), Errors.ONLY_ADMIN_ALLOWED);

        // change admin
        if (_admin != newAdm) {
            address _previousAdmin = _admin;
            _admin = newAdm;
        }

        // change param
        require(newParam != address(0));
        if (_paramsAddress != newParam) {
            _paramsAddress = newParam;
        }
    }

    function paymentMintProject() internal {
        if (msg.sender != _admin) {
            IParameterControl _p = IParameterControl(_paramsAddress);
            // at least require value 1ETH
            uint256 operationFee = _p.getUInt256(GenerativeBoilerplateNFTConfiguration.CREATE_PROJECT_FEE);
            if (operationFee > 0) {
                address operationFeeToken = _p.getAddress(GenerativeBoilerplateNFTConfiguration.FEE_TOKEN);
                if (!(operationFeeToken == address(0))) {
                    IERC20Upgradeable tokenERC20 = IERC20Upgradeable(operationFeeToken);
                    // transfer erc-20 token to this contract
                    require(tokenERC20.transferFrom(
                            msg.sender,
                            address(this),
                            operationFee
                        ));
                } else {
                    require(msg.value >= operationFee);
                }
            }
        }
    }

    // use case on project which can only be minted through this contract
    function mintProject(
        address to,
        string memory projectName,
        uint256 maxSupply,
        uint256 limit,
        uint32 scriptType,
        bool clientSeed,
        string memory uri,
        uint256 fee,
        address feeAdd,
        BoilerplateParam.ParamTemplate[] memory paramsTemplate
    ) external nonReentrant payable returns (uint256) {
        require(bytes(projectName).length > 3, Errors.MISSING_NAME);

        _currentProjectId++;
        IParameterControl _p = IParameterControl(_paramsAddress);
        paymentMintProject();
        _projects[_currentProjectId]._customUri = uri;
        _projects[_currentProjectId]._projectName = projectName;
        _projects[_currentProjectId]._creator = msg.sender;
        _projects[_currentProjectId]._fee = fee;
        _projects[_currentProjectId]._feeToken = feeAdd;
        for (uint8 i = 0; i < paramsTemplate.length; i++) {
            _projects[_currentProjectId]._paramsTemplate.push(paramsTemplate[i]);
            if (paramsTemplate[i]._editable && !_projects[_currentProjectId]._editable) {
                _projects[_currentProjectId]._editable = paramsTemplate[i]._editable;
            }
        }

        _projects[_currentProjectId]._scriptType = scriptType;
        _projects[_currentProjectId]._clientSeed = clientSeed;

        _safeMint(to, _currentProjectId);

        // deploy new by clone from template address
        address generativeNFTAdd = ClonesUpgradeable.clone(_p.getAddress(GenerativeBoilerplateNFTConfiguration.GENERATIVE_NFT_TEMPLATE));
        IGenerativeNFT nft = IGenerativeNFT(generativeNFTAdd);
        nft.init(
            BoilerplateParam.InitMinterNFTInfo(_projects[_currentProjectId]._projectName,
            StringUtils.getSlice(1, 3, _projects[_currentProjectId]._projectName),
            _p.get(GenerativeBoilerplateNFTConfiguration.NFT_BASE_URI),
            _admin,
            maxSupply,
            limit,
            _currentProjectId,
            fee,
            feeAdd,
            _projects[_currentProjectId]._creator,
            _paramsAddress)
        );
        _projects[_currentProjectId]._minterNFTInfo = generativeNFTAdd;

        return _currentProjectId;
    }

    // use case on project which can be minted by its directly
    function mintProject2(
        address to,
        string memory projectName,
        uint256 maxSupply,
        uint256 limit,
        uint32 scriptType,
        bool clientSeed,
        string memory uri,
        uint256 fee,
        address feeAdd,
        BoilerplateParam.ParamTemplate[] memory paramsTemplate
    ) external nonReentrant payable returns (uint256) {
        require(bytes(projectName).length > 3, Errors.MISSING_NAME);

        _currentProjectId++;
        IParameterControl _p = IParameterControl(_paramsAddress);
        paymentMintProject();
        _projects[_currentProjectId]._customUri = uri;
        _projects[_currentProjectId]._projectName = projectName;
        _projects[_currentProjectId]._creator = msg.sender;
        _projects[_currentProjectId]._fee = fee;
        _projects[_currentProjectId]._feeToken = feeAdd;
        for (uint8 i = 0; i < paramsTemplate.length; i++) {
            _projects[_currentProjectId]._paramsTemplate.push(paramsTemplate[i]);
            // require project can not be editable
            require(!paramsTemplate[i]._editable);
        }

        _projects[_currentProjectId]._scriptType = scriptType;
        // always false for this kind of project
        _projects[_currentProjectId]._clientSeed = false;

        _safeMint(to, _currentProjectId);

        // deploy new by clone from template address
        address generativeNFTAdd2 = ClonesUpgradeable.clone(_p.getAddress(GenerativeBoilerplateNFTConfiguration.GENERATIVE_NFT_TEMPLATE2));
        IGenerativeNFT2 nft = IGenerativeNFT2(generativeNFTAdd2);
        nft.init(
            BoilerplateParam.InitMinterNFTInfo(_projects[_currentProjectId]._projectName,
            StringUtils.getSlice(1, 3, _projects[_currentProjectId]._projectName),
            _p.get(GenerativeBoilerplateNFTConfiguration.NFT_BASE_URI),
            _admin,
            maxSupply,
            limit,
            _currentProjectId,
            fee,
            feeAdd,
            _projects[_currentProjectId]._creator,
            _paramsAddress)
        );
        _projects[_currentProjectId]._minterNFTInfo = generativeNFTAdd2;

        return _currentProjectId;
    }

    function setScript(uint256 projectId, string memory script) external {
        require(msg.sender == _projects[projectId]._creator);
        _projects[projectId]._script = script;
    }

    // registerSeed
    // set seed to chain from client
    function registerSeed(uint256 projectId, bytes32 seed) external {
        require(_projects[projectId]._clientSeed && _exists(projectId));
        require(_seedOwners[seed][projectId] == address(0x0));
        _seedOwners[seed][projectId] = msg.sender;
    }

    function paymentMintNFT(uint256 projectId, BoilerplateParam.ProjectInfo memory project) internal {
        if (ownerOf(projectId) != msg.sender) {// not owner of project -> get payment
            IParameterControl _p = IParameterControl(_paramsAddress);
            uint256 operationFee = _p.getUInt256(GenerativeBoilerplateNFTConfiguration.MINT_NFT_FEE);
            if (operationFee == 0) {
                operationFee = 500;
                // default 5% getting, 95% pay for owner of project
            }
            if (project._feeToken == address(0x0)) {
                require(msg.value >= project._fee);

                // pay for owner project
                (bool success,) = ownerOf(projectId).call{value : project._fee - (project._fee * operationFee / 10000)}("");
                require(success);
            } else {
                IERC20Upgradeable tokenERC20 = IERC20Upgradeable(project._feeToken);
                // transfer all fee erc-20 token to this contract
                require(tokenERC20.transferFrom(
                        msg.sender,
                        address(this),
                        project._fee
                    ));

                // pay for owner project
                require(tokenERC20.transfer(ownerOf(projectId), project._fee - (project._fee * operationFee / 10000)));
            }
        }
    }

    function verifySeed(uint256 projectId, BoilerplateParam.ProjectInfo memory project, BoilerplateParam.ParamsOfNFT memory paramValue) internal returns (BoilerplateParam.ParamsOfNFT memory) {
        // TODO
        if (!project._clientSeed) {// seed on chain
            paramValue._seed = Random.randomSeed(msg.sender, projectId);
            _seedOwners[paramValue._seed][projectId] = msg.sender;

        } else {// seed off-chain
            // require seed still not registerSeeds
            require(_seedOwners[paramValue._seed][projectId] == address(0));
            // seed not already used
            require(!_seedToTokens[paramValue._seed][projectId], Errors.SEED_INV);
            // marked this seed is already used
            _seedToTokens[paramValue._seed][projectId] = false;
        }
        return paramValue;
    }

    function mintNFT(uint256 _fromProjectId, BoilerplateParam.ParamsOfNFT memory paramValue) public nonReentrant payable {
        BoilerplateParam.ProjectInfo memory project = _projects[_fromProjectId];
        require(project._paramsTemplate.length == paramValue._value.length || !project._editable, Errors.INV_PARAMS);

        // get payable
        uint256 _mintFee = project._fee;
        if (_mintFee > 0) {// has fee and
            paymentMintNFT(_fromProjectId, project);
        }

        IGenerativeNFT nft = IGenerativeNFT(project._minterNFTInfo);
        paramValue = verifySeed(_fromProjectId, project, paramValue);
        nft.mint(msg.sender, paramValue);
    }

    function ownerMintNFT(uint256 _fromProjectId, uint256 tokenId, BoilerplateParam.ParamsOfNFT memory paramValue) public nonReentrant payable {
        BoilerplateParam.ProjectInfo memory project = _projects[_fromProjectId];
        require(project._paramsTemplate.length == paramValue._value.length || !project._editable, Errors.INV_PARAMS);
        require(msg.sender == project._creator);

        // get payable
        uint256 _mintFee = project._fee;
        if (_mintFee > 0) {// has fee and
            paymentMintNFT(_fromProjectId, project);
        }

        IGenerativeNFT nft = IGenerativeNFT(project._minterNFTInfo);
        paramValue = verifySeed(_fromProjectId, project, paramValue);
        nft.ownerMint(msg.sender, tokenId, paramValue);
    }

    // setCreator
    // func for set new creator on projectId
    // only creator on projectId can make this func
    function setCreator(address _to, uint256 _id) external {
        require(_projects[_id]._creator == msg.sender, Errors.ONLY_CREATOR);
        _projects[_id]._creator = _to;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return _projects[_tokenId]._customUri;
    }

    function setTokenURI(string memory _uri, uint256 _id) external {
        require(_projects[_id]._creator == msg.sender, Errors.ONLY_CREATOR);
        _projects[_id]._customUri = _uri;
    }

    /** @dev EIP2981 royalties implementation. */
    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _admin;
        royaltyAmount = (_salePrice * 500) / 10000;
    }

    function withdraw(address receiver, address erc20Addr, uint256 amount) external nonReentrant {
        require(_msgSender() == _admin, Errors.ONLY_ADMIN_ALLOWED);
        bool success;
        if (erc20Addr == address(0x0)) {
            require(address(this).balance >= amount);
            (success,) = receiver.call{value : amount}("");
            require(success);
        } else {
            IERC20Upgradeable tokenERC20 = IERC20Upgradeable(erc20Addr);
            // transfer erc-20 token
            require(tokenERC20.transfer(receiver, amount));
        }
    }

    function getParamsTemplate(uint256 id) external view returns (BoilerplateParam.ParamTemplate[] memory) {
        return _projects[id]._paramsTemplate;
    }

    function pause() external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _pause();
    }

    function unpause() external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _unpause();
    }
}