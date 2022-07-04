const BigNumber = require("big-number");
const PiNFT = artifacts.require("piNFT");
const SampleERC20 = artifacts.require("sampleERC20");
const PiMarket = artifacts.require("piMarket");

contract("PiMarket", async (accounts) => {
  let piNFT, sampleERC20, piMarket;
  let alice = accounts[0];
  let validator = accounts[1];
  let bob = accounts[2];
  let royaltyReceiver = accounts[3];
  let feeReceiver = accounts[4];

  it("should create a piNFT with 500 erc20 tokens to alice", async () => {
    piNFT = await PiNFT.deployed();
    sampleERC20 = await SampleERC20.deployed();
    await sampleERC20.mint(validator, 1000);
    const tx1 = await piNFT.mintNFT(alice, "URI1", [[royaltyReceiver, 500]]);
    const tokenId = tx1.logs[0].args.tokenId.toNumber();
    assert(tokenId === 0, "Failed to mint or wrong token Id");

    await sampleERC20.approve(piNFT.address, 500, { from: validator });
    const tx = await piNFT.addERC20(
      validator,
      tokenId,
      sampleERC20.address,
      500,
      {
        from: validator,
      }
    );

    const tokenBal = await piNFT.viewBalance(tokenId, sampleERC20.address);
    assert(tokenBal == 500, "Failed to add ERC20 tokens into NFT");
  });

  it("should deploy the marketplace contract", async () => {
    piMarket = await PiMarket.deployed();
    assert(piMarket !== undefined, "PiMarket contract was not deployed");
  });

  it("should let alice place piNFT on sale", async () => {
    await piNFT.approve(piMarket.address, 0);
    const result = await piMarket.sellNFT(piNFT.address, 0, 5000);
    assert.equal(
      await piNFT.ownerOf(0),
      piMarket.address,
      "Failed to put piNFT on Sale"
    );
  });

  it("should let bob buy piNFT", async () => {
    let meta = await piMarket._tokenMeta(1);
    assert.equal(meta.status, true);

    let _balance1 = await web3.eth.getBalance(alice);
    let _balance2 = await web3.eth.getBalance(royaltyReceiver);
    let _balance3 = await web3.eth.getBalance(feeReceiver);

    result2 = await piMarket.BuyNFT(1, { from: bob, value: 5000 });
    assert.equal(await piNFT.ownerOf(0), bob);

    let balance1 = await web3.eth.getBalance(alice);
    let balance2 = await web3.eth.getBalance(royaltyReceiver);
    let balance3 = await web3.eth.getBalance(feeReceiver);

    assert.equal(
      BigNumber(balance1).minus(BigNumber(_balance1)),
      (5000 * 9400) / 10000,
      "Failed to transfer NFT amount"
    );
    // console.log(BigNumber(balance1).minus(BigNumber(_balance1)));
    // console.log(BigNumber(balance2).minus(BigNumber(_balance2)));
    // console.log(BigNumber(balance3).minus(BigNumber(_balance3)));
    assert.equal(
      BigNumber(balance2).minus(BigNumber(_balance2)),
      (5000 * 500) / 10000,
      "Failed to transfer royalty amount"
    );
    assert.equal(
      BigNumber(balance3).minus(BigNumber(_balance3)),
      (5000 * 100) / 10000,
      "Failed to transfer fee amount"
    );

    meta = await piMarket._tokenMeta(1);
    assert.equal(meta.status, false);
  });

  it("should let bob place piNFT on sale again", async () => {
    await piNFT.approve(piMarket.address, 0, { from: bob });
    const result = await piMarket.sellNFT(piNFT.address, 0, 10000, {
      from: bob,
    });
    assert.equal(
      await piNFT.ownerOf(0),
      piMarket.address,
      "Failed to put piNFT on Sale"
    );
  });

  it("should let bob cancel sale", async () => {
    await piMarket.cancelSale(2, { from: bob });
    meta = await piMarket._tokenMeta(2);
    assert.equal(meta.status, false);
  });

  it("should let bob disintegrate NFT and ERC20 tokens", async () => {
    await piNFT.transferERC20(0, validator, sampleERC20.address, 500, {
      from: bob,
    });
    const validatorBal = await sampleERC20.balanceOf(validator);
    assert.equal(
      await piNFT.viewBalance(0, sampleERC20.address),
      0,
      "Failed to remove ERC20 tokens from NFT"
    );
    assert.equal(
      await sampleERC20.balanceOf(validator),
      1000,
      "Failed to transfer ERC20 tokens to validator"
    );
  });
});
