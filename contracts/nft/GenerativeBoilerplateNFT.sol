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
import "../lib/helpers/Errors.sol";
import "../lib/configurations/GenerativeBoilerplateNFTConfiguration.sol";
import "../governance/ParameterControl.sol";
import "./GenerativeNFT.sol";

contract GenerativeBoilerplateNFT is Initializable, ERC721PresetMinterPauserAutoIdUpgradeable, ReentrancyGuardUpgradeable, IERC2981Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using ClonesUpgradeable for *;
    using SafeMathUpgradeable for uint256;

    // super admin
    address public _admin;
    // parameter control address
    address public _paramsAddress;

    // projectId is tokenID of project nft
    CountersUpgradeable.Counter private _nextProjectId;

    struct project {
        uint256 _fee; // default frees
        address _feeToken;// default is native token
        uint256 _mintMaxSupply; // max supply can be minted on project
        uint256 _mintTotalSupply; // total supply minted on project
        string _script; // script render: 1/ simplescript 2/ ipfs:// protocol
        string _scriptType; // script type: python, js, ....
        string _paramsTemplate; // template param for project projectId -> config params factor as a json string format {“param1”: “int”, “param2”: “float”, “param3”: “string”, “param4”: {“value": “int”, "min": 1, "max": 20}, "param5": [""]}
        address _creator; // creator list for project, using for royalties
        string _customUri; // project info nft view
        string _projectName;
    }

    mapping(uint256 => project) public _projects;

    // generated NFT contract -> project ID
    mapping(address => uint256) public _nftContractProject;
    // owner generated NFT -> projectId -> deployed generated NFT
    mapping(address => mapping(uint256 => address)) public _nftContracts;

    modifier adminOnly() {
        require(_msgSender() == _admin, "ONLY_ADMIN_ALLOWED");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ONLY_ADMIN_ALLOWED");
        _;
    }

    modifier creatorOnly(uint256 _id) {
        require(_projects[_id]._creator == msg.sender, "ONLY_CREATOR");
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseUri,
        address admin,
        address paramsAddress
    ) initializer public {
        require(admin != address(0x0), Errors.INV_ADD);
        require(paramsAddress != address(0x0), Errors.INV_ADD);
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
        uint256 operationFee = _p.getUInt256(GenerativeBoilerplateNFTConfiguration.CREATE_PROJECT_FEE);
        if (operationFee > 0) {
            address operationFeeToken = _p.getAddress(GenerativeBoilerplateNFTConfiguration.FEE_TOKEN);
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
            _projects[currentTokenId]._customUri = uri;
        }
        if (bytes(projectName).length > 0) {
            _projects[currentTokenId]._projectName = projectName;
        }
        _projects[currentTokenId]._creator = msg.sender;
        _projects[currentTokenId]._mintMaxSupply = maxSupply;
        require(fee >= 0, "INV_FEE");
        _projects[currentTokenId]._fee = fee;
        _projects[currentTokenId]._feeToken = feeAdd;
        _projects[currentTokenId]._paramsTemplate = paramsTemplate;
        _projects[currentTokenId]._script = script;
        _projects[currentTokenId]._scriptType = scriptType;

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
        require(_projects[fromProjectId]._mintMaxSupply == 0 || _projects[fromProjectId]._mintTotalSupply < _projects[fromProjectId]._mintMaxSupply, "REACH_MAX");
        ParameterControl _p = ParameterControl(_paramsAddress);

        // get payable
        uint256 _mintFee = _projects[fromProjectId]._fee;
        if (_mintFee > 0) {
            uint256 operationFee = _p.getUInt256(GenerativeBoilerplateNFTConfiguration.MINT_NFT_FEE);
            if (operationFee == 0) {
                operationFee = 500;
                // default 5% getting, 95% pay for owner of project
            }
            bool isNative = _projects[fromProjectId]._feeToken == address(0);
            if (isNative) {
                require(msg.value >= _mintFee, "TRANSFER_FAIL_FEE_ETH");

                // pay for owner project
                (bool success,) = ownerOf(fromProjectId).call{value : _mintFee - (_mintFee * operationFee / 10000)}("");
                require(success, "FAIL");
            } else {
                ERC20Upgradeable tokenERC20 = ERC20Upgradeable(_projects[fromProjectId]._feeToken);
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
            generativeNFTAdd = ClonesUpgradeable.clone(_p.getAddress(GenerativeBoilerplateNFTConfiguration.GENERATIVE_NFT_TEMPLATE));
            _nftContracts[msg.sender][fromProjectId] = generativeNFTAdd;
            _nftContractProject[generativeNFTAdd] = fromProjectId;

            GenerativeNFT nft = GenerativeNFT(generativeNFTAdd);
            string memory initName = string(abi.encodePacked(_projects[fromProjectId]._projectName, " by ", Strings.toHexString(uint256(uint160(msg.sender)), 20)));
            nft.init(initName, "", msg.sender, address(this), fromProjectId);
            nft.mint(mintTo, msg.sender, uri, paramTemplateValue);
        } else {
            GenerativeNFT nft = GenerativeNFT(generativeNFTAdd);
            nft.mint(mintTo, msg.sender, uri, paramTemplateValue);
        }
        _projects[fromProjectId]._mintTotalSupply += 1;
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
        require(_projects[fromProjectId]._mintMaxSupply == 0 || _projects[fromProjectId]._mintTotalSupply + uris.length <= _projects[fromProjectId]._mintMaxSupply, "REACH_MAX");
        ParameterControl _p = ParameterControl(_paramsAddress);

        // get payable
        uint256 _mintFee = _projects[fromProjectId]._fee;
        if (_mintFee > 0) {
            _mintFee *= uris.length;
            uint256 operationFee = _p.getUInt256(GenerativeBoilerplateNFTConfiguration.MINT_NFT_FEE);
            if (operationFee == 0) {
                operationFee = 500;
                // default 5% getting, 95% pay for owner of project
            }
            bool isNative = _projects[fromProjectId]._feeToken == address(0);
            if (isNative) {
                require(msg.value >= _mintFee, "TRANSFER_FAIL_FEE_ETH");

                // pay for owner project
                (bool success,) = ownerOf(fromProjectId).call{value : _mintFee - (_mintFee * operationFee / 10000)}("");
                require(success, "FAIL");
            } else {
                ERC20Upgradeable tokenERC20 = ERC20Upgradeable(_projects[fromProjectId]._feeToken);
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
        for (uint256 i = 0; i < paramTemplateValues.length; i++) {
            if (generativeNFTAdd == address(0x0)) {
                // deploy new by clone from template address
                generativeNFTAdd = ClonesUpgradeable.clone(_p.getAddress(GenerativeBoilerplateNFTConfiguration.GENERATIVE_NFT_TEMPLATE));
                _nftContracts[msg.sender][fromProjectId] = generativeNFTAdd;
                _nftContractProject[generativeNFTAdd] = fromProjectId;

                GenerativeNFT nft = GenerativeNFT(generativeNFTAdd);
                string memory initName = string(abi.encodePacked(_projects[fromProjectId]._projectName, " by ", Strings.toHexString(uint256(uint160(msg.sender)), 20)));
                nft.init(initName, "", msg.sender, address(this), fromProjectId);
                nft.mint(mintTo, msg.sender, uris[i], paramTemplateValues[i]);
            } else {
                GenerativeNFT nft = GenerativeNFT(generativeNFTAdd);
                nft.mint(mintTo, msg.sender, uris[i], paramTemplateValues[i]);
            }
            _projects[fromProjectId]._mintTotalSupply += 1;
        }
        return generativeNFTAdd;
    }

    function burn(uint256 tokenId) public override {
        _projects[tokenId]._creator = address(0x0);
        super.burn(tokenId);
    }

    function _setCreator(address _to, uint256 _id) internal creatorOnly(_id)
    {
        _projects[_id]._creator = _to;
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
        _projects[_tokenId]._customUri = _newURI;
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return _baseURI();
    }

    function mintMaxSupply(uint256 _tokenID) public view returns (uint256) {
        return _projects[_tokenID]._mintMaxSupply;
    }

    function mintTotalSupply(uint256 _tokenID) public view returns (uint256) {
        return _projects[_tokenID]._mintTotalSupply;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        bytes memory customUriBytes = bytes(_projects[_tokenId]._customUri);
        if (customUriBytes.length > 0) {
            return _projects[_tokenId]._customUri;
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
            receiver = _projects[_tokenId]._creator;
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