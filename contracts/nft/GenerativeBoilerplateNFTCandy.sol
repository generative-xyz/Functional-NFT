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
import "../lib/helpers/BoilerplateParam.sol";
import "../lib/helpers/StringUtils.sol";
import "../interfaces/IGenerativeBoilerplateNFT.sol";
import "../interfaces/IGenerativeNFT.sol";
import "../interfaces/IParameterControl.sol";
import "../lib/helpers/TraitInfo.sol";

contract GenerativeBoilerplateNFTCandy is Initializable, ERC721PresetMinterPauserAutoIdUpgradeable, ReentrancyGuardUpgradeable, IERC2981Upgradeable, IGenerativeBoilerplateNFT {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using ClonesUpgradeable for *;
    using SafeMathUpgradeable for uint256;

    // super admin
    address public _admin;
    // parameter control address
    address public _paramsAddress;

    CountersUpgradeable.Counter private _nextTokenId;

    struct ProjectInfo {
        uint256 _fee; // default frees
        address _feeToken;// default is native token
        uint256 _mintMaxSupply; // max supply can be minted on project
        uint256 _mintTotalSupply; // total supply minted on project
        BoilerplateParam.ParamsOfProject _paramsTemplate; // struct contains list params of project and random seed(registered) in case mint nft from project
        uint256 _mintNotOwnerProjectMaxSupply; // limit for nminter is not owner of project
        string _script;
    }

    mapping(uint256 => ProjectInfo) public _projects;

    // params value for rendering -> mapping with tokenId of NFT
    mapping(uint256 => uint256[]) public _paramsValues;

    TraitInfo.Traits private _traits;

    mapping(uint256 => string) _customUri;
    mapping(uint256 => uint256) public _tokenProjectId;
    string private pBaseTokenURI;

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseUri,
        address admin,
        address paramsAddress
    ) initializer public {
        require(admin != address(0), Errors.INV_ADD);
        require(paramsAddress != address(0), Errors.INV_ADD);
        __ERC721PresetMinterPauserAutoId_init(name, symbol, baseUri);
        _paramsAddress = paramsAddress;
        _admin = admin;
        // set role for admin address
        grantRole(DEFAULT_ADMIN_ROLE, _admin);

        pBaseTokenURI = baseUri;
    }

    function updateTraits(TraitInfo.Traits calldata traits) external {
        require(msg.sender == _admin);
        _traits = traits;
    }

    function getTraits() public view returns (TraitInfo.Trait[] memory){
        return _traits._traits;
    }

    function getTokenTraits(uint256 tokenId) public view returns (TraitInfo.Trait[] memory){
        (bytes32 seed, BoilerplateParam.ParamTemplate[] memory _params) = getParamValues(tokenId);

        TraitInfo.Trait[] memory result = _traits._traits;
        if (result.length != _params.length) {
            return result;
        }
        for (uint8 i = 0; i < _params.length; i++) {
            uint256 val = _params[i]._value;
            if (result[i]._availableValues.length > 0) {
                result[i]._valueStr = result[i]._availableValues[val];
                result[i]._value = val;
            } else {
                result[i]._value = val;
            }
        }
        return result;
    }

    function getParamValues(uint256 tokenId) public view returns (bytes32, BoilerplateParam.ParamTemplate[] memory) {
        uint256[] memory values = _paramsValues[tokenId];
        bytes32 seed = keccak256(abi.encodePacked(tokenId));
        bytes32 oSeed = seed;

        BoilerplateParam.ParamsOfProject memory p = _projects[_tokenProjectId[tokenId]]._paramsTemplate;
        for (uint256 i = 0; i < p._params.length; i++) {
            if (!p._params[i]._editable) {
                if (p._params[i]._availableValues.length == 0) {
                    p._params[i]._value = Random.randomValueRange(uint256(seed), p._params[i]._min, p._params[i]._max);
                } else {
                    p._params[i]._value = Random.randomValueIndexArray(uint256(seed), p._params[i]._availableValues.length);
                }
            } else {
                p._params[i]._value = values[i];
            }
            seed = keccak256(abi.encodePacked(seed, p._params[i]._value));
        }
        return (oSeed, p._params);
    }

    function changeAdmin(address newAdm, address newParam) external {
        require(msg.sender == _admin && newAdm != address(0), Errors.ONLY_ADMIN_ALLOWED);

        // change admin
        if (_admin != newAdm) {
            address _previousAdmin = _admin;
            _admin = newAdm;
            grantRole(DEFAULT_ADMIN_ROLE, _admin);
            revokeRole(DEFAULT_ADMIN_ROLE, _previousAdmin);
        }

        // change param
        require(newParam != address(0));
        if (_paramsAddress != newParam) {
            _paramsAddress = newParam;
        }
    }

    function changeBaseTokenUri(string memory newUri) external {
        require(msg.sender == _admin && hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), Errors.ONLY_ADMIN_ALLOWED);
        pBaseTokenURI = newUri;
    }

    // disable old mint
    function mint(address to) public override {}
    // disable pause
    function pause() public override {}
    // disable unpause
    function unpause() public override {}
    // disable burn
    function burn(uint256 tokenId) public override {}

    function mintProject(
        address to,
        uint256 maxSupply,
        uint256 maxNotOwner,
        string memory script,
        uint256 fee,
        address feeAdd,
        BoilerplateParam.ParamsOfProject calldata paramsTemplate
    ) external nonReentrant payable returns (uint256) {
        require(msg.sender == _admin);

        uint256 currentProjectId = 1;
        require(_projects[currentProjectId]._paramsTemplate._params.length == 0, Errors.INV_PROJECT);

        _projects[currentProjectId]._mintMaxSupply = maxSupply;
        _projects[currentProjectId]._mintNotOwnerProjectMaxSupply = maxNotOwner;
        _projects[currentProjectId]._fee = fee;
        _projects[currentProjectId]._feeToken = feeAdd;
        _projects[currentProjectId]._script = script;
        _projects[currentProjectId]._paramsTemplate = paramsTemplate;

        return currentProjectId;
    }

    function updateProject(uint256 projectId,
        uint256 newFee, address newFeeAddr,
        address newMinterNFTInfo,
        uint256 maxSupply,
        uint256 totalSupply,
        uint256 notOwnerMaxSupply
    ) external {
        require(msg.sender == _admin && hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), Errors.ONLY_ADMIN_ALLOWED);
        _projects[projectId]._fee = newFee;
        _projects[projectId]._feeToken = newFeeAddr;
        _projects[projectId]._mintMaxSupply = maxSupply;
        _projects[projectId]._mintTotalSupply = totalSupply;
        _projects[projectId]._mintNotOwnerProjectMaxSupply = notOwnerMaxSupply;
    }

    function storeScript(uint256 projectId, string memory script) external {
        require(msg.sender == _admin && hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), Errors.ONLY_ADMIN_ALLOWED);
        require(_projects[projectId]._paramsTemplate._params.length > 0, Errors.INV_PROJECT);
        _projects[projectId]._script = script;
    }

    function mintUniqueNFT(address _mintTo,
        uint256[] memory _value,
        uint256 tokenId
    ) public nonReentrant payable {
        uint256 projectId = 1;
        ProjectInfo memory project = _projects[projectId];
        require(project._mintMaxSupply == 0 || project._mintTotalSupply + 1 <= project._mintMaxSupply, Errors.REACH_MAX);
        if (tokenId > 0) {
            require(msg.sender == _admin && project._mintNotOwnerProjectMaxSupply < tokenId && tokenId <= project._mintMaxSupply, Errors.INV_PARAMS);
        } else {
            require(msg.sender != _admin, Errors.INV_PARAMS);
            // use counter
            _nextTokenId.increment();
            tokenId = _nextTokenId.current();
            if (project._mintNotOwnerProjectMaxSupply > 0) {// not owner of project
                require(tokenId <= project._mintNotOwnerProjectMaxSupply);
            }
        }

        require(_projects[projectId]._paramsTemplate._params.length == _value.length, Errors.INV_PARAMS);
        string memory uri = string(
            abi.encodePacked(
                baseTokenURI(),
                StringsUpgradeable.toHexString(uint256(uint160(address(this))), 20),
                GenerativeBoilerplateNFTConfiguration.SEPERATE_URI,
                StringsUpgradeable.toString(1),
                GenerativeBoilerplateNFTConfiguration.SEPERATE_URI,
                StringsUpgradeable.toString(project._mintTotalSupply + 1)
            )
        );
        if (bytes(uri).length > 0) {
            _customUri[tokenId] = uri;
        }
        _paramsValues[tokenId] = _value;
        _safeMint(_mintTo, tokenId);
        _tokenProjectId[tokenId] = projectId;

        _projects[projectId]._mintTotalSupply += 1;
    }

    function totalSupply() public view override returns (uint256) {
        return _nextTokenId.current();
    }


    function baseTokenURI() virtual public view returns (string memory) {
        return pBaseTokenURI;
    }

    function setCustomURI(
        uint256 _tokenId,
        string memory _newURI
    ) public {
        require(msg.sender == _admin && hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), Errors.ONLY_ADMIN_ALLOWED);
        _customUri[_tokenId] = _newURI;
    }

    // tokenURI
    // return URI data of project
    // base on customUri of project of baseUri of erc-721
    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        bytes memory customUriBytes = bytes(_customUri[_tokenId]);
        if (customUriBytes.length > 0) {
            return _customUri[_tokenId];
        } else {
            return "";
        }
    }

    function exists(
        uint256 _id
    ) external view returns (bool) {
        return _exists(_id);
    }

    /** @dev EIP2981 royalties implementation. */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _admin;
        royaltyAmount = (_salePrice * 500) / 10000;
    }

    // withdraw
    // only Admin can withdraw operation fee on this contract
    // receiver: receiver address
    // erc20Addr: currency address
    // amount: amount
    function withdraw(address receiver, address erc20Addr, uint256 amount) external nonReentrant {
        require(msg.sender == _admin && hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), Errors.ONLY_ADMIN_ALLOWED);
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

    function getParamsTemplate(uint256 id) external view returns (BoilerplateParam.ParamsOfProject memory) {
        return _projects[id]._paramsTemplate;
    }
}