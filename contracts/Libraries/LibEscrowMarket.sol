// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../EscrowMarketplace.sol";

library LibEscrowMarket {
    /**
     * @notice Checks the requirments for submission of a bid.
     * @param meta The metadata of the sale on which the bid is being placed.
     * @param _bidPrice The amount being bidded.
     */
    // function bid(
    //     EscrowMarketplace.Escrow storage meta,
    //     uint256 _bidPrice
    // ) external {
    //     require(meta.seller != msg.sender, "Seller");
    //     require(meta.bidSale, "Not a BidSale");
    //     require(_bidPrice <= 2500 * (10 ** 6), "Greater that 2500$");
    //     // Next Bid will always be 0.5% extra
    //     require(meta.bidPrice + ((5 * meta.price) / 1000) <= _bidPrice);

    //     require(block.timestamp <= meta.bidEndTime);
    //     meta.bidPrice = _bidPrice;

    //     bool success = IERC20(meta.currency).transferFrom(
    //         msg.sender,
    //         address(this),
    //         _bidPrice
    //     );
    //     require(success);

    // }

    function _validateBid(
        EscrowMarketplace.Escrow storage meta,
        uint256 _bidPrice
    ) private view {
        require(meta.seller != msg.sender, "Seller");
        require(meta.bidSale, "Not a BidSale");
        require(meta.status, "False status");
        require(_bidPrice <= 2500 * (10 ** 6), "Greater that 2500$");
        require(
            meta.bidPrice + ((5 * meta.price) / 1000) <= _bidPrice,
            "Low bid"
        );
        require(block.timestamp <= meta.bidEndTime, "Bid ended");
    }

    function bid(
        EscrowMarketplace.Escrow storage meta,
        uint256 _bidPrice
    ) external {
        // Validate bid parameters
        _validateBid(meta, _bidPrice);

        // Update state before transfer
        meta.bidPrice = _bidPrice;

        // Handle transfer
        bool success = IERC20(meta.currency).transferFrom(
            msg.sender,
            address(this),
            _bidPrice
        );
        require(success, "Transfer failed");
    }

    /**
     * @notice executes the the sale with a selected bid.
     * @param meta The metadata of the sale being executed.
     * @param bids The metadata of the bid being executed.
     */
    function executeBid(
        EscrowMarketplace.Escrow storage meta,
        EscrowMarketplace.BidOrder storage bids
    ) external {
        require(msg.sender == meta.seller);
        require(!bids.withdrawn);
        require(meta.bidSale);
        meta.price = bids.price;
        meta.status = false;
        bids.withdrawn = true;
    }

    /**
     * @notice Withdraws a selected bid as long as it has not been executed for a sale.
     * @param meta The metadata of the sale for which the bid has been placed.
     * @param bids The metadata of the bid being withdrawn.
     */
    function withdrawBid(
        EscrowMarketplace.Escrow storage meta,
        EscrowMarketplace.BidOrder storage bids
    ) external {
        if (block.timestamp > meta.bidEndTime || !meta.status) {
            require(!bids.withdrawn, "withdrawn");
            require(bids.buyerAddress == msg.sender, "You are not Bidder");
        } else {
            require(meta.price != bids.price);
            require(bids.buyerAddress == msg.sender, "You are not Bidder");
            require(!bids.withdrawn);
        }

        bool success = IERC20(meta.currency).transfer(msg.sender, bids.price);
        if (success) {
            bids.withdrawn = true;
        } else {
            revert("no Money left!");
        }
    }
}
