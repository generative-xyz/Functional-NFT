// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

library BoilerplateParam {
    struct param {
        uint8 typeValue;
        uint8 max;
        uint8 min;
        uint8 decimal;
        uint[] availableDecimal;
        string[] availableString;
        uint8 value;// index of available array value or value of range min,max
    }

    struct projectParams {
        uint256 seedIndex;
        bytes32 seed;
        param[] Params;
    }
}