// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

library Random {
    function randomSeed(address msgSender, uint256 projectId, uint256 index) internal view returns (bytes32){
        return keccak256(abi.encodePacked(blockhash(block.number - 1), msgSender, projectId, index));
    }

    function randomValueIndexArray(uint256 seed, uint256 n) internal view returns (uint256) {
        return seed % n;
    }

    function randomValueRange(uint256 seed, uint32 min, uint256 max) internal view returns (uint256) {
        return (min + seed % (max - min + 1));
    }
}