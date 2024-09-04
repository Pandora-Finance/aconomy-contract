methods {
    function collectionId() external returns (uint256) envfree;
    function collections(uint256) external returns (string, string, string, address, address, string) envfree;
    function addressToCollectionId(address) external returns (uint256) envfree;
    function royaltiesForCollection(uint256) external returns (LibShare.Share[]) envfree;
    function piNFTMethodsAddress() external returns (address) envfree;
    function createCollection(string, string, string, string, LibShare.Share[]) external returns (uint256);
    function setRoyaltiesForCollection(uint256, LibShare.Share[]) external;
    function setCollectionURI(uint256, string) external;
    function setCollectionName(uint256, string) external;
    function setCollectionSymbol(uint256, string) external;
    function setCollectionDescription(uint256, string) external;
    function changeCollectionMethodImplementation(address) external;
    function getCollectionRoyalties(uint256) external returns (LibShare.Share[]) envfree;
    function LibCollection.deployCollectionAddress(address, address, string, string, address) external returns (address) envfree;
    function paused() external returns (bool) envfree;
    function owner() external returns (address) envfree;
}

definition MAX_ROYALTY() returns uint256 = 4900;

// Rule to check that creating a collection increments the collection counter
rule creatingCollectionIncrementsCounter(env e) {
    require !paused();
    uint256 collectionIdBefore = collectionId();
    string description;
    string name; string symbol; string uri; 
    LibShare.Share[] royalties;
    uint256 newId = createCollection(e, name, symbol, uri, description, royalties);
    
    uint256 collectionIdAfter = collectionId();
    assert collectionIdAfter == collectionIdBefore + 1, "Creating a collection should increment collection counter";
}

// Rule to check that only collection owner can set royalties
rule onlyOwnerCanSetRoyalties(env e, uint256 collectionId, LibShare.Share[] royalties) {
    address collectionOwner;
    _, _, _, _, collectionOwner, _ = collections(collectionId);
    require e.msg.sender != collectionOwner;
    
    setRoyaltiesForCollection@withrevert(e, collectionId, royalties);
    assert lastReverted, "Only collection owner should be able to set royalties";
}

// Rule to check that only owner can change collection method implementation
rule onlyOwnerCanChangeCollectionMethod(env e, address newMethod) {
    require e.msg.sender != owner();
    
    changeCollectionMethodImplementation@withrevert(e, newMethod);
    assert lastReverted, "Only owner should be able to change collection method implementation";
}

// Rule to check that setting royalties enforces the maximum royalty limit
rule royaltiesDoNotExceedMaximum(env e, uint256 collectionId, LibShare.Share[] royalties) {
    require !paused();
    
    setRoyaltiesForCollection@withrevert(e, collectionId, royalties);
    
    LibShare.Share[] newRoyalties = getCollectionRoyalties(collectionId);
    uint256 totalRoyalty = 0;
    for (uint i = 0; i < newRoyalties.length; i++) {
        totalRoyalty += newRoyalties[i].value;
    }
    
    assert totalRoyalty <= MAX_ROYALTY(), "Total royalties should not exceed maximum allowed";
}

// Invariant to check that collection owner is always set
invariant collectionOwnerAlwaysSet(uint256 id)
    id > 0 && id <= collectionId() => 
        collections(id)[4] != 0

// Invariant to check that collection contract address is always set
invariant collectionContractAddressAlwaysSet(uint256 id)
    id > 0 && id <= collectionId() => 
        collections(id)[3] != 0