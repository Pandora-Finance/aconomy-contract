const PiNFT = artifacts.require("piNFT");
const SampleERC20 = artifacts.require("mintToken");
const piNFTMethods = artifacts.require("piNFTMethods");
const { expectRevert } = require("@openzeppelin/test-helpers");

contract("PiNFT", (accounts) => {
  let piNFT, sampleERC20, piNftMethods;
  let alice = accounts[0];
  let validator = accounts[1];
  let bob = accounts[2];
  let royaltyReciever = accounts[3];

  it("should deploy the contracts", async () => {
    piNFT = await PiNFT.deployed();
    sampleERC20 = await SampleERC20.deployed();
    piNftMethods = await piNFTMethods.deployed();
    assert(piNFT !== undefined, "PiNFT contract was not deployed");
    assert(sampleERC20 !== undefined, "SampleERC20 contract was not deployed");
  });

  it("should read the name and symbol of piNFT contract", async () => {
    assert.equal(await piNFT.name(), "Aconomy");
    assert.equal(await piNFT.symbol(), "ACO");
  });

  it("should mint an ERC721 token to alice", async () => {
    const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);
    // console.log(tx);
    await expectRevert(
      piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 4001]]),
      "overflow"
    );
    const tokenId = tx.logs[0].args.tokenId.toNumber();
    assert(tokenId === 0, "Failed to mint or wrong token Id");
    assert.equal(await piNFT.balanceOf(alice), 1, "Failed to mint");
  });

  it("should not mint if the contract is paused", async () => {
    await piNFT.pause();
    await expectRevert.unspecified(
      piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]])
    );
    await piNFT.unpause();
  });

  it("should Royality must be less 4000", async () => {
    await expectRevert(
      piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 4001]]),
      "overflow"
    );
  });

  it("should mint an ERC721 token to alice", async () => {
    const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);
    const tokenId = tx.logs[0].args.tokenId.toNumber();
    assert(tokenId === 1, "Failed to mint or wrong token Id");
    assert.equal(await piNFT.balanceOf(alice), 2, "Failed to mint");
  });

  it("should Delete an ERC721 token to alice", async () => {
    const tx = await piNFT.deleteNFT(1);
    assert.equal(await piNFT.balanceOf(alice), 1, "Failed to mint");
  });

  it("should fetch the tokenURI and royalties", async () => {
    const uri = await piNFT.tokenURI(0);
    assert.equal(uri, "URI1", "Invalid URI for the token");
    const royalties = await piNFT.getRoyalties(0);
    assert.equal(royalties[0][0], royaltyReciever);
    assert.equal(royalties[0][1], 500);
  });

  it("should mint ERC20 tokens to validator", async () => {
    const tx = await sampleERC20.mint(validator, 1000);
    const balance = await sampleERC20.balanceOf(validator);
    assert(balance == 1000, "Failed to mint ERC20 tokens");
  });

  it("should allow alice to add a validator to the nft", async () => {
    await piNftMethods.addValidator(piNFT.address, 0, validator);
    assert.equal(
      await piNftMethods.approvedValidator(piNFT.address, 0),
      validator
    );
  });

  it("should let validator add ERC20 tokens to alice's NFT", async () => {
    await sampleERC20.approve(piNftMethods.address, 500, { from: validator });
    const tx = await piNftMethods.addERC20(
      piNFT.address,
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
      piNFT.address,
      0,
      sampleERC20.address
    );
    const validatorBal = await sampleERC20.balanceOf(validator);
    assert(tokenBal == 500, "Failed to add ERC20 tokens into NFT");
    assert(validatorBal == 500, "Validators balance not reduced");
    let commission = await piNftMethods.validatorCommissions(piNFT.address, 0);
    assert(commission.isValid == true);
    assert(commission.commission.account == validator);
    assert(commission.commission.value == 500);
  });

  it("should let the validator add more erc20 tokens of the same contract", async () => {
    await sampleERC20.approve(piNftMethods.address, 200, { from: validator });
    const tx = await piNftMethods.addERC20(
      piNFT.address,
      0,
      sampleERC20.address,
      200,
      500,
      [[validator, 200]],
      {
        from: validator,
      }
    );
    const tokenBal = await piNftMethods.viewBalance(
      piNFT.address,
      0,
      sampleERC20.address
    );
    const validatorBal = await sampleERC20.balanceOf(validator);
    assert(tokenBal == 700, "Failed to add ERC20 tokens into NFT");
    assert(validatorBal == 300, "Validators balance not reduced");
    let commission = await piNftMethods.validatorCommissions(piNFT.address, 0);
    assert(commission.isValid == true);
    assert(commission.commission.account == validator);
    assert(commission.commission.value == 500);
  });

  it("should not let validator add funds of a different erc20", async () => {
    await expectRevert(
      piNftMethods.addERC20(
        piNFT.address,
        0,
        accounts[5],
        200,
        400,
        [[validator, 200]],
        {
          from: validator,
        }
      ),
      "invalid"
    );
  });

  it("should let alice transfer NFT to bob", async () => {
    await piNFT.safeTransferFrom(alice, bob, 0, {
      from: alice,
    });
    assert.equal(await piNFT.ownerOf(0), bob, "Failed to transfer NFT");
  });

  it("should let bob transfer NFT to alice", async () => {
    await piNFT.safeTransferFrom(bob, alice, 0, {
      from: bob,
    });
    assert.equal(await piNFT.ownerOf(0), alice, "Failed to transfer NFT");
  });

  it("should let alice withdraw erc20", async () => {
    let _bal = await sampleERC20.balanceOf(alice);
    await piNFT.approve(piNftMethods.address, 0);
    await piNftMethods.withdraw(piNFT.address, 0, sampleERC20.address, 300);
    assert.equal(await piNFT.ownerOf(0), piNftMethods.address);
    let bal = await sampleERC20.balanceOf(alice);
    assert.equal(bal - _bal, 300);
    await piNftMethods.withdraw(piNFT.address, 0, sampleERC20.address, 200);
    assert.equal(await piNFT.ownerOf(0), piNftMethods.address);
    bal = await sampleERC20.balanceOf(alice);
    assert.equal(bal - _bal, 500);
    assert.equal(await sampleERC20.balanceOf(piNftMethods.address), 200);
  });

  it("should let alice repay erc20", async () => {
    let _bal = await sampleERC20.balanceOf(alice);
    await sampleERC20.approve(piNftMethods.address, 300);
    await piNftMethods.Repay(piNFT.address, 0, sampleERC20.address, 300);
    assert.equal(await piNFT.ownerOf(0), piNftMethods.address);
    let bal = await sampleERC20.balanceOf(alice);
    assert.equal(_bal - bal, 300);
    await sampleERC20.approve(piNftMethods.address, 200);
    await piNftMethods.Repay(piNFT.address, 0, sampleERC20.address, 200);
    assert.equal(await piNFT.ownerOf(0), alice);
    bal = await sampleERC20.balanceOf(alice);
    assert.equal(_bal - bal, 500);
  });

  it("should redeem piNft", async () => {
    await piNFT.approve(piNftMethods.address, 0);
    await piNftMethods.redeemOrBurnPiNFT(
      piNFT.address,
      0,
      alice,
      "0x0000000000000000000000000000000000000000",
      sampleERC20.address,
      false
    );
    const balance = await sampleERC20.balanceOf(validator);
    assert.equal(balance, 1000);
    assert.equal(await piNFT.ownerOf(0), alice);
    let commission = await piNftMethods.validatorCommissions(piNFT.address, 0);
    assert(commission.isValid == false);
    assert(commission.commission.account == "0x0000000000000000000000000000000000000000");
    assert(commission.commission.value == 0);
  });

  it("should transfer NFT to bob", async () => {
    await piNFT.safeTransferFrom(alice, bob, 0);
    assert.equal(await piNFT.ownerOf(0), bob, "Failed to transfer NFT");
  });

  it("should let validator add ERC20 tokens to bob's NFT", async () => {
    await sampleERC20.approve(piNftMethods.address, 500, { from: validator });
    await piNftMethods.addValidator(piNFT.address, 0, validator, { from: bob });
    await expectRevert(
      piNftMethods.addERC20(
        piNFT.address,
        0,
        sampleERC20.address,
        500,
        400,
        [
          [validator, 2000],
          [bob, 2001],
        ],
        {
          from: validator,
        }
      ),
      "overflow"
    );
    const tx = await piNftMethods.addERC20(
      piNFT.address,
      0,
      sampleERC20.address,
      500,
      400,
      [[validator, 200]],
      {
        from: validator,
      }
    );
    const tokenBal = await piNftMethods.viewBalance(
      piNFT.address,
      0,
      sampleERC20.address
    );
    const validatorBal = await sampleERC20.balanceOf(validator);
    assert(tokenBal == 500, "Failed to add ERC20 tokens into NFT");
    assert(validatorBal == 500, "Validators balance not reduced");
    let commission = await piNftMethods.validatorCommissions(piNFT.address, 0);
    assert(commission.isValid == true);
    assert(commission.commission.account == validator);
    assert(commission.commission.value == 400);
  });

  it("should let bob burn piNFT", async () => {
    assert.equal(await sampleERC20.balanceOf(bob), 0);
    await piNFT.approve(piNftMethods.address, 0, { from: bob });
    await piNftMethods.redeemOrBurnPiNFT(
      piNFT.address,
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
      await piNftMethods.viewBalance(piNFT.address, 0, sampleERC20.address),
      0,
      "Failed to remove ERC20 tokens from NFT"
    );
    assert.equal(
      await sampleERC20.balanceOf(bob),
      500,
      "Failed to transfer ERC20 tokens to bob"
    );
    assert.equal(
      await piNFT.ownerOf(0),
      validator,
      "Failed to transfer NFT to alice"
    );
    let commission = await piNftMethods.validatorCommissions(piNFT.address, 0);
    assert(commission.isValid == false);
    assert(commission.commission.account == "0x0000000000000000000000000000000000000000");
    assert(commission.commission.value == 0);
  });
});
