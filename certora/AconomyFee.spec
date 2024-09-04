methods {
    function AconomyPoolFee() external returns (uint16) envfree;
    function AconomyPiMarketFee() external returns (uint16) envfree;
    function AconomyNFTLendBorrowFee() external returns (uint16) envfree;
    function getAconomyOwnerAddress() external returns (address) envfree;
    function setAconomyPoolFee(uint16) external;
    function setAconomyPiMarketFee(uint16) external;
    function setAconomyNFTLendBorrowFee(uint16) external;
    function owner() external returns (address) envfree;
}

// Rule to check that only owner can set fees
rule onlyOwnerCanSetFees(uint16 newFee) {
    env e;
    require e.msg.sender != owner();
    
    setAconomyPoolFee@withrevert(e, newFee);
    assert lastReverted, "Non-owner should not be able to set pool fee";
    
    setAconomyPiMarketFee@withrevert(e, newFee);
    assert lastReverted, "Non-owner should not be able to set market fee";
    
    setAconomyNFTLendBorrowFee@withrevert(e, newFee);
    assert lastReverted, "Non-owner should not be able to set NFT fee";
}

// Rule to check that fees cannot be set above 50%
rule feesCannotExceed50Percent(uint16 newFee) {
    env e;
    require newFee > 5000;
    
    setAconomyPoolFee@withrevert(e, newFee);
    assert lastReverted, "Pool fee should not be settable above 50%";
    
    setAconomyPiMarketFee@withrevert(e, newFee);
    assert lastReverted, "Market fee should not be settable above 50%";
    
    setAconomyNFTLendBorrowFee@withrevert(e, newFee);
    assert lastReverted, "NFT fee should not be settable above 50%";
}

// Rule to check that setting a new fee updates the state
rule setFeeUpdatesState(uint16 newFee) {
    env e;
    require newFee <= 5000;
    require newFee != AconomyPoolFee();
    
    setAconomyPoolFee(e, newFee);
    assert AconomyPoolFee() == newFee, "Pool fee should be updated";
    
    require newFee != AconomyPiMarketFee();
    setAconomyPiMarketFee(e, newFee);
    assert AconomyPiMarketFee() == newFee, "Market fee should be updated";
    
    require newFee != AconomyNFTLendBorrowFee();
    setAconomyNFTLendBorrowFee(e, newFee);
    assert AconomyNFTLendBorrowFee() == newFee, "NFT fee should be updated";
}

// Rule to check that getAconomyOwnerAddress returns the correct owner
rule getAconomyOwnerAddressReturnsOwner() {
    assert getAconomyOwnerAddress() == owner(), "getAconomyOwnerAddress should return the owner";
}