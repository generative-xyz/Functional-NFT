// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

library BoilerplateParam {
    struct ParamTemplate {
        uint8 _typeValue;
        uint8 _max;
        uint8 _min;
        uint8 _decimal;
        uint[] _availableDecimal;
        string[] _availableString;
        uint8 _value;// index of available array value or value of range min,max
    }

    struct ParamsOfProject {
        bytes32 _seed;
        ParamTemplate[] _params;
    }


}