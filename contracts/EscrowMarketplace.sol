// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Libraries/LibEscrowMarket.sol";
import "./AconomyERC2771Context.sol";

contract EscrowMarketplace is
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable,
    AconomyERC2771Context,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using Counters for Counters.Counter;
    Counters.Counter public escrowCount;

    enum EscrowState {
        LISTED,
        AWAITING_PAYMENT,
        AWAITING_SHIPMENT,
        AWAITING_CONFIRMATION,
        COMPLETED,
        DISPUTED,
        LISTING_CANCELED
    }

    struct Escrow {
        address seller;
        address buyer;
        address nftContract;
        address currency;
        uint256 tokenId;
        uint256 price;
        uint256 redeemedAt;
        uint256 bidPrice;
        uint256 bidEndTime;
        bool bidSale;
        bool status;
        EscrowState state;
    }

    /**
     * @notice Deatils for a sale.
     * @param bidId The Id of the bid.
     * @param saleId The Id of the sale.
     * @param sellerAddress The address of the seller.
     * @param buyerAddress The address of the buyer.
     * @param price The price of the bid.
     * @param withdrawn Boolean indicating if the bid has been withdrawn.
     */
    struct BidOrder {
        uint256 bidId;
        uint256 escrowId;
        address sellerAddress;
        address buyerAddress;
        uint256 price;
        bool withdrawn;
    }

    // uint public escrowCount;
    mapping(uint256 => Escrow) public escrows;
    // BidID => BidOrder[]
    mapping(uint256 => BidOrder[]) public Bids;

    event NFTListed(
        uint256 escrowId,
        address seller,
        address nftContract,
        uint256 tokenId,
        uint256 price
    );
    event PaymentDeposited(uint256 escrowId, address buyer, uint256 amount);
    event AssetRedeemed(uint256 escrowId);
    event AssetShipped(uint256 escrowId);
    event DeliveryConfirmed(uint256 escrowId);
    event FundsReleased(uint256 escrowId, address seller);
    event DisputeRaised(uint256 escrowId);
    event SaleCancelled(uint256 escrowId);
     event BidWithdrawn(uint256 escrowId, uint256 bidId);
    
    event BidEvent(
        uint256 tokenId,
        uint256 saleId,
        uint256 bidId,
        uint256 Amount,
        address collectionAddress,
        bool BidCreated
    );

    modifier onlyBuyer(uint256 _escrowId) {
        require(
            msg.sender == escrows[_escrowId].buyer,
            "Only buyer can perform this action"
        );
        _;
    }

    modifier onlySeller(uint256 _escrowId) {
        require(
            msg.sender == escrows[_escrowId].seller,
            "Only seller can perform this action"
        );
        _;
    }

    modifier inState(uint256 _escrowId, EscrowState _state) {
        require(
            escrows[_escrowId].state == _state,
            "Invalid escrow state for this action"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address trustedForwarder) public initializer {
        __ReentrancyGuard_init();
        __ERC721Holder_init();
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        AconomyERC2771Context_init(trustedForwarder);
    }

    // Overrides needed due to multiple inheritance of Context:
    // https://docs.soliditylang.org/en/v0.8.19/contracts.html#function-overriding

    function _msgSender()
        internal
        view
        virtual
        override(AconomyERC2771Context, ContextUpgradeable)
        returns (address sender)
    {
        return AconomyERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(AconomyERC2771Context, ContextUpgradeable)
        returns (bytes calldata)
    {
        return AconomyERC2771Context._msgData();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Function to list an item
    function sellNFT(
        address _nftContract,
        address _currency,
        uint256 _tokenId,
        uint _price
    ) public whenNotPaused {
        uint256 escrowId = escrowCount.current();
        require(_price <= 2500 * (10 ** 6), "Greater that 2500$");
        require(_currency != address(0), "Zero Address Passed");
        require(
            msg.sender == ERC721(_nftContract).ownerOf(_tokenId),
            "Only token owner can execute"
        );

        //needs approval on frontend
        ERC721(_nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        escrows[escrowId] = Escrow({
            seller: payable(msg.sender),
            buyer: payable(address(0)),
            nftContract: _nftContract,
            currency: _currency,
            tokenId: _tokenId,
            price: _price,
            redeemedAt: 0,
            bidPrice: 0,
            bidEndTime: 0,
            bidSale: false,
            status: true,
            state: EscrowState.LISTED
        });
        escrowCount.increment();

        emit NFTListed(escrowId, msg.sender, _nftContract, _tokenId, _price);
    }

    /**
     * @notice Cancels a sale.
     * @param _escrowId The Id of the sale.
     */
    function cancelSale(
        uint256 _escrowId
    )
        external
        inState(_escrowId, EscrowState.LISTED)
        onlySeller(_escrowId)
        nonReentrant
        whenNotPaused
    {
        Escrow storage escrow = escrows[_escrowId];

        escrow.price = 0;
        escrow.state = EscrowState.LISTING_CANCELED;

        // Transfer NFT ownership to the buyer
        ERC721(escrow.nftContract).transferFrom(
            address(this),
            escrow.buyer,
            escrow.tokenId
        );
        emit SaleCancelled(_escrowId);
    }

    // Function to list an item
    function SellNFT_byBid(
        address _nftContract,
        address _currency,
        uint256 _tokenId,
        uint _price,
        uint256 _bidTime
    ) public whenNotPaused {
        uint256 escrowId = escrowCount.current();
        require(_price >= 10000, "Low Price");
        require(_bidTime != 0, "zero Time");
        require(_price <= 2500 * (10 ** 6), "Greater that 2500$");
        require(
            msg.sender == ERC721(_nftContract).ownerOf(_tokenId),
            "Only token owner can execute"
        );

        //needs approval on frontend
        ERC721(_nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        escrows[escrowId] = Escrow({
            seller: payable(msg.sender),
            buyer: payable(address(0)),
            nftContract: _nftContract,
            currency: _currency,
            tokenId: _tokenId,
            price: _price,
            redeemedAt: 0,
            bidPrice: 0,
            bidEndTime: _bidTime,
            bidSale: true,
            status: true,
            state: EscrowState.LISTED
        });
        escrowCount.increment();

        emit NFTListed(escrowId, msg.sender, _nftContract, _tokenId, _price);
    }

    /**
     * @notice Places a bid on an auction sale.
     * @param _escrowId The Id of the sale.
     * @param _bidPrice The amount being bidded
     */
    function Bid(
        uint256 _escrowId,
        uint256 _bidPrice
    ) external inState(_escrowId, EscrowState.LISTED) whenNotPaused {
        LibEscrowMarket.bid(escrows[_escrowId], _bidPrice);

        // require(block.timestamp <= escrows[_escrowId].bidEndTime);
        // escrows[_escrowId].bidPrice = _bidPrice;

        // bool success = IERC20(escrows[_escrowId].currency).transferFrom(
        //     msg.sender,
        //     address(this),
        //     _bidPrice
        // );
        // require(success);

        BidOrder memory bid = BidOrder(
            Bids[_escrowId].length,
            _escrowId,
            escrows[_escrowId].seller,
            msg.sender,
            _bidPrice,
            false
        );
        Bids[_escrowId].push(bid);

        emit BidEvent(
            escrows[_escrowId].tokenId,
            _escrowId,
            Bids[_escrowId].length - 1,
            _bidPrice,
            escrows[_escrowId].nftContract,
            true
        );
    }

    /**
     * @notice executes a sale with a specified bid.
     * @param _escrowId The Id of the sale.
     * @param _bidOrderID The Id of the bid.
     */
    function executeBidOrder(
        uint256 _escrowId,
        uint256 _bidOrderID
    ) external whenNotPaused nonReentrant {
        LibEscrowMarket.executeBid(
            escrows[_escrowId],
            Bids[_escrowId][_bidOrderID]
        );
        escrows[_escrowId].state = EscrowState.AWAITING_PAYMENT;

        emit BidEvent(
            escrows[_escrowId].tokenId,
            _escrowId,
            _bidOrderID,
            Bids[_escrowId][_bidOrderID].price,
            escrows[_escrowId].nftContract,
            false
        );
    }

    /**
     * @notice executes a sale with a specified bid.
     * @param _escrowId The Id of the sale.
     * @param _bidId The Id of the bid.
     */
    function withdrawBidMoney(
        uint256 _escrowId,
        uint256 _bidId
    ) external whenNotPaused nonReentrant {
        LibEscrowMarket.withdrawBid(escrows[_escrowId], Bids[_escrowId][_bidId]);
        emit BidWithdrawn(_escrowId, _bidId);
    }

    // Buyer deposits payment into the escrow contract
    function depositPayment(
        uint _escrowId
    )
        external
        inState(_escrowId, EscrowState.LISTED)
        whenNotPaused
        nonReentrant
    {
        Escrow storage escrow = escrows[_escrowId];

        bool isSuccess = IERC20(escrow.currency).transferFrom(
            msg.sender,
            address(this),
            escrow.price
        );
        require(isSuccess, "Transfer failed");

        escrow.state = EscrowState.AWAITING_PAYMENT;
        escrow.status = false;

        emit PaymentDeposited(_escrowId, msg.sender, escrow.price);
    }

    // Buyer redeems the asset with a delivery address
    function redeemAsset(
        uint _escrowId
    )
        external
        onlyBuyer(_escrowId)
        inState(_escrowId, EscrowState.AWAITING_PAYMENT)
        whenNotPaused
    {
        Escrow storage escrow = escrows[_escrowId];
        escrow.redeemedAt = block.timestamp;
        escrow.state = EscrowState.AWAITING_SHIPMENT;

        emit AssetRedeemed(_escrowId);
    }

    // Buyer redeems the asset with a delivery address
    function lazyRedeemAsset(
        uint _escrowId
    )
        external
        onlyBuyer(_escrowId)
        inState(_escrowId, EscrowState.AWAITING_PAYMENT)
        whenNotPaused
    {
        require(isTrustedForwarder(msg.sender));
        Escrow storage escrow = escrows[_escrowId];
        escrow.redeemedAt = block.timestamp;
        escrow.state = EscrowState.AWAITING_SHIPMENT;

        emit AssetRedeemed(_escrowId);
    }

    // Seller ships the asset or transfers its ownership
    function shipAsset(
        uint _escrowId
    )
        external
        onlySeller(_escrowId)
        inState(_escrowId, EscrowState.AWAITING_SHIPMENT)
        whenNotPaused
        nonReentrant
    {
        Escrow storage escrow = escrows[_escrowId];
        require(
            block.timestamp <= escrow.redeemedAt + 3 days,
            "Seller failed to ship within the allowed time"
        );

        // Transfer NFT ownership to the buyer
        ERC721(escrow.nftContract).transferFrom(
            address(this),
            escrow.buyer,
            escrow.tokenId
        );
        escrow.state = EscrowState.AWAITING_CONFIRMATION;

        emit AssetShipped(_escrowId);
    }

    // Buyer confirms receipt of the NFT
    function confirmDelivery(
        uint _escrowId
    )
        external
        onlyBuyer(_escrowId)
        inState(_escrowId, EscrowState.AWAITING_CONFIRMATION)
        whenNotPaused
        nonReentrant
    {
        Escrow storage escrow = escrows[_escrowId];
        require(
            block.timestamp <= escrow.redeemedAt + 10 days,
            "Confirmation period expired"
        );

        escrow.state = EscrowState.COMPLETED;
        bool isSuccess = IERC20(escrow.currency).transferFrom(
            address(this),
            escrow.seller,
            escrow.price
        );
        require(isSuccess, "Transfer failed");

        emit DeliveryConfirmed(_escrowId);
        emit FundsReleased(_escrowId, escrow.seller);
    }

    // Buyer raises a dispute
    function raiseDispute(
        uint _escrowId
    )
        external
        onlyBuyer(_escrowId)
        inState(_escrowId, EscrowState.AWAITING_CONFIRMATION)
        whenNotPaused
        nonReentrant
    {
        Escrow storage escrow = escrows[_escrowId];
        require(
            block.timestamp <= escrow.redeemedAt + 10 days,
            "Dispute period expired"
        );

        escrow.state = EscrowState.DISPUTED;

        emit DisputeRaised(_escrowId);
    }

    // Automatically handle timeouts
    // function handleTimeouts(
    //     uint _escrowId
    // ) external whenNotPaused nonReentrant {
    //     Escrow storage escrow = escrows[_escrowId];

    //     if (escrow.state == EscrowState.AWAITING_SHIPMENT) {
    //         // If seller fails to ship within 3 days, refund buyer
    //         if (block.timestamp > escrow.redeemedAt + 3 days) {
    //             escrow.state = EscrowState.COMPLETED;
    //             bool isSuccess = IERC20(escrow.currency).transferFrom(
    //                 address(this),
    //                 escrow.buyer,
    //                 escrow.price
    //             );
    //             require(isSuccess, "Transfer failed");
    //         }
    //     } else if (escrow.state == EscrowState.AWAITING_CONFIRMATION) {
    //         // If buyer fails to confirm or dispute within 10 days, release funds to seller
    //         if (block.timestamp > escrow.redeemedAt + 10 days) {
    //             escrow.state = EscrowState.COMPLETED;
    //             bool isSuccess = IERC20(escrow.currency).transferFrom(
    //                 address(this),
    //                 escrow.seller,
    //                 escrow.price
    //             );
    //             require(isSuccess, "Transfer failed");

    //             emit FundsReleased(_escrowId, escrow.seller);
    //         }
    //     }
    // }


    function handleTimeouts(uint _escrowId) external whenNotPaused nonReentrant {
    Escrow storage escrow = escrows[_escrowId];
    
    if (escrow.state == EscrowState.AWAITING_SHIPMENT && 
        block.timestamp > escrow.redeemedAt + 3 days) {
        _completeTimeoutToBuyer(escrow);
    } 
    else if (escrow.state == EscrowState.AWAITING_CONFIRMATION && 
             block.timestamp > escrow.redeemedAt + 10 days) {
        _completeTimeoutToSeller(escrow, _escrowId);
    }
}

function _completeTimeoutToBuyer(Escrow storage escrow) private {
    escrow.state = EscrowState.COMPLETED;
    require(
        IERC20(escrow.currency).transferFrom(
            address(this),
            escrow.buyer,
            escrow.price
        ),
        "Transfer failed"
    );
}

function _completeTimeoutToSeller(Escrow storage escrow, uint256 _escrowId) private {
    escrow.state = EscrowState.COMPLETED;
    require(
        IERC20(escrow.currency).transferFrom(
            address(this),
            escrow.seller,
            escrow.price
        ),
        "Transfer failed"
    );
    emit FundsReleased(_escrowId, escrow.seller);
}


    function resolveDispute(
        uint256 _escrowId,
        bool releaseToSeller
    ) external onlyOwner {
        Escrow storage escrow = escrows[_escrowId];
        require(escrow.state == EscrowState.DISPUTED, "Not in dispute");

        if (releaseToSeller) {
            // Release funds to seller
            IERC20(escrow.currency).transfer(escrow.seller, escrow.price);
        } else {
            // Refund buyer
            IERC20(escrow.currency).transfer(escrow.buyer, escrow.price);
        }

        delete escrows[_escrowId];
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
