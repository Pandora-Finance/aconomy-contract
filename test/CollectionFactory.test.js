const collectionFactory = artifacts.require("CollectionFactory");
const SampleERC20 = artifacts.require("mintToken");
const CollectionMethods = artifacts.require("CollectionMethods");

contract("CollectionFactory", (accounts) => {
  let CollectionFactory, sampleERC20, collectionInstance;
  let alice = accounts[0];
  let validator = accounts[1];
  let bob = accounts[2];
  let royaltyReciever = accounts[3];

  it("should deploy the contracts", async () => {
    CollectionFactory = await collectionFactory.deployed();
    sampleERC20 = await SampleERC20.deployed();
    assert(CollectionFactory !== undefined, "CollectionFactory contract was not deployed");
    assert(sampleERC20 !== undefined, "SampleERC20 contract was not deployed");
  });

  it("deploying collections with CollectionFactory contract", async () => {
    await CollectionFactory.createCollection("PANDORA", "PAN", "xyz", "xyz", [[royaltyReciever, 500]])
     let meta = await CollectionFactory.collections(1);
     let address = meta.contractAddress
     collectionInstance = await CollectionMethods.at(address)
  });

  it("should mint an ERC721 token to alice", async () => {
    const tx = await collectionInstance.mintNFT(alice, "URI1");
    const tokenId = tx.logs[0].args.tokenId.toNumber();
    assert(tokenId === 0, "Failed to mint or wrong token Id");
    assert.equal(await collectionInstance.balanceOf(alice), 1, "Failed to mint");
  });

  it("should mint an ERC721 token to alice", async () => {
    const tx = await collectionInstance.mintNFT(alice, "URI1");
    const tokenId = tx.logs[0].args.tokenId.toNumber();
    assert(tokenId === 1, "Failed to mint or wrong token Id");
    assert.equal(await collectionInstance.balanceOf(alice), 2, "Failed to mint");
  });

  it("should Delete an ERC721 token to alice", async () => {
    const tx = await collectionInstance.deleteNFT(1);
    assert.equal(await collectionInstance.balanceOf(alice), 1, "Failed to mint");
  });

  it("should fetch the tokenURI and royalties", async () => {
    const uri = await collectionInstance.tokenURI(0);
    assert.equal(uri, "URI1", "Invalid URI for the token");
    const royalties = await CollectionFactory.getCollectionRoyalties(1);
    assert.equal(royalties[0][0], royaltyReciever);
    assert.equal(royalties[0][1], 500);
  });

  it("should mint ERC20 tokens to validator", async () => {
    const tx = await sampleERC20.mint(validator, 1000);
    const balance = await sampleERC20.balanceOf(validator);
    assert(balance == 1000, "Failed to mint ERC20 tokens");
  });

  it("should allow alice to add a validator to the nft", async () => {
    await collectionInstance.addValidator(0, validator);
    assert.equal(await collectionInstance.approvedValidator(0), validator);
  })

  it("should let validator add ERC20 tokens to alice's NFT", async () => {
    await sampleERC20.approve(collectionInstance.address, 500, { from: validator });
    const tx = await collectionInstance.addERC20(0, sampleERC20.address, 500, [[validator, 200]], {
      from: validator,
    });
    const tokenBal = await collectionInstance.viewBalance(0, sampleERC20.address);
    const validatorBal = await sampleERC20.balanceOf(validator);
    assert(tokenBal == 500, "Failed to add ERC20 tokens into NFT");
    assert(validatorBal == 500, "Validators balance not reduced");
  });

  it("should let alice transfer NFT to bob", async () => {
    await collectionInstance.transferAfterFunding(0, bob, { from: alice });
    assert.equal(await collectionInstance.ownerOf(0), bob, "Failed to transfer NFT");
  });

  it("should let bob transfer NFT to alice", async () => {
    await collectionInstance.transferAfterFunding(0, alice, { from: bob });
    assert.equal(await collectionInstance.ownerOf(0), alice, "Failed to transfer NFT");
  });

  it("should let alice withdraw erc20", async () => {
    let _bal = await sampleERC20.balanceOf(alice);
    await collectionInstance.withdraw(0, sampleERC20.address, 300);
    assert.equal(await collectionInstance.ownerOf(0), collectionInstance.address);
    let bal = await sampleERC20.balanceOf(alice);
    assert.equal(bal - _bal, 300);
    await collectionInstance.withdraw(0, sampleERC20.address, 200);
    assert.equal(await collectionInstance.ownerOf(0), collectionInstance.address);
    bal = await sampleERC20.balanceOf(alice);
    assert.equal(bal - _bal, 500);
  })

  it("should let alice repay erc20", async () => {
    let _bal = await sampleERC20.balanceOf(alice);
    await sampleERC20.approve(collectionInstance.address, 300);
    await collectionInstance.Repay(0, sampleERC20.address, 300);
    assert.equal(await collectionInstance.ownerOf(0), collectionInstance.address);
    let bal = await sampleERC20.balanceOf(alice);
    assert.equal(_bal - bal, 300);
    await sampleERC20.approve(collectionInstance.address, 200);
    await collectionInstance.Repay(0, sampleERC20.address, 200);
    assert.equal(await collectionInstance.ownerOf(0), alice);
    bal = await sampleERC20.balanceOf(alice);
    assert.equal(_bal - bal, 500);
  })


  it("should redeem CollectionFactory", async () => {
    await collectionInstance.redeemOrBurnPiNFT(0, alice, '0x0000000000000000000000000000000000000000', sampleERC20.address, false);
    const balance = await sampleERC20.balanceOf(validator);
    assert.equal(balance, 1000);
    assert.equal(await collectionInstance.ownerOf(0), alice);
  });


  it("should transfer NFT to bob", async () => {
    await collectionInstance.safeTransferFrom(alice, bob, 0);
    assert.equal(await collectionInstance.ownerOf(0), bob, "Failed to transfer NFT");
  });


  it("should let validator add ERC20 tokens to bob's NFT", async () => {
    await sampleERC20.approve(collectionInstance.address, 500, { from: validator });
    await collectionInstance.addValidator(0, validator, { from: bob });
    const tx = await collectionInstance.addERC20(0, sampleERC20.address, 500, [[validator, 200]], {
      from: validator,
    });
    const tokenBal = await collectionInstance.viewBalance(0, sampleERC20.address);
    const validatorBal = await sampleERC20.balanceOf(validator);
    assert(tokenBal == 500, "Failed to add ERC20 tokens into NFT");
    assert(validatorBal == 500, "Validators balance not reduced");
  });

  it("should let bob burn CollectionFactory", async () => {
    assert.equal(
      await sampleERC20.balanceOf(bob),
      0,
    );
    await collectionInstance.redeemOrBurnPiNFT(0, '0x0000000000000000000000000000000000000000', bob, sampleERC20.address, true, {
      from: bob,
    });
    const bobBal = await sampleERC20.balanceOf(bob);
    assert.equal(
      await collectionInstance.viewBalance(0, sampleERC20.address),
      0,
      "Failed to remove ERC20 tokens from NFT"
    );
    assert.equal(
      await sampleERC20.balanceOf(bob),
      500,
      "Failed to transfer ERC20 tokens to bob"
    );
    assert.equal(
      await collectionInstance.ownerOf(0),
      validator,
      "Failed to transfer NFT to alice"
    );
  });
});