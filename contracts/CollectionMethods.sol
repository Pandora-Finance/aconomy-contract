// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

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
    address public collectionFactoryAddress;

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
    mapping(uint256 => uint256) public withdrawnAmount;

    mapping(uint256 => address) public approvedValidator;

    event ERC20Added(
        address indexed _from,
        uint256 indexed _tokenId,
        address indexed _erc20Contract,
        uint256 _value
    );
    event ERC20Transferred(
        uint256 indexed _tokenId,
        address indexed _to,
        address indexed _erc20Contract,
        uint256 _value
    );

    event RoyaltiesSet(uint256 indexed tokenId, LibShare.Share[] royalties);

    event PiNFTRedeemed(
        uint256 tokenId,
        address nftReciever,
        address validatorAddress,
        address erc20Contract,
        uint256 value
    );

    event PiNFTBurnt(
        uint256 tokenId,
        address nftReciever,
        address erc20Receiver,
        address erc20Contract,
        uint256 value
    );

    event ValidatorFundsWithdrawn(
        address withdrawer,
        uint256 tokenId,
        address erc20Contract,
        uint256 amount
    );

    event ValidatorFundsRepayed(
        address repayer,
        uint256 tokenId,
        address erc20Contract,
        uint256 amount
    );

    event ValidatorAdded(uint256 tokenId, address validator);

    event TokenMinted(uint256 tokenId, address to);

    /**
     * @notice Contract initializer.
     * @param _collectionOwner The address set to own the collection.
     * @param _collectionFactoryAddress The address of the CollectionFactory contract.
     * @param _name the name of the collection being created.
     * @param _symbol the symbol of the collection being created.
     */
    function initialize(
        address _collectionOwner,
        address _collectionFactoryAddress,
        string memory _name,
        string memory _symbol
    ) external initializer {
        __ERC721_init(_name, _symbol);
        __ERC721URIStorage_init();
        collectionOwner = _collectionOwner;
        collectionFactoryAddress = _collectionFactoryAddress;
    }

    modifier onlyOwnerOfToken(uint256 _tokenId) {
        require(msg.sender == ERC721Upgradeable.ownerOf(_tokenId), "Not Owner");
        _;
    }

    /**
     * @notice Mints an nft to a specified address.
     * @param _to address to mint the piNFT to.
     * @param _uri The uri of the piNFT.
     */
    function mintNFT(address _to, string memory _uri) public {
        require(msg.sender == collectionOwner);
        require(_to != address(0));
        uint256 tokenId_ = _tokenIdCounter.current();
        _safeMint(_to, tokenId_);
        _setTokenURI(tokenId_, _uri);
        _tokenIdCounter.increment();
        emit TokenMinted(tokenId_, _to);
    }

    /**
     * @notice Allows the nft owner to add a validator to the piNFT.
     * @param _tokenId The ID of the token.
     * @param _validator The address of the validator.
     */
    function addValidator(
        uint256 _tokenId,
        address _validator
    ) external onlyOwnerOfToken(_tokenId) {
        require(erc20Contracts[_tokenId].length == 0);
        approvedValidator[_tokenId] = _validator;
        emit ValidatorAdded(_tokenId, _validator);
    }

    /**
     * @notice Allows the validator to deposit funds to validate the piNFT.
     * @param _tokenId The ID of the token.
     * @param _erc20Contract The address of the funds being deposited.
     * @param _value The amount of funds being deposited.
     * @param royalties The validator royalties.
     */
    function addERC20(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value,
        LibShare.Share[] memory royalties
    ) public {
        require(msg.sender == approvedValidator[_tokenId]);
        require(_erc20Contract != address(0), "zero");
        require(_value != 0);
        if (erc20Contracts[_tokenId].length >= 1) {
            require(_erc20Contract == erc20Contracts[_tokenId][0], "invalid");
        } else {
            setRoyaltiesForValidator(_tokenId, royalties);
        }
        NFTowner[_tokenId] = ERC721Upgradeable.ownerOf(_tokenId);
        updateERC20(_tokenId, _erc20Contract, _value);
        require(
            IERC20(_erc20Contract).transferFrom(
                msg.sender,
                address(this),
                _value
            ),
            "failed."
        );
        emit ERC20Added(msg.sender, _tokenId, _erc20Contract, _value);
    }

    /**
     * @notice Updates the ERC20 mappings.
     * @param _tokenId The Id of the token.
     * @param _erc20Contract The address of the erc20 funds being transferred.
     * @param _value The amount of funds being transferred.
     */
    function updateERC20(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value
    ) private {
        require(ERC721Upgradeable.ownerOf(_tokenId) != address(0));
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
    }

    /**
     * @notice Checks and sets validator royalties.
     * @param _tokenId The Id of the token.
     * @param royalties The royalties to be set.
     */
    function setRoyaltiesForValidator(
        uint256 _tokenId,
        LibShare.Share[] memory royalties
    ) internal {
        require(msg.sender == approvedValidator[_tokenId]);
        require(royalties.length <= 10);
        delete RoyaltiesForValidator[_tokenId];
        uint256 sumRoyalties = 0;
        for (uint256 i = 0; i < royalties.length; i++) {
            require(royalties[i].account != address(0x0));
            require(royalties[i].value != 0, "Royalty 0");
            RoyaltiesForValidator[_tokenId].push(royalties[i]);
            sumRoyalties += royalties[i].value;
        }
        require(sumRoyalties <= 4000, "overflow");

        emit RoyaltiesSet(_tokenId, royalties);
    }

    /**
     * @notice deletes the nft.
     * @param _tokenId The Id of the token.
     */
    function deleteNFT(uint256 _tokenId) external nonReentrant {
        require(NFTowner[_tokenId] == address(0));
        require(ownerOf(_tokenId) == msg.sender);
        _burn(_tokenId);
    }

    /**
     * @notice Allows the nft owner to redeem or burn the piNFT.
     * @param _tokenId The Id of the token.
     * @param _nftReceiver The receiver of the nft after the function call.
     * @param _erc20Receiver The receiver of the validator funds after the function call.
     * @param _erc20Contract The address of the deposited validator funds.
     * @param burnNFT Boolean to determine redeeming or burning.
     */
    function redeemOrBurnPiNFT(
        uint256 _tokenId,
        address _nftReceiver,
        address _erc20Receiver,
        address _erc20Contract,
        bool burnNFT
    ) external onlyOwnerOfToken(_tokenId) nonReentrant {
        require(approvedValidator[_tokenId] != address(0));
        require(_erc20Contract != address(0));
        require(erc20Balances[_tokenId][_erc20Contract] != 0);
        uint256 _value = erc20Balances[_tokenId][_erc20Contract];
        if (burnNFT) {
            require(_erc20Receiver != address(0));
            require(_nftReceiver == address(0));
            _transferERC20(_tokenId, _erc20Receiver, _erc20Contract, _value);
            ERC721Upgradeable.safeTransferFrom(
                msg.sender,
                approvedValidator[_tokenId],
                _tokenId
            );

            emit PiNFTBurnt(
                _tokenId,
                approvedValidator[_tokenId],
                _erc20Receiver,
                _erc20Contract,
                _value
            );
        } else {
            require(_nftReceiver != address(0));
            require(_erc20Receiver == address(0));
            _transferERC20(
                _tokenId,
                approvedValidator[_tokenId],
                _erc20Contract,
                _value
            );
            if (msg.sender != _nftReceiver) {
                ERC721Upgradeable.safeTransferFrom(
                    msg.sender,
                    _nftReceiver,
                    _tokenId
                );
            }

            emit PiNFTRedeemed(
                _tokenId,
                _nftReceiver,
                approvedValidator[_tokenId],
                _erc20Contract,
                _value
            );
        }
        approvedValidator[_tokenId] = address(0);
        NFTowner[_tokenId] = address(0);
        delete RoyaltiesForValidator[_tokenId];
    }

    /**
     * @notice Transfers ERC20 to a specified account.
     * @param _tokenId The Id of the token.
     * @param _to The address to transfer the funds to.
     * @param _erc20Contract The address of the funds being transferred.
     * @param _value The amount of funds being transferred.
     */
    function _transferERC20(
        uint256 _tokenId,
        address _to,
        address _erc20Contract,
        uint256 _value
    ) private {
        require(_to != address(0));
        removeERC20(_tokenId, _erc20Contract, _value);
        require(IERC20(_erc20Contract).transfer(_to, _value), "failed.");
        emit ERC20Transferred(_tokenId, _to, _erc20Contract, _value);
    }

    /**
     * @notice Updates the ERC20 mappings when removing funds.
     * @param _tokenId The Id of the token.
     * @param _erc20Contract The address of the funds being removed.
     * @param _value The amount of funds being removed.
     */
    function removeERC20(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value
    ) private {
        if (_value == 0) {
            return;
        }
        uint256 erc20Balance = erc20Balances[_tokenId][_erc20Contract];
        require(erc20Balance >= _value, "balance");
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

    /**
     * @notice Returns the specified ERC20 balance of the token.
     * @dev Returned value is type uint256.
     * @param _tokenId The Id of the token.
     * @param _erc20Address The address of the funds to be fetched.
     * @return ERC20 balance of the token.
     */
    function viewBalance(
        uint256 _tokenId,
        address _erc20Address
    ) public view returns (uint256) {
        return erc20Balances[_tokenId][_erc20Address];
    }

    /**
     * @notice Fetches the validator royalties.
     * @dev Returns a LibShare.Share[] array.
     * @param _tokenId The id of the token.
     * @return A LibShare.Share[] struct array of royalties.
     */
    function getValidatorRoyalties(
        uint256 _tokenId
    ) external view returns (LibShare.Share[] memory) {
        return RoyaltiesForValidator[_tokenId];
    }

    /**
     * @notice Allows the nft owner to lock the piNFT in the contract and withdraw validator funds.
     * @param _tokenId The Id of the token.
     * @param _erc20Contract The address of the funds being withdrawn.
     * @param _amount The amount of funds being withdrawn.
     */
    function withdraw(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _amount
    ) external nonReentrant {
        if (withdrawnAmount[_tokenId] == 0) {
            require(msg.sender == ownerOf(_tokenId));
            NFTowner[_tokenId] = msg.sender;
        }
        require(NFTowner[_tokenId] == msg.sender);
        require(erc20Balances[_tokenId][_erc20Contract] != 0);
        require(
            withdrawnAmount[_tokenId] + _amount <=
                erc20Balances[_tokenId][_erc20Contract]
        );
        require(
            IERC20(_erc20Contract).transfer(msg.sender, _amount),
            "transfer failed"
        );

        //needs approval on frontend
        // transferring NFT to this address
        if (withdrawnAmount[_tokenId] == 0) {
            ERC721Upgradeable.safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
        }

        withdrawnAmount[_tokenId] += _amount;
        emit ValidatorFundsWithdrawn(
            msg.sender,
            _tokenId,
            _erc20Contract,
            _amount
        );
    }

    /**
     * @notice Repays the withdrawn validator funds and transfers back token on full repayment.
     * @param _tokenId The Id of the token.
     * @param _erc20Contract The address of the funds to be repaid.
     * @param _amount The amount to be repaid.
     */
    function Repay(
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _amount
    ) external nonReentrant {
        require(NFTowner[_tokenId] == msg.sender);
        require(erc20Balances[_tokenId][_erc20Contract] != 0);
        require(_amount <= withdrawnAmount[_tokenId]);
        // Send payment to the Pool
        require(
            IERC20(_erc20Contract).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "failed"
        );
        withdrawnAmount[_tokenId] -= _amount;

        if (withdrawnAmount[_tokenId] == 0) {
            ERC721Upgradeable(address(this)).safeTransferFrom(
                address(this),
                msg.sender,
                _tokenId
            );
        }
        emit ValidatorFundsRepayed(
            msg.sender,
            _tokenId,
            _erc20Contract,
            _amount
        );
    }

    /**
     * @notice Transfers the piNft after validator funding.
     * @param _tokenId The Id of the token.
     * @param _to The address to transfer to.
     */
    function transferAfterFunding(
        uint256 _tokenId,
        address _to
    ) external nonReentrant {
        require(ERC721Upgradeable.ownerOf(_tokenId) == msg.sender);
        require(msg.sender == NFTowner[_tokenId]);
        NFTowner[_tokenId] = _to;
        //needs approval
        ERC721Upgradeable.safeTransferFrom(msg.sender, _to, _tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
