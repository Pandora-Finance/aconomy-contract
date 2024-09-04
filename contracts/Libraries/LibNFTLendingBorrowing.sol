// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../NFTlendingBorrowing.sol";
import "./LibCalculations.sol";

library LibNFTLendingBorrowing {
    function acceptBid(
        NFTlendingBorrowing.NFTdetail storage nftDetail, 
        NFTlendingBorrowing.BidDetail storage bidDetail, 
        uint256 amountToAconomy,
        address aconomyOwner
        ) external {
        require(!bidDetail.withdrawn, "Already withdrawn");
        require(nftDetail.listed, "It's not listed for Borrowing");
        require(!nftDetail.bidAccepted, "bid already accepted");
        require(!bidDetail.bidAccepted, "Bid Already Accepted");
        require(bidDetail.expiration > block.timestamp, "Bid is expired");
        require(
            nftDetail.tokenIdOwner == msg.sender,
            "You can't Accept This Bid"
        );

        nftDetail.bidAccepted = true;
        bidDetail.bidAccepted = true;
        bidDetail.acceptedTimestamp = block.timestamp;

        // transfering Amount to NFT Owner
        require(
            IERC20(bidDetail.ERC20Address).transfer(
                msg.sender,
                bidDetail.Amount - amountToAconomy
            ),
            "unable to transfer to receiver"
        );

        // transfering Amount to Protocol Owner
        if (amountToAconomy != 0) {
            require(
                IERC20(bidDetail.ERC20Address).transfer(
                    aconomyOwner,
                    amountToAconomy
                ),
                "Unable to transfer to AconomyOwner"
            );
        }

        //needs approval on frontend
        // transferring NFT to this address
        ERC721(nftDetail.contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            nftDetail.NFTtokenId
        );
    }

    function RejectBid(
        NFTlendingBorrowing.NFTdetail storage nftDetail, 
        NFTlendingBorrowing.BidDetail storage bidDetail
    ) external {
        require(!bidDetail.withdrawn, "Already withdrawn");
        require(!bidDetail.bidAccepted, "Bid Already Accepted");
        require(bidDetail.expiration > block.timestamp, "Bid is expired");
        require(
            nftDetail.tokenIdOwner == msg.sender,
            "You can't Reject This Bid"
        );
        bidDetail.withdrawn = true;
        require(
            IERC20(bidDetail.ERC20Address).transfer(
                bidDetail.bidderAddress,
                bidDetail.Amount
            ),
            "unable to transfer to bidder Address"
        );
    }

    
    function removeNFT(
        NFTlendingBorrowing.NFTdetail storage nftDetail
    ) external {
        require(
            msg.sender ==
                ERC721(nftDetail.contractAddress).ownerOf(
                    nftDetail.NFTtokenId
                ),
            "Only token owner can execute"
        );
        require(
            nftDetail.bidAccepted == false,
            "bid has been accepted"
        );
        if (!nftDetail.listed) {
            revert("It's already removed");
        }

        nftDetail.listed = false;
    }

    function claimNFT(
        NFTlendingBorrowing.NFTdetail storage nftDetail, 
        NFTlendingBorrowing.BidDetail storage bidDetail
    ) external {

        require(nftDetail.bidAccepted, "Bid Not Accepted yet");
        require(nftDetail.listed, "It's not listed for Borrowing");
        require(bidDetail.bidAccepted, "Bid not Accepted");
        require(!nftDetail.repaid, "Already Repaid");
        require(block.timestamp > bidDetail.acceptedTimestamp + bidDetail.duration, "You can't claim yet");
        require(msg.sender == bidDetail.bidderAddress, "!Bidder");
        nftDetail.claimed = true;
        // transferring NFT to this address
        ERC721(nftDetail.contractAddress).safeTransferFrom(
            address(this),
            msg.sender,
            nftDetail.NFTtokenId
        );
    }

}