pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import "../lib/helpers/Errors.sol";

contract AVATARSOracle is ReentrancyGuard, Ownable, ChainlinkClient {
    event RequestFulfilled(bytes32 indexed requestId, bytes[] indexed data);
    event RequestFulfilledData(bytes32 indexed requestId, bytes indexed data);

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

    address public _admin;
    address public _be;

    // @dev: living data for collection
    struct Mood {
        string tempEmo;
        uint256 tempLastTime;
    }

    mapping(string => Mood) public _moods;
    enum Result {U, H_W, A_W, D}
    string[] public _emotions = ["0", "1", "2"];

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
    constructor (address admin, address be, address LINK_TOKEN, address ORACLE) {
        _admin = admin;
        _be = be;

        // init for oracle
        setChainlinkToken(LINK_TOKEN);
        setChainlinkOracle(ORACLE);
    }

    function changeAdmin(address newAdm) external {
        require(msg.sender == _admin && newAdm != address(0) && _admin != newAdm, Errors.ONLY_ADMIN_ALLOWED);
        _admin = newAdm;
    }

    function setBE(address be) external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _be = be;
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
        emit RequestFulfilledData(requestId, gameData);
        /*(uint32 gameId, uint40 startTime, string memory home, string memory away, uint8 homeTeamGoals, uint8 awayTeamGoals, uint8 status) = abi.decode(gameData, (uint32, uint40, string, string, uint8, uint8, uint8));
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
        
        0x2178c7a02856fe8f204cff3921baad3325803af86d9106ff115ab41b99eec43d00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000900000000000000000000000000000000000000000000000000000000001e848000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000055161746172000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000745637561646f7200000000000000000000000000000000000000000000000000
        _moods[home].tempLastTime = block.timestamp;
        _moods[away].tempLastTime = block.timestamp;*/
    }

    /**
     * @notice Stores, from Enetpulse, the scheduled games.
     */
    function fulfillSchedule(bytes32 requestId, bytes[] memory result) external recordChainlinkFulfillment(requestId) {
        emit RequestFulfilled(requestId, result);
    }

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
    function requestSchedule(bytes32 jobId, uint256 fee, uint256 market, uint256 leagueId, uint256 date) external {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        Chainlink.Request memory req = buildOperatorRequest(jobId, this.fulfillSchedule.selector);
        req.addUint("market", market);
        // 77: FIFA World Cup
        req.addUint("leagueId", leagueId);
        req.addUint("date", date);
        sendOperatorRequest(req, fee);
    }

    function withdrawLink() public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }
}
