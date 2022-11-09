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
    address public _be;
    address public _paramsAddress;

    string public _algorithm;
    uint256 public _counter;
    string public _uri;

    // @dev: mint condition 
    // base on Sweet nft
    address public _tokenAddrErc721;
    // base on fee
    uint256 public _fee;
    // base on whitelist
    mapping(address => uint) _whiteList;
    uint256 public _whitelistFee;

    // @dev: living data for collection
    struct Mood {
        string tempEmo;
        uint256 tempLastTime;
    }

    mapping(string => Mood) _moods;
    enum Result {U, H_W, A_W, D}

    /** @dev Avatars traits
    */
    string[] private _nations;
    string[] private _emotions;
    string[] private _emotionTimes;

    string[] private _dnas;
    string[] private _skins3;
    string[] private _beards4;
    string[] private _hairs4;
    string[] private _hairs3;

    string[] private _tops;
    string[] private _bottoms;
    string[] private _shoes;
    string[] private _tatoos;
    string[] private _glasses;
    string[] private _gloves;

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

    /**
     * @notice Initialize the link token and target oracle
     *
     * Mumbai polygon Testnet details:
     * Link Token: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     ** - Any API
     * Oracle: 0x40193c8518BB267228Fc409a613bDbD8eC5a97b3 (Chainlink DevRel)
     * jobId: 7da2702f37fd48e5b1b9a5715e3509b6
     * jobId bytes32: 0x3764613237303266333766643438653562316239613537313565333530396236
     ** - Enetpulse Sports Data Oracle
     * Oracle: 0xd5821b900e44db9490da9b09541bbd027fBecF4E
     * jobId: d110b5c4b83d42dca20e410ac537cd94
     * jobId bytes32: 0x6431313062356334623833643432646361323065343130616335333763643934
     *
     *
     * Ethereum Mainnet details:
     * Link Token: 0x514910771af9ca656af840dff83e8264ecf986ca
     * Oracle: 0x6A9e45568261c5e0CBb1831Bd35cA5c4b70375AE (Chainlink DevRel)
     * jobId: 7da2702f37fd48e5b1b9a5715e3509b6
     * jobId bytes32: 0x3764613237303266333766643438653562316239613537313565333530396236
     ** - Enetpulse Sports Data Oracle
     * Oracle: 0x6A9e45568261c5e0CBb1831Bd35cA5c4b70375AE (Chainlink DevRel)
     */
    function initialize(
        string memory name,
        string memory symbol,
        address admin,
        address paramsAddress,
        address sweet,
        address LINK_TOKEN,
        address ORACLE
    ) initializer public {
        require(admin != address(0), Errors.INV_ADD);
        require(paramsAddress != address(0), Errors.INV_ADD);
        __ERC721_init(name, symbol);
        _paramsAddress = paramsAddress;
        _admin = admin;
        _tokenAddrErc721 = sweet;

        // init for oracle
        setChainlinkToken(LINK_TOKEN);
        setChainlinkOracle(ORACLE);

        // init traits
        initTraits();
    }

    function initTraits() internal {
        _nations = [
        "Qatar", "Ecuador", "Senegal", "Netherlands", // GA
        "England", "IR Iran", "USA", "Wales", // GB
        "Argentina", "Saudi Arabia", "Mexico", "Poland", // GC
        "France", "Australia", "Denmark", "Tunisia", //GD
        "Spain", "Costa Rica", "Germany", "Japan", //GE
        "Belgium", "Canada", "Morocco", "Croatia", //GF
        "Brazil", "Serbia", "Switzerland", "Cameroon", //GG
        "Portugal", "Ghana", "Uruguay", "Korea Republic" // GH
        ];

        _emotions = ["0", "1", "2"];
        //["normal", "sad", "happy"];

        _emotionTimes = ["0", "1", "2", "3"];
        //["Forever", "1 day", "7 days", "30 days"];

        _dnas = ["0", "1", "2", "3", "4", "5"];
        //["male", "female", "robot", "ape", "alien", "ball head"];

        _skins3 = ["0", "1", "2"];
        //["dark", "bright", "yellow"];

        _beards4 = ["0", "1", "2", "3"];
        //["none", "shape 1", "shape 2", "shape 3"];

        _hairs4 = ["0", "1", "2", "3"];
        //["none", "short", "long", "crazy"];
        _hairs3 = ["1", "2", "3"];
        //["short", "long", "crazy"];

        _tops = ["0", "1"];
        //["tshirt", "hoodie"];

        _bottoms = ["0", "1"];
        //["shorts", "jogger"];

        _shoes = ["0", "1", "2", "3", "4", "5"];
        //["reg 1", "reg 2", "reg 3", "spe 1", "spe 2", "spe 3"];

        _tatoos = ["0", "1", "2", "3", "4", "5"];
        //["none", "shape 1", "shape 2", "shape 3", "shape 4", "shape 5"];

        _glasses = ["0", "1", "2", "3"];
        //["none", "shape 1", "shape 2", "shape 3"];
        _gloves = ["0", "1"];
        //["none", "have"];

    }

    function changeAdmin(address newAdm) external {
        require(msg.sender == _admin && newAdm != address(0), Errors.ONLY_ADMIN_ALLOWED);
        // change admin
        if (_admin != newAdm) {
            address _previousAdmin = _admin;
            _admin = newAdm;
        }
    }

    function setBE(address be) external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _be = be;
    }

    function setAlgo(string memory algo) public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _algorithm = algo;
    }

    function setFee(uint256 fee) public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _fee = fee;
    }

    function setWhitelistFee(uint256 whitelistFee) public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _whitelistFee = whitelistFee;
    }

    function pause() external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _pause();
    }

    function unpause() external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _unpause();
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success);
    }

    function addWhitelist(address[] memory addrs, uint256 count) external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);

        for (uint i = 0; i < addrs.length; i++) {
            _whiteList[addrs[i]] = count;
        }
    }

    function seeding(uint256 id, string memory trait) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(trait, StringsUpgradeable.toString(id))));
    }

    /* @TRAITS: Get data for render
    */
    function rand(uint256 id, string memory trait, string[] memory values) internal pure returns (string memory) {
        return values[seeding(id, trait) % values.length];
    }

    function randUint256(uint256 id, string memory trait, uint256 min, uint256 max) internal pure returns (uint256) {
        return (min + seeding(id, trait) % (max - min + 1));
    }

    function compareStrings(string memory a, string memory b) internal view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function getNation(uint256 id) internal view returns (string memory) {
        return rand(id, "nation", _nations);
    }

    function getDNA(uint256 id) internal view returns (string memory) {
        return rand(id, "dna", _dnas);
    }

    function getSkin(uint256 id) internal view returns (string memory) {
        string memory dna = getDNA(id);

        if (compareStrings(dna, _dnas[2])
        || compareStrings(dna, _dnas[3])
        || compareStrings(dna, _dnas[4])
            || compareStrings(dna, _dnas[5])) {
            return "none";
        }
        return rand(id, "skin", _skins3);
    }

    function getBeard(uint256 id) internal view returns (string memory) {
        string memory dna = getDNA(id);

        if (
            compareStrings(dna, _dnas[1])
            || compareStrings(dna, _dnas[2])
            || compareStrings(dna, _dnas[3])
            || compareStrings(dna, _dnas[4])
            || compareStrings(dna, _dnas[5])) {
            return "none";
        }
        return rand(id, "beard", _beards4);
    }

    function getHair(uint256 id) internal view returns (string memory) {
        string memory dna = getDNA(id);

        if (
            compareStrings(dna, _dnas[2])
            || compareStrings(dna, _dnas[3])
            || compareStrings(dna, _dnas[4])
            || compareStrings(dna, _dnas[5])) {
            return "none";
        } else if (compareStrings(dna, _dnas[1])) {
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
        return randUint256(id, "number", 1, 26);
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
        string memory emo = _moods[nation].tempEmo;
        if (!compareStrings(emotionTime, _emotionTimes[0])) {
            uint256 eT = 86400;
            if (compareStrings(emotionTime, _emotionTimes[3])) {
                eT = eT * 30;
            }
            else if (compareStrings(emotionTime, _emotionTimes[2])) {
                eT = eT * 7;
            }
            if (block.timestamp - _moods[nation].tempLastTime > eT) {
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
        // string[] private shapes = ["Pillhead", "Smiler", "Spektral", "Helix", "Tesseract", "Torus", "Obelisk"];
        // accept Pillhead
        require(uint256(keccak256(abi.encodePacked("shape", StringsUpgradeable.toString(tokenIdGated)))) % 7 == 0, Errors.INV_PARAMS);
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
     * @notice Stores, from any API, the scheduled games.
     * @param requestId the request ID for fulfillment.
     * @param gameData the games data is resolved.
     */
    function fulfill(bytes32 requestId, bytes memory gameData) public recordChainlinkFulfillment(requestId) {
        (uint32 gameId, uint40 startTime, string memory home, string memory away, uint8 homeTeamGoals, uint8 awayTeamGoals, uint8 status) = abi.decode(gameData, (uint32, uint40, string, string, uint8, uint8, uint8));
        Result result = determineResult(homeTeamGoals, awayTeamGoals);
        if (result == Result.H_W) {
            _moods[home].tempEmo = _emotions[2];
            _moods[away].tempEmo = _emotions[1];
        } else if (result == Result.A_W) {
            _moods[home].tempEmo = _emotions[1];
            _moods[away].tempEmo = _emotions[2];
        } else {
            _moods[home].tempEmo = _emotions[0];
            _moods[away].tempEmo = _emotions[0];
        }
        _moods[home].tempLastTime = block.timestamp;
        _moods[away].tempLastTime = block.timestamp;
    }

    /**
     * @notice Stores, from Enetpulse, the scheduled games.
     */
    /*function fulfillSchedule(bytes32 _requestId, bytes[] memory _result) external recordChainlinkFulfillment(_requestId) {
        for (uint i = 0; i < _result.length; i++) {

        }
    }*/

    function determineResult(uint homeTeam, uint awayTeam) internal view returns (Result) {
        if (homeTeam > awayTeam) {return Result.H_W;}
        if (homeTeam == awayTeam) {return Result.D;}
        return Result.A_W;
    }

    /**
    * @notice Requests, from any API,the tournament games to be resolved.
    */
    function requestData(bytes32 jobId, uint256 fee, string memory url, string memory path) public returns (bytes32 requestId) {
        require(msg.sender == _admin || msg.sender == _be, Errors.ONLY_ADMIN_ALLOWED);
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        req.add('get', url);
        req.add('path', path);
        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    /**
     * @notice Requests, from Enetpulse, the tournament games either to be created or to be resolved on a specific date.
     */
    /*function requestSchedule(bytes32 jobId, uint256 fee, uint256 market, uint256 date) external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        Chainlink.Request memory req = buildOperatorRequest(jobId, this.fulfillSchedule.selector);
        req.addUint("market", market);
        // 77: FIFA World Cup
        req.addUint("leagueId", 77);
        req.addUint("date", date);
        sendOperatorRequest(req, fee);
    }*/

    function withdrawLink() public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }
}
