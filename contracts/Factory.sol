// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FunctionFactory is ERC721URIStorage, ReentrancyGuard, Ownable {

        // token id
        using Counters for Counters.Counter;
        Counters.Counter private _counter;

        // function => code
        mapping(string => string) private _codes;

        // function => attribute names
        mapping(string => string[]) private _params;

        // function => attribute => possible values
        mapping(string => mapping(string => string[])) _values;

        constructor() ERC721("FunctionFactory", "FF") {}

        function setCode(string memory func, string memory code) public {
                _codes[func] = code;
        }

        function getCode(string memory func) public view returns (string memory) {
                return _codes[func];
        }

        function setParams(string memory func, string[] memory params) public onlyOwner {
                _params[func] = params;
        }

        function setValues(string memory func, string memory param, string[] memory values) public onlyOwner {
                _values[func][param] = values;
        }

        function mint(string memory func) public nonReentrant onlyOwner returns (uint256) {

                // make sure it's all set up
                require(keccak256(abi.encode(_codes[func])) != "");
                require(_params[func].length > 0);
                for (uint256 i = 0; i < _params[func].length; i++) {
                        require(_values[func][_params[func][i]].length >0);
                }

                // mint a new Functional NFT
                // TODO


                // mint
                uint256 id = _counter.current();
                _mint(msg.sender, id);
                _setTokenURI(id, func);
                _counter.increment();
                return id;
        }

}
