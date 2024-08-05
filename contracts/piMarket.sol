// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./piNFT.sol";
import "./CollectionFactory.sol";
import "./CollectionMethods.sol";
import "./utils/LibShare.sol";
import "./Libraries/LibMarket.sol";

contract piMarket is
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using Counters for Counters.Counter;

    //STORAGE START ---------------------------------------------------------------------------------

    Counters.Counter internal _saleIdCounter;
    Counters.Counter private _swapIdCounter;

    /**
     * @notice Deatils for a sale.
     * @param saleId The Id of the sale.
     * @param tokenContractAddress The nft contract address.
     * @param tokenId The Id of the token.
     * @param price The price of the sale.
     * @param directSale Boolean indicating if the sale is a direct sale.
     * @param bidSale Boolean indicating if the sale is an auction.
     * @param status Boolean indicating the status of the sale.
     * @param bidStartTime Timestamp for the start time of the bid.
     * @param bidEndTime Timestamp for the end time of the bid.
     * @param currentOwner The current owner of the nft.
     * @param currency The currency requested for the sale.
     */
    struct TokenMeta {
        uint256 saleId;
        address tokenContractAddress;
        uint256 tokenId;
        uint256 price;
        bool directSale;
        bool bidSale;
        bool status;
        uint256 bidStartTime;
        uint256 bidEndTime;
        address currentOwner;
        address currency;
    }

    /**
     * @notice Deatils for a sale.
     * @param bidId The Id of the bid
     * @param saleId The Id of the sale.
     * @param sellerAddress The address of the seller.
     * @param buyerAddress The address of the buyer.
     * @param price The price of the bid.
     * @param withdrawn Boolean indicating if the bid has been withdrawn.
     */
    struct BidOrder {
        uint256 bidId;
        uint256 saleId;
        address sellerAddress;
        address buyerAddress;
        uint256 price;
        bool withdrawn;
    }

    /**
     * @notice Deatils for a sale.
     * @param initiatorNFTAddress The address of the initiator's nft contract.
     * @param initiator The address of the initiator.
     * @param initiatorNftId The Id of the initiator's token.
     * @param requestedTokenOwner The address of the requested token's owner.
     * @param requestedTokenId The Id of the requested token.
     * @param requestedTokenAddress The address of the requested token's contract.
     * @param status Boolean indicating the status of the swap.
     */
    struct Swap {
        address initiatorNFTAddress;
        address initiator;
        uint256 initiatorNftId;
        address requestedTokenOwner;
        uint256 requestedTokenId;
        address requestedTokenAddress;
        bool status;
    }

    address private feeAddress;
    address private collectionFactoryAddress;
    address private piNFTMethodsAddress;
    mapping(uint256 => TokenMeta) public _tokenMeta;
    mapping(uint256 => BidOrder[]) public Bids;
    mapping(uint256 => Swap) private _swaps;

    //STORAGE END -------------------------------------------------------------------------------------

    event SaleCreated(uint256 tokenId, address tokenContract, uint256 saleId, uint256 BidTimeDuration, uint256 Price);
    event NFTBought(uint256 tokenId, address collectionAddress);
    event SaleCancelled(uint256 saleId);
    event BidEvent(uint256 tokenId, uint256 saleId, uint256 bidId, uint256 Amount, address collectionAddress, bool BidCreated);
    event BidWithdrawn(uint256 saleId, uint256 bidId);
    event SwapCancelled(uint256 swapId);
    event SwapAccepted(uint256 swapId);
    event SwapProposed(
        address indexed to,
        uint256 indexed swapId,
        uint256 outTokenId,
        address outTokenIdAddress,
        uint256 inTokenId,
        address inTokenIdAddress
    );
    event updatedSalePrice(uint256 saleId, uint256 Price, uint256 Duration);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _feeAddress,
        address _collectionFactoryAddress,
        address _piNFTMethodsAddress
    ) public initializer {
        require(_feeAddress != address(0));
        require(_collectionFactoryAddress != address(0));
        __ReentrancyGuard_init();
        __ERC721Holder_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        feeAddress = _feeAddress;
        collectionFactoryAddress = _collectionFactoryAddress;
        piNFTMethodsAddress = _piNFTMethodsAddress;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    modifier onlyOwnerOfToken(address _contractAddress, uint256 _tokenId) {
        require(
            msg.sender == ERC721(_contractAddress).ownerOf(_tokenId),
            "Only token owner can execute"
        );
        _;
    }

    /**
     * @notice Puts an nft on sale.
     * @param _contractAddress the address of the token contract.
     * @param _tokenId The Id of the token.
     * @param _price The price the token is to be listed at.
     * @param _currency The currency being used.
     */
    function sellNFT(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _price,
        address _currency
    )
        external
        onlyOwnerOfToken(_contractAddress, _tokenId)
        whenNotPaused
        nonReentrant
    {
        _saleIdCounter.increment();
        require(_price >= 10000);
        require(_contractAddress != address(0));

        //needs approval on frontend
        ERC721(_contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        TokenMeta memory meta = TokenMeta(
            _saleIdCounter.current(),
            _contractAddress,
            _tokenId,
            _price,
            true,
            false,
            true,
            0,
            0,
            msg.sender,
            _currency
        );

        _tokenMeta[_saleIdCounter.current()] = meta;

        emit SaleCreated(_tokenId, _contractAddress, _saleIdCounter.current(), 0, _price);
    }

    /**
     * @notice Edits the price of the sale.
     * @param _saleId The Id of the sale.
     * @param _price The new price being set.
     */
    function editSalePrice(
        uint256 _saleId,
        uint256 _price,
        uint256 _duration
    ) public whenNotPaused {
        require(
            msg.sender == _tokenMeta[_saleId].currentOwner,
            "You are not the owner"
        );
        require(_tokenMeta[_saleId].status);
        require(_price >= 10000);
        if (_tokenMeta[_saleId].bidSale) {
            require(Bids[_saleId].length == 0, "Bid has started");
        }

        if (_price != _tokenMeta[_saleId].price) {
            _tokenMeta[_saleId].price = _price;

            emit updatedSalePrice(_saleId, _price, _duration);
        }
    }

    /**
     * @notice Retrieves the token royalty.
     * @param _contractAddress the address of the token contract.
     * @param _tokenId The Id of the token.
     */
    function retrieveRoyalty(
        address _contractAddress,
        uint256 _tokenId
    ) public view returns (LibShare.Share[] memory) {
        return piNFT(_contractAddress).getRoyalties(_tokenId);
    }

    /**
     * @notice Fetches the collection royalty.
     * @param _collectionFactoryAddress The address of the CollectionFactory.
     * @param _collectionAddress The address of the collection.
     */
    function getCollectionRoyalty(
        address _collectionFactoryAddress,
        address _collectionAddress
    ) public view returns (LibShare.Share[] memory) {
        uint256 collectionId = CollectionFactory(_collectionFactoryAddress)
            .addressToCollectionId(_collectionAddress);
        return
            CollectionFactory(_collectionFactoryAddress).getCollectionRoyalties(
                collectionId
            );
    }

    /**
     * @notice Fetches the collection validator royalty.
     * @param _collectionAddress The address of the collection.
     * @param _tokenId The Id of the token.
     */
    function getCollectionValidatorRoyalty(
        address _collectionAddress,
        uint256 _tokenId
    ) public view returns (LibShare.Share[] memory) {
        return
            CollectionMethods(_collectionAddress).getValidatorRoyalties(
                _tokenId
            );
    }

    /**
     * @notice Retrieves the validator royalty.
     * @param _contractAddress the address of the token contract.
     * @param _tokenId The Id of the token.
     */
    function retrieveValidatorRoyalty(
        address _contractAddress,
        uint256 _tokenId
    ) public view returns (LibShare.Share[] memory) {
        return piNFT(_contractAddress).getValidatorRoyalties(_tokenId);
    }

    /**
     * @notice Allows a user to buy an nft on sale.
     * @param _saleId The Id of the sale.
     * @param _fromCollection A boolean indicating if the nft is from a priavte collection.
     */
    function BuyNFT(
        uint256 _saleId,
        bool _fromCollection
    ) external payable whenNotPaused nonReentrant {
        TokenMeta memory meta = _tokenMeta[_saleId];

        LibShare.Share[] memory royalties;
        LibShare.Share[] memory validatorRoyalties;
        if (_fromCollection) {
            royalties = getCollectionRoyalty(
                collectionFactoryAddress,
                meta.tokenContractAddress
            );
            validatorRoyalties = getCollectionValidatorRoyalty(
                meta.tokenContractAddress,
                meta.tokenId
            );
        } else {
            royalties = retrieveRoyalty(
                meta.tokenContractAddress,
                meta.tokenId
            );
            validatorRoyalties = retrieveValidatorRoyalty(
                meta.tokenContractAddress,
                meta.tokenId
            );
        }

        LibMarket.checkSale(_tokenMeta[_saleId]);

        LibMarket.executeSale(
            _tokenMeta[_saleId],
            feeAddress,
            piNFTMethodsAddress,
            royalties,
            validatorRoyalties
        );

        ERC721(meta.tokenContractAddress).safeTransferFrom(
            address(this),
            msg.sender,
            meta.tokenId
        );
        emit NFTBought(meta.tokenId, meta.tokenContractAddress);
    }

    /**
     * @notice Cancels a sale.
     * @param _saleId The Id of the sale.
     */
    function cancelSale(uint256 _saleId) external nonReentrant whenNotPaused {
        require(
            msg.sender == _tokenMeta[_saleId].currentOwner
        );
        require(_tokenMeta[_saleId].status);

        _tokenMeta[_saleId].price = 0;
        _tokenMeta[_saleId].status = false;
        ERC721(_tokenMeta[_saleId].tokenContractAddress).safeTransferFrom(
            address(this),
            _tokenMeta[_saleId].currentOwner,
            _tokenMeta[_saleId].tokenId
        );
        emit SaleCancelled(_saleId);
    }

    /**
     * @notice Puts an nft on auction.
     * @param _contractAddress the address of the token contract.
     * @param _tokenId The Id of the token.
     * @param _price The price the token is to be listed at.
     * @param _bidTime The duration time of the auction.
     * @param _currency The currency being used.
     */
    function SellNFT_byBid(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _bidTime,
        address _currency
    )
        external
        onlyOwnerOfToken(_contractAddress, _tokenId)
        nonReentrant
        whenNotPaused
    {
        require(_contractAddress != address(0));
        require(_price >= 10000);
        require(_bidTime != 0);
        _saleIdCounter.increment();

        //needs approval on frontend
        ERC721(_contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        TokenMeta memory meta = TokenMeta(
            _saleIdCounter.current(),
            _contractAddress,
            _tokenId,
            _price,
            false,
            true,
            true,
            block.timestamp,
            block.timestamp + _bidTime,
            msg.sender,
            _currency
        );

        _tokenMeta[_saleIdCounter.current()] = meta;

        emit SaleCreated(_tokenId, _contractAddress, _saleIdCounter.current(), _bidTime, _price);
    }

    /**
     * @notice Places a bid on an auction sale.
     * @param _saleId The Id of the sale.
     * @param _bidPrice The amount being bidded
     */
    function Bid(
        uint256 _saleId,
        uint256 _bidPrice
    ) external payable whenNotPaused {
        if (_tokenMeta[_saleId].currency == address(0)) {
            require(msg.value == _bidPrice);
        }

        LibMarket.checkBid(_tokenMeta[_saleId], _bidPrice);

        require(block.timestamp <= _tokenMeta[_saleId].bidEndTime);
        _tokenMeta[_saleId].price = _bidPrice;

        if (_tokenMeta[_saleId].currency != address(0)) {
            bool success = IERC20(_tokenMeta[_saleId].currency).transferFrom(
                msg.sender,
                address(this),
                _bidPrice
            );
            require(success);
        }

        BidOrder memory bid = BidOrder(
            Bids[_saleId].length,
            _saleId,
            _tokenMeta[_saleId].currentOwner,
            msg.sender,
            _bidPrice,
            false
        );
        Bids[_saleId].push(bid);

        emit BidEvent(_tokenMeta[_saleId].tokenId ,_saleId, Bids[_saleId].length - 1, _bidPrice, _tokenMeta[_saleId].tokenContractAddress, true);
    }

    /**
     * @notice executes a sale with a specified bid.
     * @param _saleId The Id of the sale.
     * @param _bidOrderID The Id of the bid.
     * @param _fromCollection Boolean indicating if the nft is from a private collection.
     */
    function executeBidOrder(
        uint256 _saleId,
        uint256 _bidOrderID,
        bool _fromCollection
    ) external whenNotPaused nonReentrant {
        LibShare.Share[] memory royalties;
        LibShare.Share[] memory validatorRoyalties;
        if (_fromCollection) {
            royalties = getCollectionRoyalty(
                collectionFactoryAddress,
                _tokenMeta[_saleId].tokenContractAddress
            );
            validatorRoyalties = getCollectionValidatorRoyalty(
                _tokenMeta[_saleId].tokenContractAddress,
                _tokenMeta[_saleId].tokenId
            );
        } else {
            royalties = retrieveRoyalty(
                _tokenMeta[_saleId].tokenContractAddress,
                _tokenMeta[_saleId].tokenId
            );
            validatorRoyalties = retrieveValidatorRoyalty(
                _tokenMeta[_saleId].tokenContractAddress,
                _tokenMeta[_saleId].tokenId
            );
        }

        LibMarket.executeBid(
            _tokenMeta[_saleId],
            Bids[_saleId][_bidOrderID],
            royalties,
            validatorRoyalties,
            piNFTMethodsAddress,
            feeAddress
        );

        ERC721(_tokenMeta[_saleId].tokenContractAddress).safeTransferFrom(
            address(this),
            Bids[_saleId][_bidOrderID].buyerAddress,
            _tokenMeta[_saleId].tokenId
        );

        emit BidEvent(
            _tokenMeta[_saleId].tokenId,
            _saleId,
            _bidOrderID,
            Bids[_saleId][_bidOrderID].price,
            _tokenMeta[_saleId].tokenContractAddress,
            false
        );
    }

    /**
     * @notice executes a sale with a specified bid.
     * @param _saleId The Id of the sale.
     * @param _bidId The Id of the bid.
     */
    function withdrawBidMoney(
        uint256 _saleId,
        uint256 _bidId
    ) external whenNotPaused nonReentrant {
        LibMarket.withdrawBid(_tokenMeta[_saleId], Bids[_saleId][_bidId]);
        emit BidWithdrawn(_saleId, _bidId);
    }

    /**
     * @notice Makes a swap request.
     * @param contractAddress1 The contract address of the first token.
     * @param contractAddress2 The contract address of the second token.
     * @param token1 The token Id of the token whose owner is making the request.
     * @param token2 The token Id of the token being requested for the swap.
     */
    function makeSwapRequest(
        address contractAddress1,
        address contractAddress2,
        uint256 token1,
        uint256 token2
    )
        public
        onlyOwnerOfToken(contractAddress1, token1)
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        require(contractAddress1 != address(0));

        require(contractAddress2 != address(0));
        address token2Owner = ERC721(contractAddress2).ownerOf(token2);
        require(token2Owner != msg.sender);
        uint256 swapsId = _swapIdCounter.current();
        ERC721(contractAddress1).safeTransferFrom(
            msg.sender,
            address(this),
            token1
        );

        Swap memory swap = Swap(
            contractAddress1,
            msg.sender,
            token1,
            token2Owner,
            token2,
            contractAddress2,
            true
        );

        _swaps[swapsId] = swap;

        _swapIdCounter.increment();

        emit SwapProposed(token2Owner, swapsId, token1, contractAddress1, token2, contractAddress2);

        return swapsId;
    }

    /**
     * @notice Cancels a swap.
     * @param _swapId The Id of the swap.
     */
    function cancelSwap(uint256 _swapId) public whenNotPaused nonReentrant {
        require(msg.sender == _swaps[_swapId].initiator);
        require(_swaps[_swapId].status);
        _swaps[_swapId].status = false;
        ERC721(_swaps[_swapId].initiatorNFTAddress).safeTransferFrom(
            address(this),
            _swaps[_swapId].initiator,
            _swaps[_swapId].initiatorNftId
        );

        emit SwapCancelled(_swapId);
    }

    /**
     * @notice Accepts and executes a swap.
     * @param swapId The Id of the swap.
     */
    function acceptSwapRequest(
        uint256 swapId
    ) public whenNotPaused nonReentrant {
        Swap storage swap = _swaps[swapId];
        require(swap.status);
        require(
            ERC721(swap.requestedTokenAddress).ownerOf(swap.requestedTokenId) ==
                swap.requestedTokenOwner,
            "requesting token owner has changed"
        );
        require(
            swap.requestedTokenOwner == msg.sender,
            "Only requested owner can accept swap"
        );

        swap.status = false;

        ERC721(swap.initiatorNFTAddress).safeTransferFrom(
            address(this),
            msg.sender,
            swap.initiatorNftId
        );
        ERC721(swap.requestedTokenAddress).safeTransferFrom(
            msg.sender,
            swap.initiator,
            swap.requestedTokenId
        );
        emit SwapAccepted(swapId);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
