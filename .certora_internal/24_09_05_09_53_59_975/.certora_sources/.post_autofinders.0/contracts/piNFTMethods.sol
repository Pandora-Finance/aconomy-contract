// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./utils/LibShare.sol";
import "./piNFT.sol";
import "./AconomyERC2771Context.sol";

contract piNFTMethods is
    ReentrancyGuardUpgradeable,
    AconomyERC2771Context,
    PausableUpgradeable,
    IERC721ReceiverUpgradeable,
    UUPSUpgradeable
{
    //STORAGE START ----------------------------------------------------------------------
    address public piMarketAddress;

    // collectionAddress => tokenId => (token contract => balance)
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        internal erc20Balances;

    // collectionAddress => tokenId => token contract
    mapping(address => mapping(uint256 => address[])) private erc20Contracts;

    // collectionAddress => tokenId => (token contract => token contract index)
    mapping(address => mapping(uint256 => mapping(address => uint256))) erc20ContractIndex;

    // collectionAddress => TokenId => Owner Address
    mapping(address => mapping(uint256 => address)) public NFTowner;

    // collectionAddress => TokenId => Amount
    mapping(address => mapping(uint256 => uint256)) withdrawnAmount;

    // collectionAddress => TokenId => validator
    mapping(address => mapping(uint256 => address)) public approvedValidator;

    // collection Address => tokenId => commission
    mapping (address => mapping(uint256 => Commission)) public validatorCommissions;

    struct Commission {
        LibShare.Share commission;
        bool isValid;
    }

    //STORAGE END -------------------------------------------------------------------------

    event ERC20Added(
        address collectionAddress,
        address indexed from,
        uint256 indexed tokenId,
        address indexed erc20Contract,
        uint256 value,
        string URI,
        uint256 TotalBalance
    );
    event ERC20Transferred(
        address collectionAddress,
        uint256 indexed tokenId,
        address indexed to,
        address indexed erc20Contract,
        uint256 value
    );

    event PiNFTRedeemed(
        address collectionAddress,
        uint256 tokenId,
        address nftReciever,
        address validatorAddress,
        address erc20Contract,
        uint256 value
    );

    event PiNFTBurnt(
        address collectionAddress,
        uint256 tokenId,
        address nftReciever,
        address erc20Receiver,
        address erc20Contract,
        uint256 value
    );

    event ValidatorFundsWithdrawn(
        address collectionAddress,
        address withdrawer,
        uint256 tokenId,
        address erc20Contract,
        uint256 amount
    );

    event ValidatorFundsRepayed(
        address collectionAddress,
        address repayer,
        uint256 tokenId,
        address erc20Contract,
        uint256 amount
    );

    event ValidatorAdded(
        address collectionAddress,
        uint256 tokenId,
        address validator
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address trustedForwarder) public logInternal56(trustedForwarder)initializer {
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        AconomyERC2771Context_init(trustedForwarder);
    }modifier logInternal56(address trustedForwarder) { assembly { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00380000, 1037618708536) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00380001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00381000, trustedForwarder) } _; }

    function setPiMarket(address _piMarket) external onlyOwner {
        piMarketAddress = _piMarket;
    }

    function _msgSender()
        internal
        view
        virtual
        override(AconomyERC2771Context, ContextUpgradeable)
        returns (address sender)
    {assembly { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002c0000, 1037618708524) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002c0001, 0) }
        return AconomyERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(AconomyERC2771Context, ContextUpgradeable)
        returns (bytes calldata)
    {assembly { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002d0000, 1037618708525) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002d0001, 0) }
        return AconomyERC2771Context._msgData();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addValidator(
        address _collectionAddress,
        uint256 _tokenId,
        address _validator
    ) external whenNotPaused {
        require(
            IERC721Upgradeable(_collectionAddress).ownerOf(_tokenId) ==
                msg.sender
        );
        require(erc20Contracts[_collectionAddress][_tokenId].length == 0);
        approvedValidator[_collectionAddress][_tokenId] = _validator;
        emit ValidatorAdded(_collectionAddress, _tokenId, _validator);
    }

    function lazyAddValidator(
        address _collectionAddress,
        uint256 _tokenId,
        address _validator
    ) external whenNotPaused {
        require(isTrustedForwarder(msg.sender));
        require(
            IERC721Upgradeable(_collectionAddress).ownerOf(_tokenId) ==
                AconomyERC2771Context._msgSender()
        );
        require(erc20Contracts[_collectionAddress][_tokenId].length == 0);
        approvedValidator[_collectionAddress][_tokenId] = _validator;
        emit ValidatorAdded(_collectionAddress, _tokenId, _validator);
    }

    // this function requires approval of tokens by _erc20Contract
    /**
     * @notice Allows the validator to deposit funds to validate the piNFT.
     * @param _collectionAddress The address of the collection.
     * @param _tokenId The ID of the token.
     * @param _erc20Contract The address of the funds being deposited.
     * @param _value The amount of funds being deposited.
     * @param _commission The commission of validator.
     * @param royalties The validator royalties.
     */
    function addERC20(
        address _collectionAddress,
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value,
        uint96 _commission,
        string memory _uri,
        LibShare.Share[] memory royalties
    ) public logInternal57(_collectionAddress,_tokenId,_erc20Contract,_value,_commission,_uri,royalties)whenNotPaused nonReentrant{
        require(piNFT(_collectionAddress).exists(_tokenId));
        require(msg.sender == approvedValidator[_collectionAddress][_tokenId]);
        require(_erc20Contract != address(0));
        require(_value != 0);
        if (erc20Contracts[_collectionAddress][_tokenId].length >= 1) {
            require(
                _erc20Contract ==
                    erc20Contracts[_collectionAddress][_tokenId][0],
                "invalid"
            );
            LibShare.setCommission(validatorCommissions[_collectionAddress][_tokenId].commission, _commission);
            piNFT(_collectionAddress).setRoyaltiesForValidator(
                _tokenId,
                _commission,
                royalties
            );
        } else {
            LibShare.setCommission(validatorCommissions[_collectionAddress][_tokenId].commission, _commission);
            validatorCommissions[_collectionAddress][_tokenId].isValid = true;
            piNFT(_collectionAddress).setRoyaltiesForValidator(
                _tokenId,
                _commission,
                royalties
            );
        }
        if(IERC721Upgradeable(_collectionAddress).ownerOf(_tokenId) != address(this)) {
            NFTowner[_collectionAddress][_tokenId] = IERC721Upgradeable(
                _collectionAddress
            ).ownerOf(_tokenId);
        }
        updateERC20(_collectionAddress, _tokenId, _erc20Contract, _value);
        require(
            IERC20Upgradeable(_erc20Contract).transferFrom(
                msg.sender,
                address(this),
                _value
            )
        );
        emit ERC20Added(
            _collectionAddress,
            msg.sender,
            _tokenId,
            _erc20Contract,
            _value,
            _uri,
            erc20Balances[_collectionAddress][_tokenId][_erc20Contract]
        );
    }modifier logInternal57(address _collectionAddress,uint256 _tokenId,address _erc20Contract,uint256 _value,uint96 _commission,string memory _uri,LibShare.Share[] memory royalties) { assembly { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00390000, 1037618708537) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00390001, 7) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00391000, _collectionAddress) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00391001, _tokenId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00391002, _erc20Contract) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00391003, _value) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00391004, _commission) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00391005, _uri) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00391006, royalties) } _; }

    /**
     * @notice Updates the ERC20 mappings.
     * @param _collectionAddress The address of the collection.
     * @param _tokenId The Id of the token.
     * @param _erc20Contract The address of the erc20 funds being transferred.
     * @param _value The amount of funds being transferred.
     */
    function updateERC20(
        address _collectionAddress,
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value
    ) private {assembly { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002f0000, 1037618708527) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002f0001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002f1000, _collectionAddress) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002f1001, _tokenId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002f1002, _erc20Contract) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002f1003, _value) }
        require(
            IERC721Upgradeable(_collectionAddress).ownerOf(_tokenId) !=
                address(0)
        );
        if (_value == 0) {
            return;
        }
        uint256 erc20Balance = erc20Balances[_collectionAddress][_tokenId][
            _erc20Contract
        ];
        if (erc20Balance == 0) {
            erc20ContractIndex[_collectionAddress][_tokenId][
                _erc20Contract
            ] = erc20Contracts[_collectionAddress][_tokenId].length;
            erc20Contracts[_collectionAddress][_tokenId].push(_erc20Contract);
        }
        erc20Balances[_collectionAddress][_tokenId][_erc20Contract] += _value;
    }

    /**
     * @notice Transfers ERC20 to a specified account.
     * @param _collectionAddress The address of the collection.
     * @param _tokenId The Id of the token.
     * @param _to The address to transfer the funds to.
     * @param _erc20Contract The address of the funds being transferred.
     * @param _value The amount of funds being transferred.
     */
    function _transferERC20(
        address _collectionAddress,
        uint256 _tokenId,
        address _to,
        address _erc20Contract,
        uint256 _value
    ) private {assembly { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00300000, 1037618708528) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00300001, 5) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00301000, _collectionAddress) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00301001, _tokenId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00301002, _to) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00301003, _erc20Contract) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00301004, _value) }
        require(_to != address(0));
        removeERC20(_collectionAddress, _tokenId, _erc20Contract, _value);
        require(IERC20Upgradeable(_erc20Contract).transfer(_to, _value));
        emit ERC20Transferred(
            _collectionAddress,
            _tokenId,
            _to,
            _erc20Contract,
            _value
        );
    }

    /**
     * @notice Updates the ERC20 mappings when removing funds.
     * @param _collectionAddress The address of the collection.
     * @param _tokenId The Id of the token.
     * @param _erc20Contract The address of the funds being removed.
     * @param _value The amount of funds being removed.
     */
    function removeERC20(
        address _collectionAddress,
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _value
    ) private {assembly { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002e0000, 1037618708526) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002e0001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002e1000, _collectionAddress) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002e1001, _tokenId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002e1002, _erc20Contract) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff002e1003, _value) }
        if (_value == 0) {
            return;
        }
        uint256 erc20Balance = erc20Balances[_collectionAddress][_tokenId][
            _erc20Contract
        ];
        require(erc20Balance >= _value, "value exceeds");
        uint256 newERC20Balance = erc20Balance - _value;
        erc20Balances[_collectionAddress][_tokenId][
            _erc20Contract
        ] = newERC20Balance;
        if (newERC20Balance == 0) {
            uint256 lastContractIndex = erc20Contracts[_collectionAddress][
                _tokenId
            ].length - 1;
            address lastContract = erc20Contracts[_collectionAddress][_tokenId][
                lastContractIndex
            ];
            if (_erc20Contract != lastContract) {
                uint256 contractIndex = erc20ContractIndex[_collectionAddress][
                    _tokenId
                ][_erc20Contract];
                erc20Contracts[_collectionAddress][_tokenId][
                    contractIndex
                ] = lastContract;
                erc20ContractIndex[_collectionAddress][_tokenId][
                    lastContract
                ] = contractIndex;
            }
            delete erc20ContractIndex[_collectionAddress][_tokenId][
                _erc20Contract
            ];
            erc20Contracts[_collectionAddress][_tokenId].pop();
        }
    }

    /**
     * @notice Allows the nft owner to redeem or burn the piNFT.
     * @param _collectionAddress The address of the collection.
     * @param _tokenId The Id of the token.
     * @param _nftReceiver The receiver of the nft after the function call.
     * @param _erc20Receiver The receiver of the validator funds after the function call.
     * @param _erc20Contract The address of the deposited validator funds.
     * @param burnNFT Boolean to determine redeeming or burning.
     */
    function redeemOrBurnPiNFT(
        address _collectionAddress,
        uint256 _tokenId,
        address _nftReceiver,
        address _erc20Receiver,
        address _erc20Contract,
        bool burnNFT
    ) external nonReentrant whenNotPaused {
        require(
            IERC721Upgradeable(_collectionAddress).ownerOf(_tokenId) ==
                msg.sender
        );
        require(approvedValidator[_collectionAddress][_tokenId] != address(0));
        require(_erc20Contract != address(0));
        require(
            erc20Balances[_collectionAddress][_tokenId][_erc20Contract] != 0
        );
        uint256 _value = erc20Balances[_collectionAddress][_tokenId][
            _erc20Contract
        ];
        if (burnNFT) {
            require(_erc20Receiver != address(0));
            require(_nftReceiver == address(0));
            _transferERC20(
                _collectionAddress,
                _tokenId,
                _erc20Receiver,
                _erc20Contract,
                _value
            );
            IERC721Upgradeable(_collectionAddress).safeTransferFrom(
                msg.sender,
                approvedValidator[_collectionAddress][_tokenId],
                _tokenId
            );

            emit PiNFTBurnt(
                _collectionAddress,
                _tokenId,
                approvedValidator[_collectionAddress][_tokenId],
                _erc20Receiver,
                _erc20Contract,
                _value
            );
        } else {
            require(_nftReceiver != address(0));
            require(_erc20Receiver == address(0));
            _transferERC20(
                _collectionAddress,
                _tokenId,
                approvedValidator[_collectionAddress][_tokenId],
                _erc20Contract,
                _value
            );
            if (msg.sender != _nftReceiver) {
                IERC721Upgradeable(_collectionAddress).safeTransferFrom(
                    msg.sender,
                    _nftReceiver,
                    _tokenId
                );
            }

            emit PiNFTRedeemed(
                _collectionAddress,
                _tokenId,
                _nftReceiver,
                approvedValidator[_collectionAddress][_tokenId],
                _erc20Contract,
                _value
            );
        }
        approvedValidator[_collectionAddress][_tokenId] = address(0);
        NFTowner[_collectionAddress][_tokenId] = address(0);
        delete validatorCommissions[_collectionAddress][_tokenId];
        piNFT(_collectionAddress).deleteValidatorRoyalties(_tokenId);
    }

    /**
     * @notice Returns the specified ERC20 balance of the token.
     * @dev Returned value is type uint256.
     * @param _collectionAddress The address of the collection.
     * @param _tokenId The Id of the token.
     * @param _erc20Address The address of the funds to be fetched.
     * @return ERC20 balance of the token.
     */
    function viewBalance(
        address _collectionAddress,
        uint256 _tokenId,
        address _erc20Address
    ) public view returns (uint256) {assembly { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00330000, 1037618708531) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00330001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00331000, _collectionAddress) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00331001, _tokenId) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00331002, _erc20Address) }
        return erc20Balances[_collectionAddress][_tokenId][_erc20Address];
    }

    /**
     * @notice Allows the nft owner to lock the piNFT in the contract and withdraw validator funds.
     * @param _collectionAddress The address of the collection.
     * @param _tokenId The Id of the token.
     * @param _erc20Contract The address of the funds being withdrawn.
     * @param _amount The amount of funds being withdrawn.
     */
    function withdraw(
        address _collectionAddress,
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _amount
    ) external nonReentrant whenNotPaused {
        if (withdrawnAmount[_collectionAddress][_tokenId] == 0) {
            require(
                msg.sender ==
                    IERC721Upgradeable(_collectionAddress).ownerOf(_tokenId)
            );
            NFTowner[_collectionAddress][_tokenId] = msg.sender;
        }
        require(_amount > 0);
        require(NFTowner[_collectionAddress][_tokenId] == msg.sender);
        require(
            erc20Balances[_collectionAddress][_tokenId][_erc20Contract] != 0
        );
        require(
            withdrawnAmount[_collectionAddress][_tokenId] + _amount <=
                erc20Balances[_collectionAddress][_tokenId][_erc20Contract]
        );
        require(
            IERC20Upgradeable(_erc20Contract).transfer(msg.sender, _amount)
        );

        //needs approval on frontend
        // transferring NFT to this address
        if (withdrawnAmount[_collectionAddress][_tokenId] == 0) {
            IERC721Upgradeable(_collectionAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
        }

        withdrawnAmount[_collectionAddress][_tokenId] += _amount;
        emit ValidatorFundsWithdrawn(
            _collectionAddress,
            msg.sender,
            _tokenId,
            _erc20Contract,
            _amount
        );
    }

    /**
     * @notice Fetches the withdrawn amount for a token.
     * @dev Returns a uint256.
     * @param _collectionAddress The address of the collection.
     * @param _tokenId The id of the token.
     * @return A uint256 of withdrawn amount.
     */
    function viewWithdrawnAmount(
        address _collectionAddress,
        uint256 _tokenId
    ) public view returns (uint256) {assembly { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003a0000, 1037618708538) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003a0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003a1000, _collectionAddress) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003a1001, _tokenId) }
        return withdrawnAmount[_collectionAddress][_tokenId];
    }

    /**
     * @notice Repays the withdrawn validator funds and transfers back token on full repayment.
     * @param _collectionAddress The address of the collection.
     * @param _tokenId The Id of the token.
     * @param _erc20Contract The address of the funds to be repaid.
     * @param _amount The amount to be repaid.
     */
    function Repay(
        address _collectionAddress,
        uint256 _tokenId,
        address _erc20Contract,
        uint256 _amount
    ) external nonReentrant whenNotPaused {
        require(
            NFTowner[_collectionAddress][_tokenId] == msg.sender
        );
        require(
            erc20Balances[_collectionAddress][_tokenId][_erc20Contract] != 0
        );
        require(
            _amount <= withdrawnAmount[_collectionAddress][_tokenId]
        );

        withdrawnAmount[_collectionAddress][_tokenId] -= _amount;

        // Send payment to the Pool
        require(
            IERC20Upgradeable(_erc20Contract).transferFrom(
                msg.sender,
                address(this),
                _amount
            )
        );

        if (withdrawnAmount[_collectionAddress][_tokenId] == 0) {
            IERC721Upgradeable(_collectionAddress).safeTransferFrom(
                address(this),
                msg.sender,
                _tokenId
            );
        }
        emit ValidatorFundsRepayed(
            _collectionAddress,
            msg.sender,
            _tokenId,
            _erc20Contract,
            _amount
        );
    }

    function paidCommission(address _collection, uint256 _tokenId) external {
        require(msg.sender == piMarketAddress);
        validatorCommissions[_collection][_tokenId].isValid = false;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {assembly { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00320000, 1037618708530) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00320001, 4) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00325000, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00325001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00325002, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00325003, 0) }
        return this.onERC721Received.selector;
    }

    function _authorizeUpgrade(address) internal override logInternal49()onlyOwner {}modifier logInternal49(address ) { assembly { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00310000, 1037618708529) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00310001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00315000, 0) } _; }
}
