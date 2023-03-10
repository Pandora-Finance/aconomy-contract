// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "./Libraries/LibCollection.sol";
import "./utils/LibShare.sol";

contract CollectionMethods is
    Initializable,
    ERC721URIStorageUpgradeable,
    IERC721ReceiverUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    address public collectionOwner;
    address public piNFTAddress;

    // tokenId => collection royalties
    mapping(uint256 => LibShare.Share[]) public RoyaltiesForValidator;

    // tokenId => (token contract => balance)
    mapping(uint256 => mapping(address => uint256)) erc20Balances;

    // tokenId => token contract
    mapping(uint256 => address[]) erc20Contracts;

    // tokenId => (token contract => token contract index)
    mapping(uint256 => mapping(address => uint256)) erc20ContractIndex;

    // TokenId => Owner Address
    mapping(uint256 => address) NFTowner;

    // TokenId => Amount
    mapping(uint256 => uint256) withdrawnAmount;

    mapping(uint256 => address) public approvedValidator;

    event ReceivedERC20(
        address indexed _from,
        uint256 indexed _tokenId,
        address indexed _erc20Contract,
        uint256 _value
    );
    event TransferERC20(
        uint256 indexed _tokenId,
        address indexed _to,
        address indexed _erc20Contract,
        uint256 _value
    );

    event Royalties(
        uint256 indexed tokenId,
        LibShare.Share[] indexed royalties
    );

    event mintToken(uint256 tokenId);

    function initialize(
        address _collectionOwner,
        address _piNFTAddress,
        string memory _name,
        string memory _symbol
    ) external initializer {
        __ERC721_init(_name, _symbol);
        __ERC721URIStorage_init();
        collectionOwner = _collectionOwner;
        piNFTAddress = _piNFTAddress;
    }

    modifier onlyOwnerOfToken(uint256 _tokenId) {
        require(
            msg.sender == ERC721Upgradeable.ownerOf(_tokenId),
            "Only token owner can execute"
        );
        _;
    }

    // mints an ERC721 token to _to with _uri as token uri
    function mintNFT(address _to, string memory _uri) public {
        require(
            msg.sender == collectionOwner,
            "You are not the collection Owner"
        );
        require(_to != address(0), "You can't mint with 0 address");
        uint256 tokenId_ = _tokenIdCounter.current();
        _safeMint(_to, tokenId_);
        _setTokenURI(tokenId_, _uri);
        _tokenIdCounter.increment();
        emit mintToken(tokenId_);
    }

    function addValidator(uint256 _tokenId, address _validator) external onlyOwnerOfToken(_tokenId){
        approvedValidator[_tokenId] = _validator;
    }

    // this function requires approval of tokens by _erc20Contract
    // adds ERC20 tokens to the token with _tokenId(basically trasnfer ERC20 to this contract)
    function addERC20(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value,
        LibShare.Share[] memory royalties
    ) public {
        require(msg.sender == approvedValidator[_tokenId]);
        require(
            _erc20Contract != address(0),
            "you can't do this with zero address"
        );
        require(_value != 0);
        require(erc20Contracts[_tokenId].length < 1);
        NFTowner[_tokenId] = ERC721Upgradeable.ownerOf(_tokenId);
        erc20Added(msg.sender, _tokenId, _erc20Contract, _value);
        setRoyaltiesForValidator(_tokenId, royalties);
        require(
            IERC20(_erc20Contract).transferFrom(
                msg.sender,
                address(this),
                _value
            ),
            "ERC20 transfer failed."
        );
    }

    // update the mappings for a token on recieving ERC20 tokens
    function erc20Added(
        address _from,
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value
    ) private {
        require(
            ERC721Upgradeable.ownerOf(_tokenId) != address(0),
            "_tokenId does not exist."
        );
        if (_value == 0) {
            return;
        }
        uint256 erc20Balance = erc20Balances[_tokenId][_erc20Contract];
        if (erc20Balance == 0) {
            erc20ContractIndex[_tokenId][_erc20Contract] = erc20Contracts[
                _tokenId
            ].length;
            erc20Contracts[_tokenId].push(_erc20Contract);
        }
        erc20Balances[_tokenId][_erc20Contract] += _value;
        emit ReceivedERC20(_from, _tokenId, _erc20Contract, _value);
    }

    //Set Royalties for Validator
    function setRoyaltiesForValidator(
        uint256 _tokenId,
        LibShare.Share[] memory royalties
    ) internal {
        require(royalties.length <= 10, "Atmost 10 royalties can be added");
        delete RoyaltiesForValidator[_tokenId];
        uint256 sumRoyalties = 0;
        for (uint256 i = 0; i < royalties.length; i++) {
            require(
                royalties[i].account != address(0x0),
                "Royalty recipient should be present"
            );
            require(royalties[i].value != 0, "Royalty value should be > 0");
            RoyaltiesForValidator[_tokenId].push(royalties[i]);
            sumRoyalties += royalties[i].value;
        }
        require(sumRoyalties < 10000, "Sum of Royalties > 100%");

        emit Royalties(_tokenId, royalties);
    }

    function redeemPiNFT(
        uint256 _tokenId,
        address _nftReciever,
        address _validatorAddress,
        address _erc20Contract,
        uint256 _value
    ) external onlyOwnerOfToken(_tokenId) nonReentrant {
        require(_validatorAddress == approvedValidator[_tokenId]);
        require(_nftReciever != address(0), "cannot transfer to zero address");
        require(
            _erc20Contract != address(0),
            "you can't do this with zero address"
        );
        require(erc20Balances[_tokenId][_erc20Contract] != 0);
        require(erc20Balances[_tokenId][_erc20Contract] == _value);
        approvedValidator[_tokenId] = address(0);
        NFTowner[_tokenId] = address(0);
        _transferERC20(_tokenId, _validatorAddress, _erc20Contract, _value);
        if(msg.sender != _nftReciever) {
            ERC721Upgradeable.safeTransferFrom(msg.sender, _nftReciever, _tokenId);
        }
    }

    function burnPiNFT(
        uint256 _tokenId,
        address _nftReciever,
        address _erc20Reciever,
        address _erc20Contract,
        uint256 _value
    ) external onlyOwnerOfToken(_tokenId) nonReentrant {
        require(_nftReciever != address(0), "cannot transfer to zero address");
        require(_nftReciever == approvedValidator[_tokenId]);
        require(
            _erc20Contract != address(0),
            "you can't do this with zero address"
        );
        require(erc20Balances[_tokenId][_erc20Contract] != 0);
        require(erc20Balances[_tokenId][_erc20Contract] == _value);
        approvedValidator[_tokenId] = address(0);
        NFTowner[_tokenId] = address(0);
        _transferERC20(_tokenId, _erc20Reciever, _erc20Contract, _value);
        ERC721Upgradeable.safeTransferFrom(msg.sender, _nftReciever, _tokenId);
    }

    // transfers the ERC 20 tokens from _tokenId(this contract) to _to address
    function _transferERC20(
        uint256 _tokenId,
        address _to,
        address _erc20Contract,
        uint256 _value
    ) private {
        require(_to != address(0), "cannot send to zero address");
        removeERC20(_tokenId, _erc20Contract, _value);
        require(
            IERC20(_erc20Contract).transfer(_to, _value),
            "ERC20 transfer failed."
        );
        emit TransferERC20(_tokenId, _to, _erc20Contract, _value);
    }

    // update the mappings for a token when ERC20 tokens gets removed
    function removeERC20(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value
    ) private {
        if (_value == 0) {
            return;
        }
        uint256 erc20Balance = erc20Balances[_tokenId][_erc20Contract];
        require(
            erc20Balance >= _value,
            "Not enough token available to transfer."
        );
        uint256 newERC20Balance = erc20Balance - _value;
        erc20Balances[_tokenId][_erc20Contract] = newERC20Balance;
        if (newERC20Balance == 0) {
            uint256 lastContractIndex = erc20Contracts[_tokenId].length - 1;
            address lastContract = erc20Contracts[_tokenId][lastContractIndex];
            if (_erc20Contract != lastContract) {
                uint256 contractIndex = erc20ContractIndex[_tokenId][
                    _erc20Contract
                ];
                erc20Contracts[_tokenId][contractIndex] = lastContract;
                erc20ContractIndex[_tokenId][lastContract] = contractIndex;
            }
            delete erc20ContractIndex[_tokenId][_erc20Contract];
            erc20Contracts[_tokenId].pop();
        }
    }

    // view ERC 20 token balance of a token
    function viewBalance(uint256 _tokenId, address _erc20Address)
        public
        view
        returns (uint256)
    {
        return erc20Balances[_tokenId][_erc20Address];
    }

    function getValidatorRoyalties(uint256 _tokenId)
        external
        view
        returns (LibShare.Share[] memory)
    {
        return RoyaltiesForValidator[_tokenId];
    }

    function viewWithdrawnAmount(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return withdrawnAmount[_tokenId];
    }

    function withdraw(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _amount
    ) external nonReentrant {
        require(NFTowner[_tokenId] == msg.sender, "You can't withdraw");
        require(erc20Balances[_tokenId][_erc20Contract] != 0);
        require(withdrawnAmount[_tokenId] + _amount <= erc20Balances[_tokenId][_erc20Contract]);
        require(
            IERC20(_erc20Contract).transfer(msg.sender, _amount),
            "unable to transfer to receiver"
        );
        
        //needs approval on frontend
        // transferring NFT to this address
        if(withdrawnAmount[_tokenId] == 0) {
            ERC721Upgradeable.safeTransferFrom(msg.sender, address(this), _tokenId);
        }

        withdrawnAmount[_tokenId] += _amount;
    }

    function Repay(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _amount
    ) external nonReentrant {
        require(NFTowner[_tokenId] == msg.sender, "You can't withdraw");
        require(erc20Balances[_tokenId][_erc20Contract] != 0);
        require(_amount <= withdrawnAmount[_tokenId]);
        // Send payment to the Pool
        require(
            IERC20(_erc20Contract).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Unable to tansfer to poolAddress"
        );
        withdrawnAmount[_tokenId] -= _amount;

        if (withdrawnAmount[_tokenId] == 0) {
            ERC721Upgradeable(address(this)).approve(msg.sender, _tokenId);
            ERC721Upgradeable.safeTransferFrom(
                address(this),
                msg.sender,
                _tokenId
            );
        }
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
