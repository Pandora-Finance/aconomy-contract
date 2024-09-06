methods {
    function listNFT(address, uint256, uint256, address) external returns (bool);
    function placeBid(uint256, uint256, uint256, address) external returns (bool);
    function acceptBid(uint256, uint256) external;
    function rejectBid(uint256, uint256) external;
    function repayLoan(uint256) external;
    function claimNFT(uint256) external;
    function removeNFT(uint256) external;
    function getNFTDetails(uint256) external returns (address, uint256, bool, bool, bool, address) envfree;
    function getBidDetails(uint256, uint256) external returns (address, uint256, uint256, uint256, bool, bool, uint256, address) envfree;
    function owner() external returns (address) envfree;
    function paused() external returns (bool) envfree;
}

definition MAX_DURATION() returns uint256 = 30 days;

// Rule to check that listing an NFT sets it as listed
rule listingNFTSetsListed(address nftContract, uint256 tokenId, uint256 minBid, address erc20Contract) {
    env e;
    require !paused();
    
    listNFT(e, nftContract, tokenId, minBid, erc20Contract);
    
    address contractAddress; uint256 nftTokenId; bool listed; bool bidAccepted; bool repaid; address tokenIdOwner;
    contractAddress, nftTokenId, listed, bidAccepted, repaid, tokenIdOwner = getNFTDetails(tokenId);
    
    assert listed, "NFT should be listed after calling listNFT";
}

// Rule to check that only the NFT owner can accept a bid
rule onlyNFTOwnerCanAcceptBid(uint256 nftId, uint256 bidId) {
    env e;
    require !paused();
    
    address contractAddress; uint256 nftTokenId; bool listed; bool bidAccepted; bool repaid; address tokenIdOwner;
    contractAddress, nftTokenId, listed, bidAccepted, repaid, tokenIdOwner = getNFTDetails(nftId);
    
    require e.msg.sender != tokenIdOwner;
    
    acceptBid@withrevert(e, nftId, bidId);
    
    assert lastReverted, "Only NFT owner should be able to accept a bid";
}

// Rule to check that accepting a bid marks it as accepted
rule acceptingBidMarksAsAccepted(uint256 nftId, uint256 bidId) {
    env e;
    require !paused();
    
    acceptBid(e, nftId, bidId);
    
    address bidder; uint256 amount; uint256 duration; uint256 expiration; bool withdrawn; bool bidAccepted; uint256 acceptedTimestamp; address erc20Address;
    bidder, amount, duration, expiration, withdrawn, bidAccepted, acceptedTimestamp, erc20Address = getBidDetails(nftId, bidId);
    
    assert bidAccepted, "Bid should be marked as accepted after calling acceptBid";
}

// Rule to check that repaying a loan marks the NFT as repaid
rule repayingLoanMarksAsRepaid(uint256 nftId) {
    env e;
    require !paused();
    
    repayLoan(e, nftId);
    
    address contractAddress; uint256 nftTokenId; bool listed; bool bidAccepted; bool repaid; address tokenIdOwner;
    contractAddress, nftTokenId, listed, bidAccepted, repaid, tokenIdOwner = getNFTDetails(nftId);
    
    assert repaid, "NFT should be marked as repaid after calling repayLoan";
}

// Invariant to check that bid duration never exceeds maximum duration
invariant bidDurationNeverExceedsMax(uint256 nftId, uint256 bidId)
    getBidDetails(nftId, bidId).duration <= MAX_DURATION()

// Invariant to check that withdrawn bids cannot be accepted
invariant withdrawnBidsCannotBeAccepted(uint256 nftId, uint256 bidId)
    getBidDetails(nftId, bidId).withdrawn => !getBidDetails(nftId, bidId).bidAccepted