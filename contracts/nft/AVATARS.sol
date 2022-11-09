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

    // @dev: supply for collection
    uint256 constant _max = 5000;
    uint256 constant _maxUser = 4500;

    // @dev: handler
    address public _admin;
    address public _paramsAddress;

    string public _algorithm;
    uint256 public _counter;
    string public _uri;

    // @dev: mint condition 
    // base on Sweet nft
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
    // base on fee
    uint256 public _fee;
    // base on whitelist
    mapping(address => uint) _whiteList;
    uint256 public _whitelistFee;

    // @dev: living data for collection
    struct NationEmo {
        string tempEmo;
        uint256 tempLastTime;
    }

    mapping(string => NationEmo) _nationsEmo;
    enum Result {UNKNOWN, HOMETEAMWIN, AWAYTEAMWIN, DRAW, PENDING}

    /** @dev Avatars traits
    */
    string[] private _nations = [
    "Qatar", "Ecuador", "Senegal", "Netherlands", // GA
    "England", "IR Iran", "USA", "Wales", // GB
    "Argentina", "Saudi Arabia", "Mexico", "Poland", // GC
    "France", "Australia", "Denmark", "Tunisia", //GD
    "Spain", "Costa Rica", "Germany", "Japan", //GE
    "Belgium", "Canada", "Morocco", "Croatia", //GF
    "Brazil", "Serbia", "Switzerland", "Cameroon", //GG
    "Portugal", "Ghana", "Uruguay", "Korea Republic" // GH
    ];
    string[] private _emotions = ["normal", "sad", "happy"];
    string[] private _emotionTimes = ["Forever", "1 day", "7 days", "30 days"];

    string[] private _dnas = ["male", "female", "robot", "ape", "alien", "ball head", "gold"];
    string private _skins = "none";
    string[] private _skins3 = ["dark", "bright", "yellow"];
    string private _beards = "none";
    string[] private _beards4 = ["none", "shape 1", "shape 2", "shape 3"];
    string private _hairs = "none";
    string[] private _hairs4 = ["none", "short", "long", "crazy"];
    string[] private _hairs3 = ["short", "long", "crazy"];

    string[] private _tops = ["tshirt", "hoodie"];
    string[] private _bottoms = ["shorts", "jogger"];
    uint private _numbers = 26;
    string[] private _shoes = ["reg 1", "reg 2", "reg 3", "spe 1", "spe 2", "spe 3"];
    string[] private _tatoos = ["none", "shape 1", "shape 2", "shape 3", "shape 4", "shape 5"];
    string[] private _glasses = ["none", "shape 1", "shape 2", "shape 3"];
    string[] private _gloves = ["none", "have"];

    struct Player {
        string _emotion;
        string _emotionTime;
        string _nation;
        string _dna;
        string _skin;
        string _beard;
        string _hair;
        string _shoes;
        string _top;
        string _bottom;
        uint256 _number;
        string _tatoo;
        string _glasses;
        string _gloves;
    }

    function initialize(
        string memory name,
        string memory symbol,
        address admin,
        address paramsAddress,
        address LINK_TOKEN,
        address ORACLE
    ) initializer public {
        require(admin != address(0), Errors.INV_ADD);
        require(paramsAddress != address(0), Errors.INV_ADD);
        __ERC721_init(name, symbol);
        _paramsAddress = paramsAddress;
        _admin = admin;

        // init for oracle
        setChainlinkToken(LINK_TOKEN);
        setChainlinkOracle(ORACLE);

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

    /* @TRAITS: Get data for render
    */
    function rand(uint256 id, string memory trait, string[] memory values) internal pure returns (string memory) {
        uint256 k = uint256(keccak256(abi.encodePacked(trait, toString(id))));
        return values[k % values.length];
    }

    function randUint256(uint256 id, string memory trait, uint256 min, uint256 max) internal pure returns (uint256) {
        uint256 k = uint256(keccak256(abi.encodePacked(trait, toString(id))));
        return (min + k % (max - min + 1));
    }

    function getNation(uint256 id) internal view returns (string memory) {
        return rand(id, "nation", _nations);
    }

    function getDNA(uint256 id) internal view returns (string memory) {
        return rand(id, "dna", _dnas);
    }

    function getSkin(uint256 id) internal view returns (string memory) {
        bytes32 dna = keccak256(abi.encodePacked(getDNA(id)));
        bytes32 b2 = keccak256(abi.encodePacked(_dnas[2]));
        bytes32 b3 = keccak256(abi.encodePacked(_dnas[3]));
        bytes32 b4 = keccak256(abi.encodePacked(_dnas[4]));
        bytes32 b5 = keccak256(abi.encodePacked(_dnas[5]));
        bytes32 b6 = keccak256(abi.encodePacked(_dnas[6]));

        if (dna == b2 || dna == b3 || dna == b4 || dna == b5 || dna == b6) {
            return _skins;
        }
        return rand(id, "skin", _skins3);
    }

    function getBeard(uint256 id) internal view returns (string memory) {
        bytes32 dna = keccak256(abi.encodePacked(getDNA(id)));
        bytes32 b1 = keccak256(abi.encodePacked(_dnas[1]));
        bytes32 b2 = keccak256(abi.encodePacked(_dnas[2]));
        bytes32 b3 = keccak256(abi.encodePacked(_dnas[3]));
        bytes32 b4 = keccak256(abi.encodePacked(_dnas[4]));
        bytes32 b5 = keccak256(abi.encodePacked(_dnas[5]));
        bytes32 b6 = keccak256(abi.encodePacked(_dnas[6]));

        if (dna == b1 || dna == b2 || dna == b3 || dna == b4 || dna == b5 || dna == b6) {
            return _beards;
        }
        return rand(id, "beard", _beards4);
    }

    function getHair(uint256 id) internal view returns (string memory) {
        bytes32 dna = keccak256(abi.encodePacked(getDNA(id)));
        bytes32 b1 = keccak256(abi.encodePacked(_dnas[1]));
        bytes32 b2 = keccak256(abi.encodePacked(_dnas[2]));
        bytes32 b3 = keccak256(abi.encodePacked(_dnas[3]));
        bytes32 b4 = keccak256(abi.encodePacked(_dnas[4]));
        bytes32 b5 = keccak256(abi.encodePacked(_dnas[5]));
        bytes32 b6 = keccak256(abi.encodePacked(_dnas[6]));

        if (dna == b2 || dna == b3 || dna == b4 || dna == b5 || dna == b6) {
            return _hairs;
        } else if (dna == b2) {
            return rand(id, "hair", _hairs3);
        }
        return rand(id, "hair", _hairs4);
    }

    function getTop(uint256 id) internal view returns (string memory) {
        return rand(id, "top", _tops);
    }

    function getBottom(uint256 id) internal view returns (string memory) {
        return rand(id, "bottom", _bottoms);
    }

    function getNumber(uint256 id) internal view returns (uint256) {
        return randUint256(id, "number", 1, _numbers);
    }

    function getShoes(uint256 id) internal view returns (string memory) {
        return rand(id, "shoe", _shoes);
    }

    function getTatoo(uint256 id) internal view returns (string memory) {
        return rand(id, "tatoo", _tatoos);
    }

    function getGlasses(uint256 id) internal view returns (string memory) {
        return rand(id, "glasses", _glasses);
    }

    function getGloves(uint256 id) internal view returns (string memory) {
        return rand(id, "glovers", _glasses);
    }

    function getEmotionTime(uint256 id) internal view returns (string memory) {
        return rand(id, "emotionTime", _emotionTimes);
    }

    function getParamValues(uint256 tokenId) public view returns (Player memory player) {
        string memory nation = getNation(tokenId);
        string memory emotionTime = getEmotionTime(tokenId);
        string memory emo = _nationsEmo[nation].tempEmo;
        if (keccak256(abi.encodePacked(emotionTime)) != keccak256(abi.encodePacked(_emotionTimes[0]))) {
            uint256 eT = 86400;
            if (keccak256(abi.encodePacked(emotionTime)) == keccak256(abi.encodePacked(_emotionTimes[1]))) {
                eT = eT * 1;
            }
            else if (keccak256(abi.encodePacked(emotionTime)) == keccak256(abi.encodePacked(_emotionTimes[2]))) {
                eT = eT * 7;
            } else {
                eT = eT * 30;
            }
            if (block.timestamp - _nationsEmo[nation].tempLastTime > eT) {
                emo = _emotions[0];
            }
        }
        player = Player(emo, emotionTime, nation, getDNA(tokenId),
            getSkin(tokenId), getBeard(tokenId), getHair(tokenId),
            getShoes(tokenId), getTop(tokenId), getBottom(tokenId),
            getNumber(tokenId), getTatoo(tokenId),
            getGlasses(tokenId),
            getGloves(tokenId));
        return player;
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

    /* @URI: control uri
    */
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function changeBaseURI(string memory baseURI) public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _uri = baseURI;
    }

    /* @MINT mint nft
    */
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
        require(_whitelistFee > 0 && msg.value >= _whitelistFee, Errors.INV_FEE_PROJECT);
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

    /* @notice: Oracle feature
    */
    using Chainlink for Chainlink.Request;
    using CBORChainlink for BufferChainlink.buffer;
    struct GameCreate {
        uint32 gameId;
        uint40 startTime;
        string homeTeam;
        string awayTeam;
    }

    struct GameResolve {
        uint32 gameId;
        uint8 homeScore;
        uint8 awayScore;
        string status;
    }

    function changeOracle(address oracle) external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        setChainlinkOracle(oracle);
    }

    /**
     * @notice Stores the scheduled games.
     * @param requestId the request ID for fulfillment.
     * @param gameData the games data is resolved.
     */
    function fulfill(bytes32 requestId, bytes memory gameData) public recordChainlinkFulfillment(requestId) {
        (uint32 gameId, uint40 startTime, string memory home, string memory away, uint8 homeTeamGoals, uint8 awayTeamGoals, uint8 status) = abi.decode(gameData, (uint32, uint40, string, string, uint8, uint8, uint8));
        Result result = determineResult(homeTeamGoals, awayTeamGoals);
        if (result == Result.HOMETEAMWIN) {
            _nationsEmo[home].tempEmo = _emotions[2];
            _nationsEmo[away].tempEmo = _emotions[1];
        } else if (result == Result.AWAYTEAMWIN) {
            _nationsEmo[home].tempEmo = _emotions[1];
            _nationsEmo[away].tempEmo = _emotions[2];
        } else {
            _nationsEmo[home].tempEmo = _emotions[0];
            _nationsEmo[away].tempEmo = _emotions[0];
        }
        _nationsEmo[home].tempLastTime = block.timestamp;
        _nationsEmo[away].tempLastTime = block.timestamp;
    }

    /**
     * @notice Stores the scheduled games.
     * @param _requestId the request ID for fulfillment.
     * @param _result the games either to be created or resolved.
     */
    function fulfillSchedule(bytes32 _requestId, bytes[] memory _result) external recordChainlinkFulfillment(_requestId) {
        // TODO
    }

    function determineResult(uint homeTeam, uint awayTeam) internal view returns (Result) {
        if (homeTeam > awayTeam) {return Result.HOMETEAMWIN;}
        if (homeTeam == awayTeam) {return Result.DRAW;}
        return Result.AWAYTEAMWIN;
    }

    function requestData(bytes32 jobId, uint256 fee, string memory url, string memory path) public returns (bytes32 requestId) {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req.add('get', url);
        req.add('path', path);
        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    /**
     * @notice Requests the tournament games either to be created or to be resolved on a specific date.
     * @dev Requests the 'schedule' endpoint. Result is an array of GameCreate or GameResolve encoded (see structs).
     * @param jobId the jobID.
     * @param fee the LINK amount in Juels (i.e. 10^18 aka 1 LINK).
     // 77: FIFA World Cup
     * @param market the number associated with the type of market (see Data Conversions).
     * @param date the starting time of the event as a UNIX timestamp in seconds.
     */
    function requestSchedule(bytes32 jobId, uint256 fee, uint256 market, uint256 date) external {
        Chainlink.Request memory req = buildOperatorRequest(jobId, this.fulfillSchedule.selector);
        req.addUint("market", market);
        // 77: FIFA World Cup
        req.addUint("leagueId", 77);
        req.addUint("date", date);
        sendOperatorRequest(req, fee);
    }

    function withdrawLink() public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }
}
