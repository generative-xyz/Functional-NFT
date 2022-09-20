// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FunctionalNFT is ERC721URIStorage, ReentrancyGuard, Ownable {

        // token id
        using Counters for Counters.Counter;
        Counters.Counter private _counter;

        // the function source code
        string private _code;

        // the function parameters
        string[] private _params;

        // the possible values of a param
        mapping(string => string[]) private _ranges;

        // the specific value of a param (attribute) of an NFT
        mapping(uint256 => mapping(string => string)) private _values;

        constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

        function setCode(string memory code) public onlyOwner {
                _code = code;
        }


        function setRange(string memory param, string[] memory range) public onlyOwner {
                _ranges[param] = range;
        }

        function _setValue(uint256 id, string memory param, string memory value) internal {
                _values[id][param] = value;
        }

        // for code gen execution
        function getCode() public view returns (string memory) {
                return _code;
        }

        // TODO: look at common format so it can be displayed on opensea etc
        function getValue(uint256 id, string memory param) public view returns (string memory) {
                return _values[id][param];
        }

        function mint() public nonReentrant returns (uint256) {
                uint256 id = _counter.current();
                _mint(msg.sender, id);
                _setTokenURI(id, _randomAttributes(id));
                _counter.increment();
                return id;
        }

        function _randomAttributes(uint256 id) internal returns (string memory) {
                string memory content;

                for (uint256 i = 0; i < _params.length; i++) {
                        string storage param = _params[i];
                        uint256 k = _randomNumber(_ranges[param].length);
                        string memory value = _ranges[param][k];
                        _setValue(id, param, value);
                        content = string(abi.encodePacked(content, value));
                }

                return content;
        }

        function _randomNumber(uint256 n) internal view returns (uint256) {
                return uint(keccak256(abi.encodePacked(block.difficulty, msg.sender, block.timestamp))) % n;
        }
}
