using CollectionFactory as collectionFactory;
using piNFTMethods as piNFTMethods;

methods {
    function collectionOwner() external returns (address) envfree;
    function collectionFactoryAddress() external returns (address) envfree;
    function initialize(address, address, string, string) external;
    function mintNFT(address, string) external returns (uint256);
    function setRoyaltiesForValidator(uint256, uint256, LibShare.Share[]) external;
    function deleteValidatorRoyalties(uint256) external;
    function deleteNFT(uint256) external;
    function exists(uint256) external returns (bool) envfree;
    function getValidatorRoyalties(uint256) external returns (LibShare.Share[]) envfree;
    function ownerOf(uint256) external returns (address) envfree;
    function collectionFactory.piNFTMethodsAddress() external returns (address) envfree;
    function piNFTMethods.NFTowner(address, uint256) external returns (address) envfree;
}

definition MAX_ROYALTIES() returns uint256 = 4900;

// Rule to check that only the collection owner can mint NFTs
rule onlyOwnerCanMintNFT(address to, string uri) {
    env e;
    require e.msg.sender != collectionOwner();
    mintNFT@withrevert(e, to, uri);
    assert lastReverted, "Only collection owner should be able to mint NFTs";
}

// Rule to check that minting an NFT increases the token counter
rule mintingIncreasesTokenCounter(address to, string uri) {
    env e;
    require e.msg.sender == collectionOwner();
    uint256 tokenIdBefore = mintNFT(e, to, uri);
    uint256 tokenIdAfter = mintNFT(e, to, uri);
    assert tokenIdAfter == tokenIdBefore + 1, "Minting should increase token counter";
}

// Rule to check that only piNFTMethods can set validator royalties
rule onlyMethodsCanSetValidatorRoyalties(uint256 tokenId, uint256 commission, LibShare.Share[] royalties) {
    env e;
    address piNFTMethodsAddress = collectionFactory.piNFTMethodsAddress(e, collectionFactoryAddress());
    require e.msg.sender != piNFTMethodsAddress;
    setRoyaltiesForValidator@withrevert(e, tokenId, commission, royalties);
    assert lastReverted, "Only piNFTMethods should be able to set validator royalties";
}

// Rule to check that only the token owner can delete an NFT
rule onlyOwnerCanDeleteNFT(uint256 tokenId) {
    env e;
    require exists(tokenId);
    require e.msg.sender != ownerOf(tokenId);
    deleteNFT@withrevert(e, tokenId);
    assert lastReverted, "Only token owner should be able to delete NFT";
}

// Invariant to check that validator royalties are always set for existing tokens
invariant validatorRoyaltiesAlwaysSet(uint256 tokenId)
    exists(tokenId) => getValidatorRoyalties(tokenId).length > 0;

// Invariant to check that deleted NFTs don't exist
invariant deletedNFTsDontExist(uint256 tokenId)
    !exists(tokenId) => ownerOf(tokenId) == 0;