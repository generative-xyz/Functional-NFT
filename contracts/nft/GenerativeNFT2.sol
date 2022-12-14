// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../lib/configurations/GenerativeBoilerplateNFTConfiguration.sol";
import "../lib/helpers/Random.sol";
import "../lib/helpers/Errors.sol";
import "../lib/helpers/BoilerplateParam.sol";
import "../lib/helpers/TraitInfo.sol";
import "../interfaces/IGenerativeNFT2.sol";
import "../interfaces/IGenerativeBoilerplateNFT.sol";
import "../interfaces/IParameterControl.sol";

contract GenerativeNFT2 is ERC721Pausable, ReentrancyGuard, IERC2981, IGenerativeNFT2, Ownable {
    // admin of collection -> owner, creator, ...
    address public _admin;
    // linked boilerplate address
    address public _boilerplateAddr;
    // linked projectId in boilerplate
    uint256 public _boilerplateId;

    TraitInfo.Traits private _traits;

    string private _nameColl;
    string private _symbolColl;
    string private _uri;

    uint256 public n;

    uint256 public _max; // max supply can be minted on project
    uint256 public _limit; // limit for nminter is not owner of project

    uint256 public _fee;
    address public _feeToken;
    address public _creator;
    address public _paramsAddress;

    constructor(
        string memory name,
        string memory symbol,
        address admin
    ) ERC721(name, symbol) {
        _admin = admin;
    }

    function owner() public view override returns (address) {
        return _admin;
    }

    function _checkOwner() internal view override {
        require(owner() == msg.sender || msg.sender == _boilerplateAddr, "Ownable: caller is not the owner");
    }

    function init(
        BoilerplateParam.InitMinterNFTInfo memory p
    ) external {
        require(p._admin != address(0x0), "INV_ADD");
        require(_boilerplateId == 0, "EXISTED");

        _nameColl = p._name;
        _symbolColl = p._symbol;
        _uri = p._uri;
        _boilerplateAddr = msg.sender;
        _boilerplateId = p._projectId;
        _max = p._max;
        _limit = p._limit;
        _fee = p._fee;
        _feeToken = p._feeToken;
        _admin = p._admin;
        _creator = p._creator;
        _paramsAddress = p._paramsAddress;
        transferOwnership(p._admin);
    }

    function updateTraits(TraitInfo.Traits calldata traits) external {
        require(msg.sender == _admin || msg.sender == _boilerplateAddr, Errors.ONLY_ADMIN_ALLOWED);
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

    function name() public view override returns (string memory) {
        return _nameColl;
    }

    function symbol() public view override returns (string memory) {
        return _symbolColl;
    }

    modifier adminOnly() {
        require(_msgSender() == _admin, "ONLY_ADMIN_ALLOWED");
        _;
    }

    function changeAdmin(address _newAdmin) public adminOnly {
        require(_newAdmin != address(0), Errors.INV_ADD);
        address _previousAdmin = _admin;
        _admin = _newAdmin;
    }

    function changeBoilerplate(address newBoilerplate, uint256 newBoilerplateId) public adminOnly {
        require(newBoilerplate != address(0), Errors.INV_ADD);
        _boilerplateAddr = newBoilerplate;
        _boilerplateId = newBoilerplateId;
    }

    function changeBaseURI(string memory baseURI) public adminOnly {
        _uri = baseURI;
    }

    function paymentMintNFT() internal {
        if (_creator != msg.sender) {// not owner of project -> get payment
            IParameterControl _p = IParameterControl(_paramsAddress);
            // default 5% getting, 95% pay for owner of project
            uint256 operationFee = 500;
            if (_paramsAddress != address(0)) {
                operationFee = _p.getUInt256(GenerativeBoilerplateNFTConfiguration.MINT_NFT_FEE);
            }
            if (_feeToken == address(0x0)) {
                require(msg.value >= _fee);

                // pay for owner project
                (bool success,) = _creator.call{value : _fee - (_fee * operationFee / 10000)}("");
                require(success);
                // pay for host _boilerplateAddr
                (success,) = _boilerplateAddr.call{value : _fee * operationFee / 10000}("");
            } else {
                IERC20Upgradeable tokenERC20 = IERC20Upgradeable(_feeToken);
                // transfer all fee erc-20 token to this contract
                require(tokenERC20.transferFrom(
                        msg.sender,
                        address(this),
                        _fee
                    ));

                // pay for owner project
                require(tokenERC20.transfer(_creator, _fee - (_fee * operationFee / 10000)));
                // pay for host _boilerplateAddr
                require(tokenERC20.transfer(_creator, _fee * operationFee / 10000));
            }
        }
    }

    function mint() external {
        require(_boilerplateAddr != address(0), Errors.INV_BOILERPLATE_ADD);
        require(_boilerplateId > 0, Errors.INV_PROJECT);
        paymentMintNFT();
        n++;
        require(n <= _limit, Errors.REACH_MAX);
        _safeMint(msg.sender, n);
    }

    function ownerMint(uint256 tokenId) external {
        require(_boilerplateAddr != address(0), Errors.INV_BOILERPLATE_ADD);
        require(_boilerplateId > 0, Errors.INV_PROJECT);
        require(tokenId > _limit && tokenId <= _max, Errors.REACH_MAX);
        paymentMintNFT();
        _safeMint(msg.sender, tokenId);
    }

    function getParamValues(uint256 tokenId) public view returns (bytes32, BoilerplateParam.ParamTemplate[] memory) {
        IGenerativeBoilerplateNFT b = IGenerativeBoilerplateNFT(_boilerplateAddr);
        BoilerplateParam.ParamTemplate[] memory p = b.getParamsTemplate(_boilerplateId);

        bytes32 originalSeed = keccak256(abi.encodePacked(Strings.toString(tokenId)));
        bytes32 seed = originalSeed;
        for (uint256 i = 0; i < p.length; i++) {
            if (!p[i]._editable) {
                if (p[i]._availableValues.length == 0) {
                    p[i]._value = Random.randomValueRange(uint256(seed), p[i]._min, p[i]._max);
                } else {
                    p[i]._value = Random.randomValueIndexArray(uint256(seed), p[i]._availableValues.length);
                }
            } else {
                p[i]._value = 0;
            }
            seed = keccak256(abi.encodePacked(seed, p[i]._value));
        }
        return (seed, p);
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(),
            Strings.toHexString(uint256(uint160(_boilerplateAddr)), 20),
            "/", Strings.toString(_boilerplateId),
            "/", Strings.toString(_tokenId)));
    }

    /** @dev EIP2981 royalties implementation. */
    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _admin;
        royaltyAmount = (_salePrice * 500) / 10000;
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
