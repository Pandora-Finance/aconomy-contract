methods {
    function listNFTforBorrowing(uint256, address, uint16, uint32, uint256, uint256) external returns (uint256);
    function Bid(uint256, uint256, address, uint16, uint32, uint256) external;
    function AcceptBid(uint256, uint256) external;
    function rejectBid(uint256, uint256) external;
    function Repay(uint256, uint256) external;
    function ClaimNFT(uint256, uint256) external;
    function removeNFTfromList(uint256) external;
    function getNFTDetails(uint256) external returns (uint256, address, uint32, uint256, uint256, uint16, bool, bool, bool, bool) envfree;
    function getBidDetails(uint256, uint256) external returns (uint256, uint16, uint32, uint256, address, address, uint256, uint256, uint16, bool, bool) envfree;
    function owner() external returns (address) envfree;
    function paused() external returns (bool) envfree;
}

definition MAX_DURATION() returns uint256 = 30 * 24 * 60 * 60; // 30 days in seconds

// Rule to check that listing an NFT sets it as listed
rule listingNFTSetsListed(uint256 tokenId, address contractAddress, uint16 percent, uint32 duration, uint256 expiration, uint256 expectedAmount) {
    env e;
    require !paused();
    
    uint256 nftId = listNFTforBorrowing(e, tokenId, contractAddress, percent, duration, expiration, expectedAmount);
    
    uint256 nftTokenId; address tokenIdOwner; uint32 nftDuration; uint256 nftExpiration; uint256 nftExpectedAmount; uint16 nftPercent; bool listed; bool bidAccepted; bool repaid; bool claimed;
    nftTokenId, tokenIdOwner, nftDuration, nftExpiration, nftExpectedAmount, nftPercent, listed, bidAccepted, repaid, claimed = getNFTDetails(nftId);
    
    assert listed, "NFT should be listed after calling listNFTforBorrowing";
}

// Rule to check that only the NFT owner can accept a bid
rule onlyNFTOwnerCanAcceptBid(uint256 nftId, uint256 bidId) {
    env e;
    require !paused();
    
    uint256 nftTokenId; address tokenIdOwner; uint32 nftDuration; uint256 nftExpiration; uint256 nftExpectedAmount; uint16 nftPercent; bool listed; bool bidAccepted; bool repaid; bool claimed;
    nftTokenId, tokenIdOwner, nftDuration, nftExpiration, nftExpectedAmount, nftPercent, listed, bidAccepted, repaid, claimed = getNFTDetails(nftId);
    
    require e.msg.sender != tokenIdOwner;
    
    AcceptBid@withrevert(e, nftId, bidId);
    
    assert lastReverted, "Only NFT owner should be able to accept a bid";
}

// Rule to check that accepting a bid marks it as accepted
rule acceptingBidMarksAsAccepted(uint256 nftId, uint256 bidId) {
    env e;
    require !paused();
    
    AcceptBid(e, nftId, bidId);
    
    uint256 bidIdRet; uint16 percent; uint32 duration; uint256 expiration; address bidderAddress; address erc20Address; uint256 amount; uint256 acceptedTimestamp; uint16 protocolFee; bool withdrawn; bool bidAccepted;
    bidIdRet, percent, duration, expiration, bidderAddress, erc20Address, amount, acceptedTimestamp, protocolFee, withdrawn, bidAccepted = getBidDetails(nftId, bidId);
    
    assert bidAccepted, "Bid should be marked as accepted after calling AcceptBid";
}

// Rule to check that repaying a loan marks the NFT as repaid
rule repayingLoanMarksAsRepaid(uint256 nftId, uint256 bidId) {
    env e;
    require !paused();
    
    Repay(e, nftId, bidId);
    
    uint256 nftTokenId; address tokenIdOwner; uint32 nftDuration; uint256 nftExpiration; uint256 nftExpectedAmount; uint16 nftPercent; bool listed; bool bidAccepted; bool repaid; bool claimed;
    nftTokenId, tokenIdOwner, nftDuration, nftExpiration, nftExpectedAmount, nftPercent, listed, bidAccepted, repaid, claimed = getNFTDetails(nftId);
    
    assert repaid, "NFT should be marked as repaid after calling Repay";
}

// Invariant to check that bid duration never exceeds maximum duration
invariant bidDurationNeverExceedsMax(uint256 nftId, uint256 bidId)
    getBidDetails(nftId, bidId).duration <= MAX_DURATION();

// Invariant to check that withdrawn bids cannot be accepted
invariant withdrawnBidsCannotBeAccepted(uint256 nftId, uint256 bidId)
    getBidDetails(nftId, bidId).withdrawn => !getBidDetails(nftId, bidId).bidAccepted;