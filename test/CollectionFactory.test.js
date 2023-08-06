const collectionFactory = artifacts.require("CollectionFactory");
const SampleERC20 = artifacts.require("mintToken");
const CollectionMethods = artifacts.require("CollectionMethods");
const piNFTMethods = artifacts.require("piNFTMethods");
const { expectRevert } = require("@openzeppelin/test-helpers");

contract("CollectionFactory", (accounts) => {
  let CollectionFactory, sampleERC20, collectionInstance, piNftMethods;
  let alice = accounts[0];
  let validator = accounts[1];
  let bob = accounts[2];
  let royaltyReciever = accounts[3];

  it("should deploy the contracts", async () => {
    CollectionFactory = await collectionFactory.deployed();
    sampleERC20 = await SampleERC20.deployed();
    piNftMethods = await piNFTMethods.deployed();
    assert(
      CollectionFactory !== undefined,
      "CollectionFactory contract was not deployed"
    );
    assert(sampleERC20 !== undefined, "SampleERC20 contract was not deployed");
  });

  it("should not create collection if the contract is paused", async () => {
    await CollectionFactory.pause();
    await expectRevert.unspecified(
      CollectionFactory.createCollection("PANDORA", "PAN", "xyz", "xyz", [
        [royaltyReciever, 500],
      ])
    );
    await CollectionFactory.unpause();
  });


  it("deploying collections with CollectionFactory contract", async () => {
    await CollectionFactory.createCollection("PANDORA", "PAN", "xyz", "xyz", [
      [royaltyReciever, 500],
    ]);
    let meta = await CollectionFactory.collections(1);
    let address = meta.contractAddress;
    collectionInstance = await CollectionMethods.at(address);
  });

  it("should fail to mint if the caller is not the collection owner", async () => {
    await expectRevert.unspecified(
      collectionInstance.mintNFT(bob, "xyz", { from: bob })
    );
  });

  it("should fail to mint if the to address is address 0", async () => {
    await expectRevert.unspecified(
      collectionInstance.mintNFT(
        "0x0000000000000000000000000000000000000000",
        "xyz"
      )
    );
  });

  it("should mint an ERC721 token to alice", async () => {
    const tx = await collectionInstance.mintNFT(alice, "URI1");
    const tokenId = tx.logs[0].args.tokenId.toNumber();
    assert(tokenId === 0, "Failed to mint or wrong token Id");
    assert.equal(
      await collectionInstance.balanceOf(alice),
      1,
      "Failed to mint"
    );
  });

  it("should mint an ERC721 token to alice", async () => {
    const tx = await collectionInstance.mintNFT(alice, "URI1");
    const tokenId = tx.logs[0].args.tokenId.toNumber();
    assert(tokenId === 1, "Failed to mint or wrong token Id");
    assert.equal(
      await collectionInstance.balanceOf(alice),
      2,
      "Failed to mint"
    );
  });

  it("should not Delete an ERC721 token if the caller isn't the owner", async () => {
    await expectRevert.unspecified(
      collectionInstance.deleteNFT(1, { from: bob })
    );
  });

  it("should Delete an ERC721 token", async () => {
    const tx = await collectionInstance.deleteNFT(1);
    assert.equal(
      await collectionInstance.balanceOf(alice),
      1,
      "Failed to mint"
    );
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
    await piNftMethods.addValidator(collectionInstance.address, 0, validator);
    assert.equal(
      await piNftMethods.approvedValidator(collectionInstance.address, 0),
      validator
    );
  });

  it("should let validator add ERC20 tokens to alice's NFT", async () => {
    await sampleERC20.approve(piNftMethods.address, 500, {
      from: validator,
    });
    const tx = await piNftMethods.addERC20(
      collectionInstance.address,
      0,
      sampleERC20.address,
      500,
      500,
      [[validator, 200]],
      {
        from: validator,
      }
    );
    const tokenBal = await piNftMethods.viewBalance(
      collectionInstance.address,
      0,
      sampleERC20.address
    );
    const validatorBal = await sampleERC20.balanceOf(validator);
    assert(tokenBal == 500, "Failed to add ERC20 tokens into NFT");
    assert(validatorBal == 500, "Validators balance not reduced");
    let commission = await piNftMethods.validatorCommissions(
      collectionInstance.address,
      0
    );
    assert(commission.isValid == true);
    assert(commission.commission.account == validator);
    assert(commission.commission.value == 500);
  });

  it("should not Delete an ERC721 token after validator funding", async () => {
    await expectRevert.unspecified(collectionInstance.deleteNFT(0));
  });

  it("should let validator add more ERC20 tokens to alice's NFT", async () => {
    await sampleERC20.approve(piNftMethods.address, 200, {
      from: validator,
    });
    const tx = await piNftMethods.addERC20(
      collectionInstance.address,
      0,
      sampleERC20.address,
      200,
      0,
      [[validator, 200]],
      {
        from: validator,
      }
    );
    const tokenBal = await piNftMethods.viewBalance(
      collectionInstance.address,
      0,
      sampleERC20.address
    );
    const validatorBal = await sampleERC20.balanceOf(validator);
    assert(tokenBal == 700, "Failed to add ERC20 tokens into NFT");
    assert(validatorBal == 300, "Validators balance not reduced");
    let commission = await piNftMethods.validatorCommissions(
      collectionInstance.address,
      0
    );
    assert(commission.isValid == true);
    assert(commission.commission.account == validator);
    assert(commission.commission.value == 500);
  });

  it("should not let validator add funds of a different erc20", async () => {
    await expectRevert(
      piNftMethods.addERC20(
        collectionInstance.address,
        0,
        accounts[5],
        200,
        500,
        [[validator, 200]],
        {
          from: validator,
        }
      ),
      "invalid"
    );
  });

  it("should let alice transfer NFT to bob", async () => {
    await collectionInstance.safeTransferFrom(alice, bob, 0, { from: alice });
    assert.equal(
      await collectionInstance.ownerOf(0),
      bob,
      "Failed to transfer NFT"
    );
  });

  it("should let bob transfer NFT to alice", async () => {
    await collectionInstance.safeTransferFrom(bob, alice, 0, { from: bob });
    assert.equal(
      await collectionInstance.ownerOf(0),
      alice,
      "Failed to transfer NFT"
    );
  });

  it("should let alice withdraw erc20", async () => {
    let _bal = await sampleERC20.balanceOf(alice);
    await collectionInstance.approve(piNftMethods.address, 0, { from: alice });
    await piNftMethods.withdraw(
      collectionInstance.address,
      0,
      sampleERC20.address,
      300
    );
    assert.equal(await collectionInstance.ownerOf(0), piNftMethods.address);
    let bal = await sampleERC20.balanceOf(alice);
    assert.equal(bal - _bal, 300);
    await piNftMethods.withdraw(
      collectionInstance.address,
      0,
      sampleERC20.address,
      200
    );
    assert.equal(await collectionInstance.ownerOf(0), piNftMethods.address);
    bal = await sampleERC20.balanceOf(alice);
    assert.equal(bal - _bal, 500);
    assert.equal(await sampleERC20.balanceOf(piNftMethods.address), 200);
  });

  it("should let alice repay erc20", async () => {
    let _bal = await sampleERC20.balanceOf(alice);
    await sampleERC20.approve(piNftMethods.address, 300);
    await piNftMethods.Repay(
      collectionInstance.address,
      0,
      sampleERC20.address,
      300
    );
    assert.equal(await collectionInstance.ownerOf(0), piNftMethods.address);
    let bal = await sampleERC20.balanceOf(alice);
    assert.equal(_bal - bal, 300);
    await sampleERC20.approve(piNftMethods.address, 200);
    await piNftMethods.Repay(
      collectionInstance.address,
      0,
      sampleERC20.address,
      200
    );
    assert.equal(await collectionInstance.ownerOf(0), alice);
    bal = await sampleERC20.balanceOf(alice);
    assert.equal(_bal - bal, 500);
  });

  it("should redeem CollectionFactory", async () => {
    await piNftMethods.redeemOrBurnPiNFT(
      collectionInstance.address,
      0,
      alice,
      "0x0000000000000000000000000000000000000000",
      sampleERC20.address,
      false
    );
    const balance = await sampleERC20.balanceOf(validator);
    assert.equal(balance, 1000);
    assert.equal(await collectionInstance.ownerOf(0), alice);
    let commission = await piNftMethods.validatorCommissions(
      collectionInstance.address,
      0
    );
    assert(commission.isValid == false);
    assert(
      commission.commission.account ==
        "0x0000000000000000000000000000000000000000"
    );
    assert(commission.commission.value == 0);
  });

  it("should transfer NFT to bob", async () => {
    await collectionInstance.safeTransferFrom(alice, bob, 0);
    assert.equal(
      await collectionInstance.ownerOf(0),
      bob,
      "Failed to transfer NFT"
    );
  });

  it("should let validator add ERC20 tokens to bob's NFT", async () => {
    await sampleERC20.approve(piNftMethods.address, 500, {
      from: validator,
    });
    await piNftMethods.addValidator(collectionInstance.address, 0, validator, {
      from: bob,
    });
    const tx = await piNftMethods.addERC20(
      collectionInstance.address,
      0,
      sampleERC20.address,
      500,
      600,
      [[validator, 200]],
      {
        from: validator,
      }
    );
    const tokenBal = await piNftMethods.viewBalance(
      collectionInstance.address,
      0,
      sampleERC20.address
    );
    const validatorBal = await sampleERC20.balanceOf(validator);
    assert(tokenBal == 500, "Failed to add ERC20 tokens into NFT");
    assert(validatorBal == 500, "Validators balance not reduced");
    let commission = await piNftMethods.validatorCommissions(
      collectionInstance.address,
      0
    );
    assert(commission.isValid == true);
    assert(commission.commission.account == validator);
    assert(commission.commission.value == 600);
  });

  it("should let bob burn CollectionFactory", async () => {
    assert.equal(await sampleERC20.balanceOf(bob), 0);
    await collectionInstance.approve(piNftMethods.address, 0, { from: bob });
    await piNftMethods.redeemOrBurnPiNFT(
      collectionInstance.address,
      0,
      "0x0000000000000000000000000000000000000000",
      bob,
      sampleERC20.address,
      true,
      {
        from: bob,
      }
    );
    const bobBal = await sampleERC20.balanceOf(bob);
    assert.equal(
      await piNftMethods.viewBalance(
        collectionInstance.address,
        0,
        sampleERC20.address
      ),
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
    let commission = await piNftMethods.validatorCommissions(
      collectionInstance.address,
      0
    );
    assert(commission.isValid == false);
    assert(
      commission.commission.account ==
        "0x0000000000000000000000000000000000000000"
    );
    assert(commission.commission.value == 0);
  });

  it("should prevent an external address to call piNFTMethods callable functions", async () => {
    await expectRevert(
      collectionInstance.setRoyaltiesForValidator(1, 3000, []),
      "methods"
    );
    await expectRevert(
      collectionInstance.deleteValidatorRoyalties(1),
      "methods"
    );
  });
});
