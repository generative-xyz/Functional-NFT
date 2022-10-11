// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

library StringUtils {
    function generateCollectionName(string memory name, address sender) internal pure returns (string memory) {
        return string(abi.encodePacked(name, " by ", StringsUpgradeable.toHexString(uint256(uint160(sender)), 20)));
    }
}