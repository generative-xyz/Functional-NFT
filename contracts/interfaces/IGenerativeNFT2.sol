// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "../lib/helpers/BoilerplateParam.sol";

interface IGenerativeNFT2 {
    function mint() external;

    function ownerMint(uint256 tokenId) external;

    function init(
        BoilerplateParam.InitMinterNFTInfo memory p
    ) external;
}