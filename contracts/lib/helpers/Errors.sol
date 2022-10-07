// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

library Errors {
    enum ReturnCode {
        SUCCESS,
        FAILED
    }

    string public constant SUCCESS = "0";

    // common errors
    string public constant INV_ADD = "100";
    string public constant ONLY_ADMIN_ALLOWED = "101";
    string public constant EMPTY_LIST = "102";

    // transfer error
    string public constant NOT_ALLOWANCE = "200";
    string public constant INSUFF = "201";
    string public constant TRANSFER_FAIL_ERC_20 = "202";
    string public constant TRANSFER_FAIL_NATIVE = "203";

    // validation error
    string public constant MISSING_NAME = "300";
    string public constant INV_FEE_PROJECT = "301";
    string public constant INVALID_PROJECT = "302";
    string public constant REACH_MAX = "303";
    string public constant INV_PARAMS = "103";
}