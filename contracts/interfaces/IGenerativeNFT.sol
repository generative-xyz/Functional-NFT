// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "../lib/helpers/BoilerplateParam.sol";

interface IGenerativeNFT {
    function mint(address mintTo, BoilerplateParam.ParamsOfNFT memory _paramsTemplateValue) external;

    function ownerMint(address mintTo, uint256 tokenId, BoilerplateParam.ParamsOfNFT memory _paramsTemplateValue) external;

    function init(
        BoilerplateParam.InitMinterNFTInfo memory p
    ) external;
}