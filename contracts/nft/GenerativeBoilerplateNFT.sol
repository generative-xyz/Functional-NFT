// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../governance/ParameterControl.sol";
import "./GenerativeNFT.sol";

contract GenerativeBoilerplateNFT is Initializable, ERC721PresetMinterPauserAutoIdUpgradeable, ReentrancyGuardUpgradeable, IERC2981Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using ClonesUpgradeable for *;
    using SafeMathUpgradeable for uint256;

    // const
    string public constant FEE_TOKEN = "FEE_TOKEN"; // currency using for create project fee
    string public constant CREATE_PROJECT_FEE = "CREATE_PROJECT_FEE"; // fee for user mint project id
    string public constant MINT_NFT_FEE = "MINT_NFT_FEE"; // % will pay for this contract when minter use project id for mint nft
    string public constant GENERATIVE_NFT_TEMPLATE = "GENERATIVE_NFT_TEMPLATE";// address of Generative NFT erc-721 contract

    // super admin
    address public _admin;
    // parameter control address
    address public _paramsAddress;

    // projectId is tokenID of project nft
    CountersUpgradeable.Counter private _nextProjectId;

    /* ###  project info for minting generative nft and fee ### */
    // minting fee, if any
    // projectId -> fee setting
    mapping(uint256 => uint256) public _fees; // default frees
    mapping(uint256 => address) public _feeTokens; // default is native token
    // projectId -> max supply
    mapping(uint256 => uint256) public _mintMaxSupply; // max supply can be minted on project
    // projectId -> total supply
    mapping(uint256 => uint256) public _mintTotalSupply; // total supply minted on project
    // generated NFT contract -> project ID
    mapping(address => uint256) public _nftContractProject;
    // owner generated NFT -> projectId -> deployed generated NFT
    mapping(address => mapping(uint256 => address)) public _nftContracts;

    /* ### project info rendering ### */
    // projectId -> script render: 1/ simplescript 2/ ipfs:// protocol
    mapping(uint256 => string) public _scripts;
    mapping(uint256 => string) public _scriptsTypes;
    // template param for project projectId -> config params factor as a json string format {“param1”: “int”, “param2”: “float”, “param3”: “string”, “param4”: {“value": “int”, "min": 1, "max": 20}, "param5": [""]}
    mapping(uint256 => string) public _paramsTemplates;

    /* ### project info nft view ### */
    mapping(uint256 => string) public _customUri;
    mapping(uint256 => string) public _projectName;
    // creator list for project, using for royalties
    mapping(uint256 => address) public _creators;

    modifier adminOnly() {
        require(_msgSender() == _admin, "ONLY_ADMIN_ALLOWED");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ONLY_ADMIN_ALLOWED");
        _;
    }

    modifier creatorOnly(uint256 _id) {
        require(_creators[_id] == msg.sender, "ONLY_CREATOR");
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseUri,
        address admin,
        address paramsAddress
    ) initializer public {
        require(admin != address(0x0), "INV_ADD");
        require(paramsAddress != address(0x0), "INV_ADD");
        __ERC721PresetMinterPauserAutoId_init(name, symbol, baseUri);
        _paramsAddress = paramsAddress;
        _admin = admin;
        // set role for admin address
        grantRole(DEFAULT_ADMIN_ROLE, _admin);
        grantRole(PAUSER_ROLE, _admin);

        // revoke role for sender
        revokeRole(PAUSER_ROLE, msg.sender);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function changeAdmin(address newAdm) public adminOnly {
        address _previousAdmin = _admin;
        _admin = newAdm;

        grantRole(DEFAULT_ADMIN_ROLE, _admin);
        revokeRole(DEFAULT_ADMIN_ROLE, _previousAdmin);
    }


    // mint a Project token id
    // to: owner
    // name: name of project
    // maxSupply: max available nft supply which minted from this project
    // uri: metadata of project info
    // fee: fee mint nft from this project
    // feeAdd: currency for mint nft fee
    // paramsTemplate: json format string for render view template
    function mint(
        address to,
        string memory projectName,
        uint256 maxSupply,
        string memory script,
        string memory scriptType,
        string memory uri,
        uint256 fee,
        address feeAdd,
        string memory paramsTemplate
    ) public nonReentrant payable returns (uint256) {
        bytes memory nameChecked = bytes(projectName);
        require(nameChecked.length > 0, "MISSING_NAME");
        _nextProjectId.increment();
        uint256 currentTokenId = _nextProjectId.current();

        ParameterControl _p = ParameterControl(_paramsAddress);
        uint256 operationFee = _p.getUInt256(CREATE_PROJECT_FEE);
        if (operationFee > 0) {
            address operationFeeToken = _p.getAddress(FEE_TOKEN);
            bool isNative = operationFeeToken == address(0x0);
            if (!isNative) {
                ERC20Upgradeable tokenERC20 = ERC20Upgradeable(operationFeeToken);
                require(tokenERC20.allowance(msg.sender, address(this)) >= operationFee, "NOT_ALLOW");
                require(tokenERC20.balanceOf(msg.sender) >= operationFee, "INSUFF");
                // tranfer erc-20 token to this contract
                bool success = tokenERC20.transferFrom(
                    msg.sender,
                    address(this),
                    operationFee
                );
                require(success == true, "TRANSFER_FAIL");
            } else {
                require(msg.value >= operationFee, "TRANSFER_FAIL");
            }
        }


        if (bytes(uri).length > 0) {
            _customUri[currentTokenId] = uri;
        }
        if (bytes(projectName).length > 0) {
            _projectName[currentTokenId] = projectName;
        }
        _creators[currentTokenId] = msg.sender;
        _mintMaxSupply[currentTokenId] = maxSupply;
        require(fee >= 0, "INV_FEE");
        _fees[currentTokenId] = fee;
        _feeTokens[currentTokenId] = feeAdd;
        _paramsTemplates[currentTokenId] = paramsTemplate;
        _scripts[currentTokenId] = script;
        _scriptsTypes[currentTokenId] = scriptType;

        _safeMint(to, currentTokenId);

        return currentTokenId;
    }

    // mintUniqueNFT
    // from projectId -> get algo and minting an unique nfr on GenerativeNFT contract collection
    function mintUniqueNFT(
        uint256 fromProjectId,
        address mintTo,
        string memory uri,
        string memory paramTemplateValue
    ) public nonReentrant payable returns (address newContract) {
        require(_exists(fromProjectId), "INVALID_PROJECT");
        require(_mintTotalSupply[fromProjectId] < _mintMaxSupply[fromProjectId], "REACH_MAX");
        ParameterControl _p = ParameterControl(_paramsAddress);
        // get payable
        uint256 _mintFee = _fees[fromProjectId];
        if (_mintFee > 0) {
            uint256 operationFee = _p.getUInt256(MINT_NFT_FEE);
            if (operationFee == 0) {
                operationFee = 500;
                // default 5% getting, 95% pay for owner of project
            }
            bool isNative = _feeTokens[fromProjectId] == address(0);
            if (isNative) {
                require(msg.value >= _fees[fromProjectId], "TRANSFER_FAIL_FEE_ETH");

                // pay for owner project
                (bool success,) = ownerOf(fromProjectId).call{value : _mintFee - (_mintFee * operationFee / 10000)}("");
                require(success, "FAIL");
            } else {
                ERC20Upgradeable tokenERC20 = ERC20Upgradeable(_feeTokens[fromProjectId]);
                require(tokenERC20.allowance(msg.sender, address(this)) >= _mintFee, "NOT_ALLOW");
                require(tokenERC20.balanceOf(msg.sender) >= _mintFee, "INSUFF");

                // transfer all fee erc-20 token to this contract
                bool success = tokenERC20.transferFrom(
                    msg.sender,
                    address(this),
                    _mintFee
                );
                require(success == true, "TRANSFER_FAIL_ERC20_FEE");

                // pay for owner project
                success = tokenERC20.transfer(ownerOf(fromProjectId), _mintFee - (_mintFee * operationFee / 10000));
                require(success == true, "TRANSFER_FAIL_ERC20_OWNER");
            }
        }

        address generativeNFTAdd = _nftContracts[msg.sender][fromProjectId];
        if (generativeNFTAdd == address(0x0)) {
            // deploy new by clone from template address
            address template = _p.getAddress(GENERATIVE_NFT_TEMPLATE);
            generativeNFTAdd = ClonesUpgradeable.clone(template);
            _nftContracts[msg.sender][fromProjectId] = generativeNFTAdd;
            _nftContractProject[generativeNFTAdd] = fromProjectId;

            GenerativeNFT nft = GenerativeNFT(generativeNFTAdd);
            string memory initName = string(abi.encodePacked(_projectName[fromProjectId], " by ", Strings.toHexString(uint256(uint160(msg.sender)), 20)));
            nft.init(initName, "", msg.sender, address(this), fromProjectId);
            nft.mint(mintTo, msg.sender, uri, paramTemplateValue);
        } else {
            GenerativeNFT nft = GenerativeNFT(generativeNFTAdd);
            nft.mint(mintTo, msg.sender, uri, paramTemplateValue);
        }
        _mintTotalSupply[fromProjectId] += 1;
        return generativeNFTAdd;
    }

    // mintBatchUniqueNFT
    // from projectId -> get algo and minting an batch unique nfr on GenerativeNFT contract collection
    function mintBatchUniqueNFT(
        uint256 fromProjectId,
        address mintTo,
        string[] memory uris,
        string[] memory paramTemplateValues
    ) public nonReentrant payable returns (address newContract) {
        require(uris.length > 0, "EMPTY");
        require(uris.length == paramTemplateValues.length, "INV_PARAMS");
        require(_mintTotalSupply[fromProjectId] + uris.length <= _mintMaxSupply[fromProjectId], "REACH_MAX");

        // check payable
        uint256 _mintFee = _fees[fromProjectId];
        bool isNative = _feeTokens[fromProjectId] == address(0);
        if (isNative) {
            require(msg.value >= _mintFee * uris.length, "TRANSFER_FAIL");
        } else {
            ERC20Upgradeable tokenERC20 = ERC20Upgradeable(_feeTokens[fromProjectId]);
            require(tokenERC20.allowance(msg.sender, address(this)) >= _mintFee * uris.length, "NOT_ALLOW");
            require(tokenERC20.balanceOf(msg.sender) >= _mintFee * uris.length, "INSUFF");
        }

        address nftAddress;
        for (uint256 i = 0; i < paramTemplateValues.length; i++) {
            nftAddress = mintUniqueNFT(fromProjectId, mintTo, uris[i], paramTemplateValues[i]);
        }
        return nftAddress;
    }

    function burn(uint256 tokenId) public override {
        _creators[tokenId] = address(0x0);
        super.burn(tokenId);
    }

    function _setCreator(address _to, uint256 _id) internal creatorOnly(_id)
    {
        _creators[_id] = _to;
    }

    function setCreator(
        address _to,
        uint256[] memory _ids
    ) public {
        require(_to != address(0), "INVALID_ADDRESS.");
        _grantRole(MINTER_ROLE, _to);
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            _setCreator(_to, id);
        }
    }

    function totalSupply() public view override returns (uint256) {
        return _nextProjectId.current() - 1;
    }

    function setCustomURI(
        uint256 _tokenId,
        string memory _newURI
    ) public creatorOnly(_tokenId) {
        _customUri[_tokenId] = _newURI;
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return _baseURI();
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        bytes memory customUriBytes = bytes(_customUri[_tokenId]);
        if (customUriBytes.length > 0) {
            return _customUri[_tokenId];
        } else {
            return string(abi.encodePacked(baseTokenURI(), StringsUpgradeable.toString(_tokenId)));
        }
    }

    function exists(
        uint256 _id
    ) external view returns (bool) {
        return _exists(_id);
    }

    /** @dev EIP2981 royalties implementation. */
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
        bool isValue;
    }

    mapping(uint256 => RoyaltyInfo) public royalties;

    function setTokenRoyalty(
        uint256 _tokenId,
        address _recipient,
        uint256 _value
    ) public adminOnly {
        require(_value <= 10000, 'TOO_HIGH');
        royalties[_tokenId] = RoyaltyInfo(_recipient, uint24(_value), true);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalty = royalties[_tokenId];
        if (royalty.isValue) {
            receiver = royalty.recipient;
            royaltyAmount = (_salePrice * royalty.amount) / 10000;
        } else {
            receiver = _creators[_tokenId];
            royaltyAmount = (_salePrice * 500) / 10000;
        }
    }

    // withdraw
    // only Admin can withdraw operation fee on this contract
    // receiver: receiver address
    // erc20Addr: currency address
    // amount: amount
    function withdraw(address receiver, address erc20Addr, uint256 amount) external nonReentrant adminOnly {
        if (erc20Addr == address(0x0)) {
            require(address(this).balance >= amount, "NOT_ENOUGH");
            (bool success,) = receiver.call{value : amount}("");
            require(success, "TRANSFER_FAIL_E");
        } else {
            ERC20Upgradeable tokenERC20 = ERC20Upgradeable(erc20Addr);
            require(tokenERC20.balanceOf(address(this)) > amount, "NOT_ENOUGH");
            // transfer erc-20 token
            bool success = tokenERC20.transfer(receiver, amount);
            require(success == true, "TRANSFER_FAIL_ERC-20");
        }
    }
}