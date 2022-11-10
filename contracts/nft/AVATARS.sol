pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../lib/helpers/Errors.sol";

contract AVATARS is Initializable, ERC721PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, IERC2981Upgradeable {
    using SafeMathUpgradeable for uint256;
    event RequestFulfilledData(bytes32 indexed requestId, bytes indexed data);

    // @dev: supply for collection
    uint256 constant _max = 5000;
    uint256 constant _maxUser = 4500;

    // @dev: handler
    address public _admin;
    address public _be;
    address public _paramsAddress;
    address public _oracle;
    mapping(bytes32 => bytes) public _requestIdData;

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
    string[] private _beards3;
    string[] private _hair10;
    string[] private _hairs7;

    string[] private _undershirts;
    string[] private _tops;
    string[] private _bottoms;
    string[] private _shoes;
    string[] private _tatoos;
    string[] private _glasses;
    string[] private _captains;

    struct Player {
        string _emotion;
        string _emotionTime;
        string _nation;
        string _dna;
        string _beard;
        string _hair;
        string _undershirt;
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
        address paramsAddress
    ) initializer public {
        require(admin != address(0) && paramsAddress != address(0), Errors.INV_ADD);
        __ERC721_init(name, symbol);
        _paramsAddress = paramsAddress;
        _admin = admin;
        // init traits
        initTraits();
    }

    function initTraits() internal {
        _nations = [
        "Qatar", "Ecuador", "Senegal", "Netherlands", // GA
        "England", "IR_Iran", "USA", "Wales", // GB
        "Argentina", "Saudi Arabia", "Mexico", "Poland", // GC
        "France", "Australia", "Denmark", "Tunisia", //GD
        "Spain", "Costa_Rica", "Germany", "Japan", //GE
        "Belgium", "Canada", "Morocco", "Croatia", //GF
        "Brazil", "Serbia", "Switzerland", "Cameroon", //GG
        "Portugal", "Ghana", "Uruguay", "Korea_Republic" // GH
        ];

        _emotions = ["1", "2", "3"];
        //["normal", "sad", "happy"];

        _emotionTimes = ["1", "2", "3", "4"];
        //["Forever", "1 day", "7 days", "30 days"];

        _dnas = ["1", "2", "3", "4", "5", "6", "7"];
        //["male", "female", "robot", "ape", "alien", "ball head"];

        _beards3 = ["0", "1", "2"];
        //["none", "shape 1", "shape 2", "shape 3"];

        _hair10 = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
        //["none", "short", "long", "crazy"];
        _hairs7 = ["1", "2", "3", "4", "5", "6", "7"];
        //["short", "long", "crazy"];

        _undershirts = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17"];

        _tops = ["0", "1"];
        //["tshirt", "hoodie"];

        _bottoms = ["0", "1"];
        //["shorts", "jogger"];

        _shoes = ["1", "2", "3"];
        //["reg 1", "reg 2", "reg 3", "spe 1", "spe 2", "spe 3"];

        _tatoos = ["0", "1", "2", "3", "4"];
        //["none", "shape 1", "shape 2", "shape 3", "shape 4", "shape 5"];

        _glasses = ["0", "1", "2", "3", "4", "5"];
        //["none", "shape 1", "shape 2", "shape 3"];
        _captains = ["0", "1"];
        //["none", "have"];

    }

    function changeAdmin(address newAdm) external {
        require(msg.sender == _admin && newAdm != address(0) && _admin != newAdm, Errors.ONLY_ADMIN_ALLOWED);
        _admin = newAdm;
    }

    function changeToken(address sweet) external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _tokenAddrErc721 = sweet;
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

    /*function testShape(uint256 tokenIdGated) public view returns (uint256) {
        return seeding(tokenIdGated, "shape") % 7;
    }*/

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

    function getBeard(uint256 id) internal view returns (string memory) {
        string memory dna = getDNA(id);

        if (
            compareStrings(dna, _dnas[1])
            || compareStrings(dna, _dnas[2])
            || compareStrings(dna, _dnas[3])
            || compareStrings(dna, _dnas[4])
            || compareStrings(dna, _dnas[5])
            || compareStrings(dna, _dnas[6])
        ) {
            return "0";
        }
        return rand(id, "beard", _beards3);
    }

    function getHair(uint256 id) internal view returns (string memory) {
        string memory dna = getDNA(id);

        if (
            compareStrings(dna, _dnas[2])
            || compareStrings(dna, _dnas[3])
            || compareStrings(dna, _dnas[4])
            || compareStrings(dna, _dnas[5])
            || compareStrings(dna, _dnas[6])) {
            return "0";
        } else if (compareStrings(dna, _dnas[1])) {
            return rand(id, "hair", _hairs7);
        }
        return rand(id, "hair", _hair10);
    }

    function getUndershirt(uint256 id) internal view returns (string memory) {
        string memory dna = getDNA(id);

        if (compareStrings(dna, _dnas[0])) {
            string memory top = getTop(id);
            if (compareStrings(top, _tops[0])) {
                uint256 number = getNumber(id);
                if (number != 0) {
                    return rand(id, "undershirt", _undershirts);
                }
            }
        }
        return "0";
    }

    function getTop(uint256 id) internal view returns (string memory) {
        return rand(id, "top", _tops);
    }

    function getBottom(uint256 id) internal view returns (string memory) {
        return rand(id, "bottom", _bottoms);
    }

    function getNumber(uint256 id) internal view returns (uint256) {
        return randUint256(id, "number", 0, 26);
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

    function getCaptain(uint256 id) internal view returns (string memory) {
        return rand(id, "glovers", _captains);
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
        player = Player(
            emo,
            emotionTime,
            nation,
            getDNA(tokenId),
            getBeard(tokenId),
            getHair(tokenId),
            getShoes(tokenId),
            getUndershirt(tokenId),
            getTop(tokenId),
            getBottom(tokenId),
            getNumber(tokenId),
            getTatoo(tokenId),
            getGlasses(tokenId),
            getCaptain(tokenId)
        );
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
        require(seeding(tokenIdGated, "shape") % 7 == 0, Errors.INV_PARAMS);
        // erc-721
        IERC721Upgradeable token = IERC721Upgradeable(_tokenAddrErc721);
        // burn
        token.transferFrom(msg.sender, address(this), tokenIdGated);

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

    function changeOracle(address oracle) external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        require(oracle != address(0), Errors.INV_ADD);
        _oracle = oracle;
    }

    /**
     * @notice Stores, from any API, the scheduled games.
     * @param requestId the request ID for fulfillment.
     * @param gameData the games data is resolved.
     */
    function fulfill(bytes32 requestId, bytes memory gameData) external {
        require(msg.sender == _oracle, Errors.INV_ADD);
        emit RequestFulfilledData(requestId, gameData);

        _requestIdData[requestId] = gameData;
        (uint32 gameId, uint40 startTime, string memory home, string memory away, uint8 homeTeamGoals, uint8 awayTeamGoals, string memory status) = abi.decode(gameData, (uint32, uint40, string, string, uint8, uint8, string));
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

    function determineResult(uint homeTeam, uint awayTeam) internal view returns (Result) {
        if (homeTeam > awayTeam) {return Result.H_W;}
        if (homeTeam == awayTeam) {return Result.D;}
        return Result.A_W;
    }
}
