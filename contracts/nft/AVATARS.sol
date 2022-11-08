pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import "../lib/helpers/Errors.sol";

contract AVATARS is Initializable, ERC721PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, ChainlinkClient, IERC2981Upgradeable {
    using SafeMathUpgradeable for uint256;
    // supply
    uint256 constant _max = 5000;
    uint256 constant _maxUser = 4500;

    address public _admin;
    address public _paramsAddress;

    string public _algorithm;
    uint256 public _counter;
    string public _uri;

    // mint condition
    // Sweet nft
    address public _tokenAddrErc721;
    // check trait shape
    string[] private _shapes = [
    "Pillhead",
    "Smiler",
    "Spektral",
    "Helix",
    "Tesseract",
    "Torus",
    "Obelisk"
    ];
    mapping(string => uint) private _availableShapes;
    uint private _numAvailableShapes;

    uint256 public _fee;
    mapping(address => uint) _whiteList;

    // Oracle
    bytes32 public _oracleJobId;
    uint256 public _oracleFee;
    string public _oracleUrl;

    //
    // Avatars traits
    //
    // TODO
    string[] private _nations = [
    "England",
    "Italia"
    ];

    enum EMOTION {NORMAL, CRY, HAPPY}
    mapping(string => EMOTION) _nationsEmo;
    enum Result {UNKNOWN, HOMETEAMWIN, AWAYTEAMWIN, DRAW, PENDING}


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

        _availableShapes["Pillhead"] = 1;
        _numAvailableShapes = 1;
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

    function setAlgo(string memory algo) public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _algorithm = algo;
    }

    function pause() external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _pause();
    }

    function unpause() external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _unpause();
    }

    function withdraw(address erc20Addr, uint256 amount) external nonReentrant {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        bool success;
        if (erc20Addr == address(0x0)) {
            require(address(this).balance >= amount);
            (success,) = msg.sender.call{value : amount}("");
            require(success);
        } else {
            IERC20Upgradeable tokenERC20 = IERC20Upgradeable(erc20Addr);
            // transfer erc-20 token
            require(tokenERC20.transfer(msg.sender, amount));
        }
    }

    function addWhitelist(address[] memory addrs, uint256 count) external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);

        for (uint i = 0; i < addrs.length; i++) {
            _whiteList[addrs[i]] = count;
        }
    }

    function rand(uint256 id, string memory trait, string[] memory values) internal pure returns (string memory) {
        uint256 k = uint256(keccak256(abi.encodePacked(trait, toString(id))));
        return values[k % values.length];
    }

    function getNation(uint256 id) public view returns (string memory) {
        return rand(id, "nation", _nations);
    }

    function getParamValues(uint256 tokenId) public view returns (EMOTION emo, string memory nation) {
        nation = getNation(tokenId);
        return (_nationsEmo[nation], nation);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {return "0";}
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;

        }
        return string(buffer);
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function changeBaseURI(string memory baseURI) public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _uri = baseURI;
    }

    function mintByToken(uint256 tokenIdGated) public nonReentrant {
        require(_tokenAddrErc721 != address(0), Errors.INV_ADD);
        // check shapes
        if (_numAvailableShapes > 0) {
            require(_availableShapes[rand(tokenIdGated, "shape", _shapes)] == 1, Errors.INV_PARAMS);
        }
        // erc-721
        IERC721Upgradeable token = IERC721Upgradeable(_tokenAddrErc721);
        // burn
        token.safeTransferFrom(msg.sender, address(0), tokenIdGated);

        require(_counter < _maxUser);
        _counter++;
        _safeMint(msg.sender, _counter);
    }

    function mint() public nonReentrant payable {
        require(_fee > 0 && msg.value >= _fee, Errors.INV_FEE_PROJECT);
        require(_counter < _maxUser);
        _counter++;
        _safeMint(msg.sender, _counter);
    }

    function mintWhitelist() public nonReentrant payable {
        require(_whiteList[msg.sender] > 0, Errors.INV_ADD);
        require(_counter < _maxUser);
        _counter++;
        _safeMint(msg.sender, _counter);
        _whiteList[msg.sender] -= 1;
    }

    function ownerMint(uint256 id) public nonReentrant {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        require(id > _maxUser && id <= _max);
        _safeMint(msg.sender, id);
    }

    /** @dev EIP2981 royalties implementation. */
    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _admin;
        royaltyAmount = (_salePrice * 500) / 10000;
    }

    ///
    // Oracle
    ///
    using Chainlink for Chainlink.Request;
    function changeOracle(bytes32 jobId, uint256 fee, string memory url) external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _oracleJobId = jobId;
        // 0,1 * 10**18 (Varies by network and job)
        //        _fee = (1 * LINK_DIVISIBILITY) / 10;
        _oracleFee = fee;
        _oracleUrl = url;
    }

    function fulfill(bytes32 requestId, bytes memory gameData) public recordChainlinkFulfillment(requestId) {
        // TODO
        (bytes32 gameId, string memory home, string memory away, uint homeTeamGoals, uint awayTeamGoals, uint8 status) = abi.decode(gameData, (bytes32, string, string, uint8, uint8, uint8));
        Result result = determineResult(homeTeamGoals, awayTeamGoals);
        if (result == Result.HOMETEAMWIN) {
            _nationsEmo[home] = EMOTION.HAPPY;
            _nationsEmo[away] = EMOTION.CRY;
        } else if (result == Result.AWAYTEAMWIN) {
            _nationsEmo[home] = EMOTION.CRY;
            _nationsEmo[away] = EMOTION.HAPPY;
        } else {
            _nationsEmo[home] = EMOTION.NORMAL;
            _nationsEmo[away] = EMOTION.NORMAL;
        }
    }

    function determineResult(uint homeTeam, uint awayTeam) internal view returns (Result) {
        if (homeTeam > awayTeam) {return Result.HOMETEAMWIN;}
        if (homeTeam == awayTeam) {return Result.DRAW;}
        return Result.AWAYTEAMWIN;
    }

    function requestData(bytes32 _gameId) public returns (bytes32 requestId) {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        Chainlink.Request memory req = buildChainlinkRequest(_oracleJobId, address(this), this.fulfill.selector);

        // Set the URL to perform the GET request on
        req.add('get', string(abi.encodePacked(_oracleUrl, "/game/", _gameId, "/data")));

        // Chainlink nodes prior to 1.0.0 support this format
        // request.add("path", "k1.k2.k3.k4..."); 
        req.add('path', "DATA.GAME");
        // Chainlink nodes 1.0.0 and later support this format

        // Sends the request
        return sendChainlinkRequest(req, _oracleFee);
    }

    function withdrawLink() public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }
}
