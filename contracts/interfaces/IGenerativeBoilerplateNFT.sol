// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "../lib/helpers/BoilerplateParam.sol";


interface IGenerativeBoilerplateNFT {
    function getParamsTemplate(uint256 id) external view returns (BoilerplateParam.ParamTemplate[] memory);
}