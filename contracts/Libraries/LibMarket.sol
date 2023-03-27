// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../utils/LibShare.sol";
import "../piMarket.sol";

library LibMarket {
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

    function executeSale(
        piMarket.TokenMeta storage meta,
        address feeAddress,
        LibShare.Share[] memory royalties,
        LibShare.Share[] memory validatorRoyalties
    ) external {
        meta.status = false;

        if (meta.currency == address(0)) {
            uint256 sum = msg.value;
            uint256 val = msg.value;
            uint256 fee = msg.value / 100;

            for (uint256 i = 0; i < royalties.length; i++) {
                uint256 amount = (royalties[i].value * val) / 10000;
                // address payable receiver = royalties[i].account;
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
            (bool feeSuccess, ) = payable(feeAddress).call{value: fee}("");
            require(feeSuccess, "Fee Transfer failed");
        } else {
            uint256 sum = meta.price;
            uint256 val = meta.price;
            uint256 fee = meta.price / 100;

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
            (bool feeSuccess) = IERC20(meta.currency).transferFrom(
                msg.sender,
                feeAddress,
                fee
            );
            require(feeSuccess, "Fee Transfer failed");
        }
    }

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

    function executeBid(
        piMarket.TokenMeta storage meta,
        piMarket.BidOrder storage bids,
        LibShare.Share[] memory royalties,
        LibShare.Share[] memory validatorRoyalties,
        address feeAddress
    ) external {
        require(msg.sender == meta.currentOwner);
        require(!bids.withdrawn);
        require(meta.status);
        meta.status = false;
        meta.price = bids.price;
        bids.withdrawn = true;

        if (meta.currency == address(0)) {
            uint256 sum = bids.price;
            uint256 fee = bids.price / 100;

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
            (bool feeSuccess, ) = payable(feeAddress).call{value: fee}("");
            require(feeSuccess, "Fee Transfer failed");
        } else {
            uint256 sum = bids.price;
            uint256 fee = bids.price / 100;

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
            (bool feeSuccess) = IERC20(meta.currency).transfer(
                feeAddress,
                fee
            );
            require(feeSuccess, "Fee Transfer failed");
        }
    }

    function withdrawBid(
        piMarket.TokenMeta storage meta,
        piMarket.BidOrder storage bids
    ) external {
        //require(msg.sender != meta.currentOwner);
        require(meta.price != bids.price);
        require(bids.buyerAddress == msg.sender);
        require(!bids.withdrawn);

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
