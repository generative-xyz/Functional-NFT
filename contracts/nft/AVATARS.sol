pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../lib/helpers/Errors.sol";
import "../interfaces/ICallback.sol";

contract AVATARS is Initializable, ERC721PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, ICallback, IERC2981Upgradeable {
    using SafeMathUpgradeable for uint256;
    event RequestFulfilledData(bytes32 indexed requestId, bytes indexed data);

    // @dev: supply for collection
    uint256 constant _max = 10000;
    uint256 constant _maxUser = 9000;

    // @dev: handler
    address public _admin;
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
        string _captain;
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
    }

    function changeAdmin(address newAdm) external {
        require(msg.sender == _admin && newAdm != address(0) && _admin != newAdm, Errors.ONLY_ADMIN_ALLOWED);
        _admin = newAdm;
    }

    function changeToken(address sweet) external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _tokenAddrErc721 = sweet;
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
    function randUint256(uint256 id, string memory trait, uint256 min, uint256 max) internal pure returns (uint256) {
        return (min + seeding(id, trait) % (max - min + 1));
    }

    function compareStrings(string memory a, string memory b) internal view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function getNation(uint256 id) internal view returns (string memory) {
        string[32] memory _nations = [
        "Qatar", "Ecuador", "Senegal", "Netherlands", // GA
        "England", "IR Iran", "USA", "Wales", // GB
        "Argentina", "Saudi Arabia", "Mexico", "Poland", // GC
        "France", "Australia", "Denmark", "Tunisia", //GD
        "Spain", "Costa Rica", "Germany", "Japan", //GE
        "Belgium", "Canada", "Morocco", "Croatia", //GF
        "Brazil", "Serbia", "Switzerland", "Cameroon", //GG
        "Portugal", "Ghana", "Uruguay", "Korea Republic" // GH
        ];
        return _nations[seeding(id, "nation") % _nations.length];
    }

    function getDNA(uint256 id) internal view returns (string memory) {
        string[6] memory _dnas = ["1", "2", "3", "4", "5", "6"];
        // male, female, robot, ape, alien, ballhead

        uint256 prob = randUint256(id, "dna", 1, 10000);
        if (prob > 3000) {
            return _dnas[0];
        } else if (prob >= 1 && prob <= 2000) {
            return _dnas[1];
        } else if (prob >= 2001 && prob <= 2600) {
            return _dnas[2];
        } else if (prob >= 2601 && prob <= 2900) {
            return _dnas[3];
        } else if (prob >= 2901 && prob <= 2990) {
            return _dnas[4];
        } else {
            return _dnas[5];
        }
    }

    function getBeard(uint256 id) internal view returns (string memory) {
        string[3] memory _beards3 = ["0", "1", "2"];
        string memory dna = getDNA(id);

        if (compareStrings(dna, "1")) {// male
            return _beards3[seeding(id, "beard") % _beards3.length];
        }
        return "0";
    }

    function getHair(uint256 id) internal view returns (string memory) {
        string[10] memory _hair10 = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
        string[7] memory _hairs7 = ["1", "2", "3", "4", "5", "6", "7"];
        string memory dna = getDNA(id);

        if (compareStrings(dna, "2")) {// female
            return _hairs7[seeding(id, "hair") % _hairs7.length];
        } else if (compareStrings(dna, "1")) {// male
            return _hair10[seeding(id, "hair") % _hair10.length];
        }
        return "0";
    }

    function getUndershirt(uint256 id) internal view returns (string memory) {
        string[17] memory _undershirts = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17"];
        string memory dna = getDNA(id);

        if (compareStrings(dna, "1")) {// only male
            string memory top = getTop(id);
            if (compareStrings(top, "1")) {// top 1
                uint256 number = getNumber(id);
                if (number != 0) {// has number
                    return _undershirts[seeding(id, "undershirt") % _undershirts.length];
                }
            }
        }
        return "0";
    }

    function getTop(uint256 id) internal view returns (string memory) {
        string[3] memory _tops = ["1", "2", "3"];
        string[3] memory _topsF = ["1", "2", "4"];
        string memory dna = getDNA(id);

        if (compareStrings(dna, "2")) {// female
            return _topsF[seeding(id, "top") % _topsF.length];
        }
        return _tops[seeding(id, "top") % _tops.length];
    }

    function getBottom(uint256 id) internal view returns (string memory) {
        string[2] memory _bottomsF = ["3", "4"];
        string[2] memory _bottoms = ["1", "2"];
        string memory dna = getDNA(id);

        if (compareStrings(dna, "2")) {// female
            return _bottomsF[seeding(id, "bottom") % _bottomsF.length];
        }
        return _bottoms[seeding(id, "bottom") % _bottoms.length];
    }

    function getNumber(uint256 id) internal view returns (uint256) {
        uint256[26] memory _number = [uint256(1), 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26];

        uint256 prob = randUint256(id, "number", 1, 10000);
        if (prob > 7800) {
            return 0;
        }
        return _number[seeding(id, "number") % _number.length];
    }

    function getShoes(uint256 id) internal view returns (string memory) {
        string[3] memory _shoes = ["1", "2", "3"];
        return _shoes[seeding(id, "shoe") % _shoes.length];
    }

    function getTatoo(uint256 id) internal view returns (string memory) {
        string[4] memory _tatoos = ["0", "1", "2", "3"];
        return _tatoos[seeding(id, "tatoo") % _tatoos.length];
    }

    function getGlasses(uint256 id) internal view returns (string memory) {
        string[6] memory _glasses = ["0", "1", "2", "3", "4", "5"];
        return _glasses[seeding(id, "glasses") % _glasses.length];
    }

    function getCaptain(uint256 id) internal view returns (string memory) {
        string[2] memory _captains = ["0", "1"];
        return _captains[seeding(id, "captain") % _captains.length];
    }

    function getEmotionTime(uint256 id) internal view returns (string memory, string[3] memory) {
        string[3] memory _emotionTimes = ["1", "2", "3"];
        return (_emotionTimes[seeding(id, "emotionTime") % _emotionTimes.length], _emotionTimes);
    }

    function getParamValues(uint256 tokenId) public view returns (Player memory player) {
        string[3] memory _emotions = ["1", "2", "3"];

        string memory nation = getNation(tokenId);
        (string memory emotionTime, string[3] memory _emotionTimes) = getEmotionTime(tokenId);
        string memory emo = _moods[nation].tempEmo;
        //1 day
        uint256 eT = 86400;
        if (compareStrings(emotionTime, _emotionTimes[2])) {// 30 days
            eT = eT * 30;
        }
        else if (compareStrings(emotionTime, _emotionTimes[1])) {// 1 week
            eT = eT * 7;
        }
        if (block.timestamp - _moods[nation].tempLastTime > eT) {
            emo = _emotions[0];
        }
        player = Player(
            emo,
            emotionTime,
            nation,
            getDNA(tokenId),
            getBeard(tokenId),
            getHair(tokenId),
            getUndershirt(tokenId),
            getShoes(tokenId),
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
        string[3] memory _emotions = ["1", "2", "3"];
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
