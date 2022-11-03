// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

library BoilerplateParam {
    struct ProjectInfo {
        uint256 _fee; // default frees
        address _feeToken;// default is native token
        string _script; // script render: 1/ simplescript 2/ ipfs:// protocol
        uint32 _scriptType; // script type: python, js, ....
        address _creator; // creator list for project, using for royalties
        string _customUri; // project info nft view
        string _projectName; // name of project
        bool _clientSeed; // accept seed from client if true -> contract will not verify value
        ParamTemplate[] _paramsTemplate; // struct contains list params of project and random seed(registered) in case mint nft from project
        address _minterNFTInfo;// map projectId ->  NFT collection address mint from project
    }

    struct ParamTemplate {
        // 1: int
        // 2: float
        // 3: string
        // 4: bool
        uint8 _typeValue;

        uint256 _max;
        uint256 _min;
        uint8 _decimal;
        string[] _availableValues;
        uint256 _value;// index of available array value or value of range min,max
        bool _editable; // false: random by seed, true: not random by seed
    }

    struct ParamsOfNFT {
        bytes32 _seed;
        uint256[] _value;// index of available array value or value of range min,max
    }

    struct InitMinterNFTInfo {
        string _name;
        string _symbol;
        string _uri;
        address _admin;
        uint256 _max;
        uint256 _limit;
        uint256 _projectId;
    }
}