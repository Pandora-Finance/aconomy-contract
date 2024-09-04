methods {
    function mintNFT(address, string, LibShare.Share[]) external returns (uint256) envfree;
    function lazyMintNFT(address, string, LibShare.Share[]) external returns (uint256) envfree;
    function getRoyalties(uint256) external returns (LibShare.Share[]) envfree;
    function getValidatorRoyalties(uint256) external returns (LibShare.Share[]) envfree;
    function setRoyaltiesForValidator(uint256, uint256, LibShare.Share[]) external;
    function deleteValidatorRoyalties(uint256) external;
    function deleteNFT(uint256) external;
    function exists(uint256) external returns (bool) envfree;
    function ownerOf(uint256) external returns (address) envfree;
    function piNFTMethodsAddress() external returns (address) envfree;
    function paused() external returns (bool) envfree;
    function isTrustedForwarder(address) external returns (bool) envfree;
}

definition MAX_ROYALTY() returns uint256 = 4900;

// Rule to check that minting increments the token counter
rule mintingIncrementsCounter(address to, string uri, LibShare.Share[] royalties) {
    env e;
    require !paused();
    uint256 tokenIdBefore = mintNFT(e, to, uri, royalties);
    uint256 tokenIdAfter = mintNFT(e, to, uri, royalties);
    assert tokenIdAfter == tokenIdBefore + 1, "Minting should increment token counter";
}


// Rule to check that only piNFTMethods can set validator royalties
rule onlyMethodsCanSetValidatorRoyalties(uint256 tokenId, uint256 commission, LibShare.Share[] royalties) {
    env e;
    require e.msg.sender != piNFTMethodsAddress();
    
    setRoyaltiesForValidator@withrevert(e, tokenId, commission, royalties);
    assert lastReverted, "Only piNFTMethods should be able to set validator royalties";
}

// Rule to check that deleting an NFT removes it from existence
rule deletingNFTRemovesExistence(uint256 tokenId) {
    env e;
    require exists(tokenId);
    require ownerOf(tokenId) == e.msg.sender;
    require !paused();
    
    deleteNFT@withrevert(e, tokenId);
    
    bool deleteSucceeded = !lastReverted;
    assert deleteSucceeded => !exists(tokenId), "Deleted NFT should not exist";
}

// Rule to check that lazy minting can only be called by trusted forwarder
rule lazyMintingOnlyByTrustedForwarder(address to, string uri, LibShare.Share[] royalties) {
    env e;
    require !paused();
    
    lazyMintNFT@withrevert(e, to, uri, royalties);
    bool reverted = lastReverted;
    
    assert !reverted => isTrustedForwarder(e.msg.sender), "Lazy minting should only be allowed by trusted forwarder";
}

