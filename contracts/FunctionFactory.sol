// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FunctionFactory is ERC721URIStorage {

        // token id
        using Counters for Counters.Counter;
        Counters.Counter private counter;

        // function => code
        mapping(string => string) private _functions;

        // function => attribute => possible values
        mapping(string => mapping(string => string[])) _values;

        // token id => attribute => value
        mapping(string => mapping(string => string)) private _attributes;

        // function => attribute names
        mapping(string => string[]) private _attributeNames;

        constructor() ERC721("FunctionFactory", "FF") {}

        function setFunction(string memory name, string memory code) public {
                _functions[name] = code;
        }

        function getFunction(string memory name) public view returns (string memory) {
                return _functions[name];
        }

        function setValues(string memory func, string memory attr, string[] memory values) public {
                _values[func][attr] = values;
        }

        function _setAttribute(string memory id, string memory attribute, string memory value) internal {
                _attributes[id][attribute] = value;
        }

        function getAttribute(string memory id, string memory attribute) public view returns (string memory) {
                return _attributes[id][attribute];
        }

        function mintObject(string memory func) public returns (uint256) {
                uint256 i = counter.current();
                _mint(msg.sender, i);
                _setTokenURI(i, _randomAttributes(func));
                counter.increment();
                return i;
        }

        function _randomAttributes(uint256 tokenId, string memory func) internal returns (string memory) {
                string memory content;

                for (uint256 i = 0; i < _attributeNames[func].length; i++) {
                        string storage attr = _attributeNames[func][i];
                        uint256 k = _randomNumber(_values[func][attr].length);
                        string memory value = _values[func][attr][k];
                        _setAttribute(tokenId, attr, value);
                        content = string(abi.encodePacked(content, value));
                }

                return content;
        }

        function _randomNumber(uint256 n) internal returns (uint256) {
                return uint(keccak256(abi.encodePacked(block.difficulty, msg.sender, block.timestamp))) % n;
        }
}
