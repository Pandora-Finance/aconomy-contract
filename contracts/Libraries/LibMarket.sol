// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../utils/LibShare.sol";
import "../piMarket.sol";
import "../AconomyFee.sol";

library LibMarket {

    /**
     * @notice Checks the requiments for a sale to go through.
     * @param meta The metadata of the sale being bought.
     */
    function checkSale(piMarket.TokenMeta storage meta) external view {
        require(meta.status);
        require(msg.sender != address(0) && msg.sender != meta.currentOwner);
        require(!meta.bidSale);
        if (meta.currency == address(0)) {
            require(msg.value == meta.price);
        } else {
            require(
                IERC20(meta.currency).balanceOf(msg.sender) >=
                    meta.price
            );
        }
    }

    /**
     * @notice Executes the sale from the given sale metadata.
     * @param meta The metadata of the sale being executed.
     * @param AconomyFeeAddress The address of AconomyFee contract.
     * @param royalties The token or collection royalties.
     * @param validatorRoyalties the piNFT validatorRoyalties.
     */
    function executeSale(
        piMarket.TokenMeta storage meta,
        address AconomyFeeAddress,
        LibShare.Share[] memory royalties,
        LibShare.Share[] memory validatorRoyalties
    ) external {
        meta.status = false;
        uint16 piMarketFee = AconomyFee(AconomyFeeAddress).AconomyPiMarketFee();
        address AconomyOwner = AconomyFee(AconomyFeeAddress)
            .getAconomyOwnerAddress();

        if (meta.currency == address(0)) {
            uint256 sum = msg.value;
            uint256 val = msg.value;
            
            uint256 fee = (msg.value*piMarketFee)/10000;

            for (uint256 i = 0; i < royalties.length; i++) {
                uint256 amount = (royalties[i].value * val) / 10000;
                (bool royalSuccess, ) = payable(royalties[i].account).call{
                    value: amount
                }("");
                require(royalSuccess, "Royalty Transfer failed");
                sum = sum - amount;
            }

            for (uint256 i = 0; i < validatorRoyalties.length; i++) {
                uint256 amount = (validatorRoyalties[i].value * val) / 10000;
                (bool royalSuccess, ) = payable(validatorRoyalties[i].account)
                    .call{value: amount}("");
                require(royalSuccess, "Royalty Transfer failed");
                sum = sum - amount;
            }

            (bool isSuccess, ) = payable(meta.currentOwner).call{
                value: (sum - fee)
            }("");
            require(isSuccess, "Transfer failed");
            if(piMarketFee != 0) {
                (bool feeSuccess, ) = payable(AconomyOwner).call{value: fee}("");
                require(feeSuccess, "Fee Transfer failed");
            }
            
        } else {
            uint256 sum = meta.price;
            uint256 val = meta.price;
            uint256 fee = (meta.price * piMarketFee) / 10000;

            for (uint256 i = 0; i < royalties.length; i++) {
                uint256 amount = (royalties[i].value * val) / 10000;
                sum = sum - amount;
                // address payable receiver = royalties[i].account;
                bool royalSuccess = IERC20(meta.currency)
                    .transferFrom(msg.sender, royalties[i].account, amount);
                require(royalSuccess, "Transfer failed");
            }

            for (uint256 i = 0; i < validatorRoyalties.length; i++) {
                uint256 amount = (validatorRoyalties[i].value * val) / 10000;
                (bool royalValSuccess) = IERC20(meta.currency).transferFrom(msg.sender, validatorRoyalties[i].account, amount);
                require(royalValSuccess, "Royalty Transfer failed");
                sum = sum - amount;
            }

            bool isSuccess = IERC20(meta.currency).transferFrom(
                msg.sender,
                meta.currentOwner,
                sum - fee
            );
            require(isSuccess, "Transfer failed");
            if(piMarketFee != 0) {
                (bool feeSuccess) = IERC20(meta.currency).transferFrom(
                    msg.sender,
                    AconomyOwner,
                    fee
                );
                require(feeSuccess, "Fee Transfer failed");
            }
            
        }
    }

    /**
     * @notice Checks the requirments for submission of a bid.
     * @param meta The metadata of the sale on which the bid is being placed.
     * @param amount The amount being bidded.
     */
    function checkBid(
        piMarket.TokenMeta storage meta,
        uint256 amount
    ) external view {
        require(meta.currentOwner != msg.sender);
        require(meta.status);
        require(meta.bidSale);
        require(meta.price + ((5 * meta.price) / 100) <= amount);
        if (meta.currency != address(0)) {
            require(
                IERC20(meta.currency).balanceOf(msg.sender) >= amount
            );
        }
    }

    /**
     * @notice executes the the sale with a selected bid.
     * @param meta The metadata of the sale being executed.
     * @param bids The metadata of the bid being executed.
     * @param royalties The token royalties.
     * @param validatorRoyalties The piNFT validator royalties.
     * @param AconomyFeeAddress The address of AconomyFee contract.
     */
    function executeBid(
        piMarket.TokenMeta storage meta,
        piMarket.BidOrder storage bids,
        LibShare.Share[] memory royalties,
        LibShare.Share[] memory validatorRoyalties,
        address AconomyFeeAddress
    ) external {
        require(msg.sender == meta.currentOwner);
        require(!bids.withdrawn);
        require(meta.status);
        meta.status = false;
        meta.price = bids.price;
        bids.withdrawn = true;

        uint16 piMarketFee = AconomyFee(AconomyFeeAddress).AconomyPiMarketFee();
        address AconomyOwner = AconomyFee(AconomyFeeAddress)
            .getAconomyOwnerAddress();

        if (meta.currency == address(0)) {
            uint256 sum = bids.price;
            uint256 fee = (bids.price * piMarketFee)/10000;

            for (uint256 i = 0; i < royalties.length; i++) {
                uint256 amount = (royalties[i].value * bids.price) / 10000;
                // address payable receiver = royalties[i].account;
                (bool royalSuccess, ) = payable(royalties[i].account).call{
                    value: amount
                }("");
                require(royalSuccess, "Royalty transfer failed");
                sum = sum - amount;
            }

            for (uint256 i = 0; i < validatorRoyalties.length; i++) {
                uint256 amount = (validatorRoyalties[i].value * bids.price) / 10000;
                (bool royalSuccess, ) = payable(validatorRoyalties[i].account).call{
                    value: amount
                }("");
                require(royalSuccess, "Royalty transfer failed");
                sum = sum - amount;
            }

            (bool isSuccess, ) = payable(msg.sender).call{value: (sum - fee)}("");
            require(isSuccess, "Transfer failed");
            if(piMarketFee != 0) {
                (bool feeSuccess, ) = payable(AconomyOwner).call{value: fee}("");
                require(feeSuccess, "Fee Transfer failed");
            }
            
        } else {
            uint256 sum = bids.price;
            uint256 fee = (bids.price * piMarketFee)/10000;

            for (uint256 i = 0; i < royalties.length; i++) {
                uint256 amount = (royalties[i].value * bids.price) / 10000;
                // address payable receiver = royalties[i].account;
                bool royalSuccess = IERC20(meta.currency)
                    .transfer(royalties[i].account, amount);
                require(royalSuccess, "Royalty transfer failed");
                sum = sum - amount;
            }

            for (uint256 i = 0; i < validatorRoyalties.length; i++) {
                uint256 amount = (validatorRoyalties[i].value * bids.price) / 10000;
                (bool royalValSuccess) = IERC20(meta.currency).transfer(validatorRoyalties[i].account, amount);
                require(royalValSuccess, "Royalty transfer failed");
                sum = sum - amount;
            }

            bool isSuccess = IERC20(meta.currency).transfer(
                meta.currentOwner,
                sum - fee
            );
            require(isSuccess, "Transfer failed");
            if(piMarketFee != 0) {
                (bool feeSuccess) = IERC20(meta.currency).transfer(
                    AconomyOwner,
                    fee
                );
                require(feeSuccess, "Fee Transfer failed");
            }
            
        }
    }

    /**
     * @notice Withdraws a selected bid as long as it has not been executed for a sale.
     * @param meta The metadata of the sale for which the bid has been placed.
     * @param bids The metadata of the bid being withdrawn.
     */
    function withdrawBid(
        piMarket.TokenMeta storage meta,
        piMarket.BidOrder storage bids
    ) external {
        //require(msg.sender != meta.currentOwner);
        if(block.timestamp > meta.bidEndTime) {
            require(!bids.withdrawn);
            require(bids.buyerAddress == msg.sender);
        } else {
            require(meta.price != bids.price);
            require(bids.buyerAddress == msg.sender);
            require(!bids.withdrawn);
        }

        if (meta.currency == address(0)) {
            (bool success, ) = payable(msg.sender).call{value: bids.price}("");
            if (success) {
                bids.withdrawn = true;
            } else {
                revert("No Money left!");
            }
        } else {
            bool success = IERC20(meta.currency).transfer(
                msg.sender,
                bids.price
            );
            if (success) {
                bids.withdrawn = true;
            } else {
                revert("no Money left!");
            }
        }
    }
}
