pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../lib/helpers/Errors.sol";
import "../operator-filter-registry/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

contract HORNS is Initializable, ERC721PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, IERC2981Upgradeable, DefaultOperatorFiltererUpgradeable {
    using SafeMathUpgradeable for uint256;

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
    // base on PLAYER nft
    address public _tokenAddrErc721;
    // base on fee
    uint256 public _fee;

    // @dev: living data for collection
    struct Mood {
        string tempEmo;
        uint256 tempLastTime;
    }

    mapping(string => Mood) public _moods;
    enum Result {U, H_W, A_W, D}

    struct Horn {
        string nation;
        string palletTop;
        string palletBottom;
    }

    uint256 public _limit;

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
        _limit = _maxUser;

        __Ownable_init();
        __DefaultOperatorFilterer_init();
        __ReentrancyGuard_init();
        __ERC721Pausable_init();
    }

    function changeAdmin(address newAdm) external {
        require(msg.sender == _admin && newAdm != address(0) && _admin != newAdm, Errors.ONLY_ADMIN_ALLOWED);
        _admin = newAdm;
    }

    function changeParam(address newP) external {
        require(msg.sender == _admin && newP != address(0) && _paramsAddress != newP, Errors.ONLY_ADMIN_ALLOWED);
        _paramsAddress = newP;
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

    function setLimit(uint256 limit) public {
        require(msg.sender == _admin, Errors.ONLY_ADMIN_ALLOWED);
        _limit = limit;
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


    function seeding(uint256 id, string memory trait) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(trait, StringsUpgradeable.toString(id))));
    }

    /* @TRAITS: Get data for render
    */
    function randUint256(uint256 id, string memory trait, uint256 min, uint256 max) internal pure returns (uint256) {
        return (min + (seeding(id, trait) % (max - min + 1)));
    }

    function compareStrings(string memory a, string memory b) internal view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function getNation(uint256 id) internal view returns (string memory) {
        // 3% for each
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

    function getPaletteBottom(uint256 id) public view returns (string memory) {
        string[16] memory colors = [
        "#E7434F",
        "#E7973D",
        "#E7DC4E",
        "#5CE75D",
        "#2981E7",
        "#5D21E7",
        "#E777E4",
        "#E7E7E7",
        "#312624",
        "#E7969F",
        "#E7B277",
        "#E7DD8F",
        "#8CE7C3",
        "#87B2E7",
        "#A082E7",
        "#E4B7E7"
        ];
        return colors[seeding(id, "palletTop") % colors.length];
    }

    function getPaletteTop(uint256 id) public view returns (string memory) {
        string[16] memory colors = [
        "#E7434F",
        "#E7973D",
        "#E7DC4E",
        "#5CE75D",
        "#2981E7",
        "#5D21E7",
        "#E777E4",
        "#E7E7E7",
        "#312624",
        "#E7969F",
        "#E7B277",
        "#E7DD8F",
        "#8CE7C3",
        "#87B2E7",
        "#A082E7",
        "#E4B7E7"
        ];
        return colors[seeding(id, "palletBottom") % colors.length];
    }

    function getParamValues(uint256 tokenId) public view returns (Horn memory horn) {
        horn = Horn(
            getNation(tokenId),
            getPaletteTop(tokenId),
            getPaletteBottom(tokenId)
        );
        return horn;
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
    function mintByToken(uint256 tokenIdGated) public {
        require(_tokenAddrErc721 != address(0) && _limit > 0, Errors.INV_ADD);
        // owner erc-721
        IERC721Upgradeable token = IERC721Upgradeable(_tokenAddrErc721);
        require(token.ownerOf(tokenIdGated) == msg.sender);

        require(_counter < _maxUser && _counter < _limit);
        _counter++;
        _safeMint(msg.sender, _counter);
    }

    function mint() public payable {
        require(_fee > 0 && msg.value >= _fee && _limit > 0, Errors.INV_FEE_PROJECT);
        require(_counter < _maxUser && _counter < _limit);
        _counter++;
        _safeMint(msg.sender, _counter);
    }

    function ownerMint(uint256 id) public {
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

    /* @notice: opensea operator filter registry
    */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}
