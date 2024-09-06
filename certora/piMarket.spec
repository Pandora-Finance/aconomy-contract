using CollectionFactory as collectionFactory;
using piNFTMethods as piNFTMethods;

methods {
    // piMarket methods
    function createSale(address, uint256, uint256, bool, bool, address) external returns (uint256) envfree;
    function cancelSale(uint256) external;
    function buyNFT(uint256) external payable;
    function createBid(uint256, uint256) external payable;
    function withdrawBid(uint256, uint256) external;    
    function acceptBid(uint256, uint256) external;
    function updateSalePrice(uint256, uint256, uint256) external;
    function createSwap(address, uint256, address, uint256, address) external returns (uint256) envfree;
    function acceptSwap(uint256) external;
    function cancelSwap(uint256) external;
    function _tokenMeta(uint256) external returns (TokenMeta) envfree;
    function Bids(uint256, uint256) external returns (BidOrder) envfree;
    function _swaps(uint256) external returns (Swap) envfree;
    function feeAddress() external returns (address) envfree;
    function collectionFactoryAddress() external returns (address) envfree;
    function piNFTMethodsAddress() external returns (address) envfree;
    function piNFTaddress() external returns (address) envfree;
    function paused() external returns (bool) envfree;
    function owner() external returns (address) envfree;

    // CollectionFactory methods
    function collectionFactory.piNFTMethodsAddress() external returns (address) envfree;

    // piNFTMethods methods
    function piNFTMethods.NFTowner(address, uint256) external returns (address) envfree;
}

definition MAX_FEE() returns uint256 = 1000; // 10% in basis points

// Rule to check that only the owner can create a sale
rule onlyOwnerCanCreateSale(address tokenContract, uint256 tokenId, uint256 price, bool directSale, bool bidSale, address currency) {
    env e;
    address tokenOwner = piNFTMethods.NFTowner(tokenContract, tokenId);
    require e.msg.sender != tokenOwner;
    createSale@withrevert(e, tokenContract, tokenId, price, directSale, bidSale, currency);
    assert lastReverted, "Only token owner should be able to create a sale";
}

// Rule to check that only the sale creator can cancel a sale
rule onlyCreatorCanCancelSale(uint256 saleId) {
    env e;
    TokenMeta meta = _tokenMeta(saleId);
    require e.msg.sender != meta.currentOwner;
    cancelSale@withrevert(e, saleId);
    assert lastReverted, "Only sale creator should be able to cancel a sale";
}

// Rule to check that buying an NFT transfers ownership
rule buyingNFTTransfersOwnership(uint256 saleId) {
    env e;
    address buyerBefore = piNFTMethods.NFTowner(e, _tokenMeta(saleId).tokenContractAddress, _tokenMeta(saleId).tokenId);
    buyNFT(e, saleId);
    address buyerAfter = piNFTMethods.NFTowner(e, _tokenMeta(saleId).tokenContractAddress, _tokenMeta(saleId).tokenId);
    assert buyerAfter == e.msg.sender && buyerAfter != buyerBefore, "Buying NFT should transfer ownership";
}

// Rule to check that creating a bid increases the number of bids
rule creatingBidIncreasesBidCount(uint256 saleId, uint256 bidAmount) {
    env e;
    uint256 bidCountBefore = Bids(saleId).length;
    createBid(e, saleId, bidAmount);
    uint256 bidCountAfter = Bids(saleId).length;
    assert bidCountAfter == bidCountBefore + 1, "Creating a bid should increase the bid count";
}

// Invariant to check that the fee is always within the allowed range
invariant feeWithinAllowedRange()
    _tokenMeta(saleId).price * MAX_FEE() / 10000 >= feeAddress();

// Rule to check that only the swap initiator can cancel a swap
rule onlyInitiatorCanCancelSwap(uint256 swapId) {
    env e;
    Swap swap = _swaps(swapId);
    require e.msg.sender != swap.initiator;
    cancelSwap@withrevert(e, swapId);
    assert lastReverted, "Only swap initiator should be able to cancel a swap";
}

// Rule to check that accepting a swap transfers ownership of both NFTs
rule acceptingSwapTransfersOwnership(uint256 swapId) {
    env e;
    Swap swap = _swaps(swapId);
    address initiatorBefore = piNFTMethods.NFTowner(e, swap.initiatorNFTAddress, swap.initiatorNftId);
    address requestedOwnerBefore = piNFTMethods.NFTowner(e, swap.requestedTokenAddress, swap.requestedTokenId);
    acceptSwap(e, swapId);
    address initiatorAfter = piNFTMethods.NFTowner(e, swap.initiatorNFTAddress, swap.initiatorNftId);
    address requestedOwnerAfter = piNFTMethods.NFTowner(e, swap.requestedTokenAddress, swap.requestedTokenId);
    assert initiatorAfter == swap.requestedTokenOwner && requestedOwnerAfter == swap.initiator, "Accepting swap should transfer ownership of both NFTs";
}