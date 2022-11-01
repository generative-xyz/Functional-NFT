// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SWEETS is ERC721, Ownable, ReentrancyGuard {

    string[] private shapes = [
    "Pillhead",
    "Smiler",
    "Spektral",
    "Helix",
    "Tesseract",
    "Torus",
    "Obelisk"
    ];

    string[] private sizes = [
    "Nibble",
    "Bite",
    "Devour"
    ];

    string[] private surfaces = [
    "Hydro",
    "Plated",
    "Tactile"
    ];

    string[] private colors = [
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

    string public algorithm;
    uint256 private n;

    constructor() ERC721 ("SWEETS", "SWEETS") Ownable() {}

    function mint() public nonReentrant {
        require(n < 4500);
        n++;
        _safeMint(msg.sender, n);
    }

    function ownerMint(uint256 id) public nonReentrant onlyOwner {
        require(id > 4500 && id <= 5000);
        _safeMint(msg.sender, id);
    }

    function setAlgo(string memory algo) public onlyOwner {
        algorithm = algo;
    }

    function rand(uint256 id, string memory trait, string[] memory values) internal pure returns (string memory) {
        uint256 k = uint256(keccak256(abi.encodePacked(trait, toString(id))));
        return values[k % values.length];
    }

    function getSize(uint256 id) public view returns (string memory) {
        return rand(id, "size", sizes);
    }

    function getSurface(uint256 id) public view returns (string memory) {
        return rand(id, "shape", shapes);
    }

    function getShape(uint256 id) public view returns (string memory) {
        return rand(id, "surface", surfaces);
    }

    function getParamValues(uint256 tokenId) public view returns (string[4] memory, string memory shape, string memory size, string memory surface) {
        return (getPalette(tokenId), getShape(tokenId), getSize(tokenId), getSurface(tokenId));
    }

    function getPalette(uint256 id) public view returns (string[4] memory) {
        string[4] memory palette;
        palette[0] = rand(id, "color 0", colors);
        palette[1] = rand(id, "color 1", colors);
        palette[2] = rand(id, "color 2", colors);
        palette[3] = rand(id, "color 3", colors);
        return palette;
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
        return "https://rendering.rove.to/v1/rendered-nft/1/metadata/";
    }
}