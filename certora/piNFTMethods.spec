methods {
    function addValidator(address, uint256, address) external;
    function lazyAddValidator(address, uint256, address) external;
    function addERC20(address, uint256, address, uint256, uint96, string, LibShare.Share[]) external;
    function redeemOrBurnPiNFT(address, uint256, address, address, address, bool) external;
    function viewBalance(address, uint256, address) external returns (uint256) envfree;
    function withdraw(address, uint256, address, uint256) external;
    function viewWithdrawnAmount(address, uint256) external returns (uint256) envfree;
    function Repay(address, uint256, address, uint256) external;
    function paidCommission(address, uint256) external;
    function piMarketAddress() external returns (address) envfree;
    function NFTowner(address, uint256) external returns (address) envfree;
    function approvedValidator(address, uint256) external returns (address) envfree;
    function paused() external returns (bool) envfree;
    function isTrustedForwarder(address) external returns (bool) envfree;
}

definition MAX_COMMISSION() returns uint96 = 4900; // 49% in basis points

// Rule to check that only the approved validator can add ERC20
rule onlyApprovedValidatorCanAddERC20(address collectionAddress, uint256 tokenId, address erc20Contract, uint256 value, uint96 commission, string uri, LibShare.Share[] royalties) {
    env e;
    require e.msg.sender != approvedValidator(collectionAddress, tokenId);
    
    addERC20@withrevert(e, collectionAddress, tokenId, erc20Contract, value, commission, uri, royalties);
    
    assert lastReverted, "Only approved validator should be able to add ERC20";
}

// Rule to check that commission is within allowed range
rule commissionWithinAllowedRange(address collectionAddress, uint256 tokenId, address erc20Contract, uint256 value, uint96 commission, string uri, LibShare.Share[] royalties) {
    env e;
    
    addERC20@withrevert(e, collectionAddress, tokenId, erc20Contract, value, commission, uri, royalties);
    
    assert !lastReverted => commission <= MAX_COMMISSION(), "Commission should not exceed 49%";
}

// Rule to check that only NFT owner can redeem or burn
rule onlyNFTOwnerCanRedeemOrBurn(address collectionAddress, uint256 tokenId, address nftReceiver, address erc20Receiver, address erc20Contract, bool burnNFT) {
    env e;
    address currentOwner = IERC721Upgradeable(collectionAddress).ownerOf(tokenId);
    require e.msg.sender != currentOwner;
    
    redeemOrBurnPiNFT@withrevert(e, collectionAddress, tokenId, nftReceiver, erc20Receiver, erc20Contract, burnNFT);
    
    assert lastReverted, "Only NFT owner should be able to redeem or burn";
}

// Rule to check that withdrawal amount does not exceed balance
rule withdrawalAmountNotExceedBalance(address collectionAddress, uint256 tokenId, address erc20Contract, uint256 amount) {
    env e;
    uint256 balance = viewBalance(collectionAddress, tokenId, erc20Contract);
    
    withdraw@withrevert(e, collectionAddress, tokenId, erc20Contract, amount);
    
    assert !lastReverted => amount <= balance, "Withdrawal amount should not exceed balance";
}

// Rule to check that repayment amount does not exceed withdrawn amount
rule repaymentAmountNotExceedWithdrawnAmount(address collectionAddress, uint256 tokenId, address erc20Contract, uint256 amount) {
    env e;
    uint256 withdrawnAmount = viewWithdrawnAmount(collectionAddress, tokenId);
    
    Repay@withrevert(e, collectionAddress, tokenId, erc20Contract, amount);
    
    assert !lastReverted => amount <= withdrawnAmount, "Repayment amount should not exceed withdrawn amount";
}

// Rule to check that only piMarket can call paidCommission
rule onlyPiMarketCanCallPaidCommission(address collection, uint256 tokenId) {
    env e;
    require e.msg.sender != piMarketAddress();
    
    paidCommission@withrevert(e, collection, tokenId);
    
    assert lastReverted, "Only piMarket should be able to call paidCommission";
}

// Rule to check that lazy add validator can only be called by trusted forwarder
rule lazyAddValidatorOnlyByTrustedForwarder(address collectionAddress, uint256 tokenId, address validator) {
    env e;
    require !isTrustedForwarder(e.msg.sender);
    
    lazyAddValidator@withrevert(e, collectionAddress, tokenId, validator);
    
    assert lastReverted, "Lazy add validator should only be allowed by trusted forwarder";
}

