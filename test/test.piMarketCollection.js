const BigNumber = require("big-number");
const CollectionFactory = artifacts.require("CollectionFactory");
const CollectionMethods = artifacts.require("CollectionMethods");
const SampleERC20 = artifacts.require("mintToken");
const PiMarket = artifacts.require("piMarket");
const AconomyFee = artifacts.require("AconomyFee");
const piNFTMethods = artifacts.require("piNFTMethods");
const {
  BN,
  constants,
  expectEvent,
  shouldFail,
  time,
  expectRevert,
} = require("@openzeppelin/test-helpers");
// require("dotenv").config();

contract("PiMarket", async (accounts) => {
  let factory, collectionContract, sampleERC20, piMarket, piNftMethods;
  let alice = accounts[0];
  let validator = accounts[1];
  let bob = accounts[2];
  let carl = accounts[3];
  let royaltyReceiver = accounts[3];
  let feeReceiver = "0xFF708C09221d5BA90eA3e3A3C42E2aBc8cA8aAc9";
  let bidder1 = accounts[5];
  let bidder2 = accounts[6];

  describe("Direct Sale", () => {
    it("should create a private piNFT with 500 erc20 tokens to carl", async () => {
      factory = await CollectionFactory.deployed();
      sampleERC20 = await SampleERC20.deployed();
      aconomyFee = await AconomyFee.deployed();
      piNftMethods = await piNFTMethods.deployed();
      await aconomyFee.setAconomyPiMarketFee(100);
      await aconomyFee.transferOwnership(feeReceiver);
      await sampleERC20.mint(validator, 1000);
      await factory.createCollection("PANDORA", "PAN", "xyz", "xyz", [
        [royaltyReceiver, 500],
      ]);
      let meta = await factory.collections(1);
      let address = meta.contractAddress;
      collectionContract = await CollectionMethods.at(address);
      const tx1 = await collectionContract.mintNFT(carl, "URI1");
      const tokenId = tx1.logs[0].args.tokenId.toNumber();
      assert(tokenId === 0, "Failed to mint or wrong token Id");

      await piNftMethods.addValidator(
        collectionContract.address,
        tokenId,
        validator,
        { from: carl }
      );
      await sampleERC20.approve(piNftMethods.address, 500, {
        from: validator,
      });
      const tx = await piNftMethods.addERC20(
        collectionContract.address,
        tokenId,
        sampleERC20.address,
        500,
        1000,
        [[validator, 200]],
        {
          from: validator,
        }
      );

      const tokenBal = await piNftMethods.viewBalance(
        collectionContract.address,
        tokenId,
        sampleERC20.address
      );
      assert(tokenBal == 500, "Failed to add ERC20 tokens into NFT");
      let commission = await piNftMethods.validatorCommissions(collectionContract.address, 0);
      assert(commission.isValid == true);
      assert(commission.commission.account == validator);
      assert(commission.commission.value == 1000);
    });

    it("should deploy the marketplace contract", async () => {
      piMarket = await PiMarket.deployed();
      assert(piMarket !== undefined, "PiMarket contract was not deployed");
    });

    it("should let carl transfer piNFT to alice", async () => {
      await collectionContract.safeTransferFrom(carl, alice, 0, { from: carl });
      assert.equal(
        await collectionContract.ownerOf(0),
        alice,
        "Failed to transfer piNFT"
      );
    });

    it("should not place nft on sale if price < 10000", async () => {
      await collectionContract.approve(piMarket.address, 0);
      await expectRevert.unspecified(piMarket.sellNFT(
        collectionContract.address,
        0,
        100,
        "0x0000000000000000000000000000000000000000"
      ))
    })

    it("should not place nft on sale if contract address is 0", async () => {
      await collectionContract.approve(piMarket.address, 0);
      await expectRevert.unspecified(piMarket.sellNFT(
        "0x0000000000000000000000000000000000000000",
        0,
        50000,
        "0x0000000000000000000000000000000000000000"
      ))
    })

    it("should let alice place piNFT on sale", async () => {
      await collectionContract.approve(piMarket.address, 0);
      const result = await piMarket.sellNFT(
        collectionContract.address,
        0,
        50000,
        "0x0000000000000000000000000000000000000000"
      );
      assert.equal(
        await collectionContract.ownerOf(0),
        piMarket.address,
        "Failed to put piNFT on Sale"
      );
    });

    it("should edit the price after listing on sale", async () => {
      const tx = await piMarket.editSalePrice(1, 60000, { from: alice });
      await expectRevert(
        piMarket.editSalePrice(1, 60000, { from: bob }),
        "You are not the owner"
      );
      await expectRevert.unspecified(
        piMarket.editSalePrice(1, 60, { from: alice })
      );
      let price = tx.logs[0].args.Price.toNumber();
      // console.log("newPrice", price);
      assert.equal(price, 60000, "Price not updated");
      const tx1 = await piMarket.editSalePrice(1, 50000, { from: alice });
      let newPrice = tx1.logs[0].args.Price.toNumber();
      assert.equal(newPrice, 50000, "Price is still 6000");
    });

    it("should not let seller buy their own nft", async () => {
      expectRevert.unspecified(piMarket.BuyNFT(1, true, { from: alice, value: 50000 }))
    })

    it("should let bob buy piNFT", async () => {
      let meta = await piMarket._tokenMeta(1);
      assert.equal(meta.status, true);

      let _balance1 = await web3.eth.getBalance(alice);
      let _balance2 = await web3.eth.getBalance(royaltyReceiver);
      let _balance3 = await web3.eth.getBalance(feeReceiver);
      let _balance4 = await web3.eth.getBalance(validator);

      result2 = await piMarket.BuyNFT(1, true, { from: bob, value: 50000 });
      // console.log(result2.receipt.rawLogs)
      assert.equal(await collectionContract.ownerOf(0), bob);

      //validator 200
      //royalties 500
      //fee 50

      let balance1 = await web3.eth.getBalance(alice);
      let balance2 = await web3.eth.getBalance(royaltyReceiver);
      let balance3 = await web3.eth.getBalance(feeReceiver);
      let balance4 = await web3.eth.getBalance(validator);
      let temp = BigNumber(balance1).minus(BigNumber(_balance1));
      // console.log(balance1, " ", _balance1, " ", temp.toString());
      assert.equal(
        BigNumber(balance1).minus(BigNumber(_balance1)),
        (50000 * 8200) / 10000,
        "Failed to transfer NFT amount"
      );

      assert.equal(
        BigNumber(balance2).minus(BigNumber(_balance2)),
        (50000 * 500) / 10000,
        "Failed to transfer royalty amount"
      );

      // console.log(Number(web3.utils.toBN(balance2)-(web3.utils.toBN(_balance2))))

      // console.log(Number(BigNumber(balance3).minus(BigNumber(_balance3))));
      assert.equal(
        BigNumber(balance3).minus(BigNumber(_balance3)),
        (50000 * 100) / 10000,
        "Failed to transfer fee amount"
      );

      assert.equal(
        BigNumber(balance4).minus(BigNumber(_balance4)),
        (50000 * 1200) / 10000,
        "Failed to transfer validator amount"
      );

      meta = await piMarket._tokenMeta(1);
      assert.equal(meta.status, false);
      let commission = await piNftMethods.validatorCommissions(collectionContract.address, 0);
      assert(commission.isValid == false);
      assert(commission.commission.account == validator);
      assert(commission.commission.value == 1000);
    });

    it("should let bob withdraw funds from the NFT", async () => {
      await collectionContract.approve(piNftMethods.address, 0, { from: bob });
      await piNftMethods.withdraw(
        collectionContract.address,
        0,
        sampleERC20.address,
        200,
        {
          from: bob,
        }
      );
      assert.equal(await sampleERC20.balanceOf(bob), 200);
      assert.equal(await collectionContract.ownerOf(0), piNftMethods.address);
    });

    it("should let bob withdraw more funds from the NFT", async () => {
      await piNftMethods.withdraw(
        collectionContract.address,
        0,
        sampleERC20.address,
        100,
        {
          from: bob,
        }
      );
      assert.equal(await sampleERC20.balanceOf(bob), 300);
      assert.equal(await collectionContract.ownerOf(0), piNftMethods.address);
    });

    it("should let bob repay funds to the NFT", async () => {
      await sampleERC20.approve(piNftMethods.address, 300, { from: bob });
      await piNftMethods.Repay(
        collectionContract.address,
        0,
        sampleERC20.address,
        300,
        {
          from: bob,
        }
      );
      assert.equal(await sampleERC20.balanceOf(bob), 0);
      assert.equal(await collectionContract.ownerOf(0), bob);
    });

    it("should let bob place piNFT on sale again", async () => {
      await collectionContract.approve(piMarket.address, 0, { from: bob });
      const result = await piMarket.sellNFT(
        collectionContract.address,
        0,
        50000,
        "0x0000000000000000000000000000000000000000",
        {
          from: bob,
        }
      );
      assert.equal(
        await collectionContract.ownerOf(0),
        piMarket.address,
        "Failed to put piNFT on Sale"
      );
    });

    it("should let alice buy piNFT", async () => {
      let meta = await piMarket._tokenMeta(2);
      assert.equal(meta.status, true);

      let _balance1 = await web3.eth.getBalance(bob);
      let _balance2 = await web3.eth.getBalance(royaltyReceiver);
      let _balance3 = await web3.eth.getBalance(feeReceiver);
      let _balance4 = await web3.eth.getBalance(validator);

      result2 = await piMarket.BuyNFT(2, true, { from: alice, value: 50000 });
      // console.log(result2.receipt.rawLogs)
      assert.equal(await collectionContract.ownerOf(0), alice);

      //validator 200
      //royalties 500
      //fee 50

      let balance1 = await web3.eth.getBalance(bob);
      let balance2 = await web3.eth.getBalance(royaltyReceiver);
      let balance3 = await web3.eth.getBalance(feeReceiver);
      let balance4 = await web3.eth.getBalance(validator);
      let temp = BigNumber(balance1).minus(BigNumber(_balance1));
      console.log(balance1, " ", _balance1, " ", temp.toString());
      assert.equal(
        BigNumber(balance1).minus(BigNumber(_balance1)),
        (50000 * 9200) / 10000,
        "Failed to transfer NFT amount"
      );

      assert.equal(
        BigNumber(balance2).minus(BigNumber(_balance2)),
        (50000 * 500) / 10000,
        "Failed to transfer royalty amount"
      );

      // console.log(Number(web3.utils.toBN(balance2)-(web3.utils.toBN(_balance2))))

      // console.log(Number(BigNumber(balance3).minus(BigNumber(_balance3))));
      assert.equal(
        BigNumber(balance3).minus(BigNumber(_balance3)),
        (50000 * 100) / 10000,
        "Failed to transfer fee amount"
      );

      assert.equal(
        BigNumber(balance4).minus(BigNumber(_balance4)),
        (50000 * 200) / 10000,
        "Failed to transfer validator amount"
      );

      meta = await piMarket._tokenMeta(1);
      assert.equal(meta.status, false);
      let commission = await piNftMethods.validatorCommissions(collectionContract.address, 0);
      assert(commission.isValid == false);
      assert(commission.commission.account == validator);
      assert(commission.commission.value == 1000);
      await collectionContract.safeTransferFrom(alice, bob, 0, {from: alice});
    });

    it("should let bob place piNFT on sale again", async () => {
      await collectionContract.approve(piMarket.address, 0, { from: bob });
      const result = await piMarket.sellNFT(
        collectionContract.address,
        0,
        10000,
        "0x0000000000000000000000000000000000000000",
        {
          from: bob,
        }
      );
      assert.equal(
        await collectionContract.ownerOf(0),
        piMarket.address,
        "Failed to put piNFT on Sale"
      );
    });

    it("should not let non owner cancel sale", async () => {
      await expectRevert.unspecified(piMarket.cancelSale(3, { from: alice }))
    })

    it("should let bob cancel sale", async () => {
      await piMarket.cancelSale(3, { from: bob });
      meta = await piMarket._tokenMeta(3);
      assert.equal(meta.status, false);
    });

    it("should let bob redeem piNFT", async () => {
      await collectionContract.approve(piNftMethods.address, 0, { from: bob });
      await piNftMethods.redeemOrBurnPiNFT(
        collectionContract.address,
        0,
        alice,
        "0x0000000000000000000000000000000000000000",
        sampleERC20.address,
        false,
        {
          from: bob,
        }
      );
      const validatorBal = await sampleERC20.balanceOf(validator);
      assert.equal(
        await piNftMethods.viewBalance(
          collectionContract.address,
          0,
          sampleERC20.address
        ),
        0,
        "Failed to remove ERC20 tokens from NFT"
      );
      assert.equal(
        await sampleERC20.balanceOf(validator),
        1000,
        "Failed to transfer ERC20 tokens to validator"
      );
      assert.equal(
        await collectionContract.ownerOf(0),
        alice,
        "Failed to transfer NFT to alice"
      );
      let commission = await piNftMethods.validatorCommissions(collectionContract.address, 0);
      assert(commission.isValid == false);
      assert(commission.commission.account == "0x0000000000000000000000000000000000000000");
      assert(commission.commission.value == 0);
    });
  });

  describe("Auction sale", () => {
    it("should create a piNFT with 500 erc20 tokens to alice", async () => {
      sampleERC20 = await SampleERC20.deployed();
      piMarket = await PiMarket.deployed();
      await sampleERC20.mint(validator, 1000);
      const tx1 = await collectionContract.mintNFT(alice, "URI2");
      const tokenId = tx1.logs[0].args.tokenId.toNumber();
      assert(tokenId === 1, "Failed to mint or wrong token Id");

      await piNftMethods.addValidator(
        collectionContract.address,
        tokenId,
        validator
      );
      await sampleERC20.approve(piNftMethods.address, 500, {
        from: validator,
      });
      const tx = await piNftMethods.addERC20(
        collectionContract.address,
        tokenId,
        sampleERC20.address,
        500,
        1000,
        [[validator, 200]],
        {
          from: validator,
        }
      );
      let commission = await piNftMethods.validatorCommissions(collectionContract.address, 1);
      assert(commission.isValid == true);
      assert(commission.commission.account == validator);
      assert(commission.commission.value == 1000);
    });

    it("should not place nft on auction if price < 10000", async () => {
      await collectionContract.approve(piMarket.address, 1);
      await expectRevert.unspecified(piMarket.SellNFT_byBid(
        collectionContract.address,
        1,
        100,
        300,
        "0x0000000000000000000000000000000000000000"
      ))
    })

    it("should not place nft on auction if contract address is 0", async () => {
      await collectionContract.approve(piMarket.address, 1);
      await expectRevert.unspecified(piMarket.SellNFT_byBid(
        "0x0000000000000000000000000000000000000000",
        1,
        50000,
        300,
        "0x0000000000000000000000000000000000000000"
      ))
    })

    it("should not place nft on auction if auction time is 0", async () => {
      await collectionContract.approve(piMarket.address, 1);
      await expectRevert.unspecified(piMarket.SellNFT_byBid(
        collectionContract.address,
        1,
        50000,
        0,
        "0x0000000000000000000000000000000000000000"
      ))
    })

    it("should let alice place piNFT on auction", async () => {
      await collectionContract.approve(piMarket.address, 1);
      const tx = await piMarket.SellNFT_byBid(
        collectionContract.address,
        1,
        50000,
        300,
        "0x0000000000000000000000000000000000000000"
      );
      assert.equal(
        await collectionContract.ownerOf(1),
        piMarket.address,
        "Failed to put piNFT on Auction"
      );
      const result = await piMarket._tokenMeta(4);
      assert.equal(result.bidSale, true);
    });

    it("should let alice change the start price of the auction", async () => {
      await piMarket.editSalePrice(4, 10000);
      let result = await piMarket._tokenMeta(4);
      assert.equal(result.price, 10000);
      await piMarket.editSalePrice(4, 50000);
      result = await piMarket._tokenMeta(4);
      assert.equal(result.price, 50000);
    })

    it("should let bidders place bid on piNFT", async () => {
      await expectRevert.unspecified(piMarket.Bid(4, 60000, { from: alice, value: 60000 }))
      await expectRevert.unspecified(piMarket.Bid(4, 50000, { from: bidder1, value: 50000 }))

      await piMarket.Bid(4, 60000, { from: bidder1, value: 60000 });
      await piMarket.Bid(4, 65000, { from: bidder2, value: 65000 });
      await piMarket.Bid(4, 70000, { from: bidder1, value: 70000 });

      result = await piMarket.Bids(4, 2);
      assert.equal(result.buyerAddress, bidder1);
    });

    it("should not let alice change the auction price after bidding has begun", async () => {
      await expectRevert(piMarket.editSalePrice(4, 10000), "Bid has started")
    })

    it("should let alice execute highest bid", async () => {
      let _balance1 = await web3.eth.getBalance(alice);
      let _balance2 = await web3.eth.getBalance(royaltyReceiver);
      let _balance3 = await web3.eth.getBalance(feeReceiver);
      let _balance4 = await web3.eth.getBalance(validator);

      // console.log("Ball", _balance1.toString());

      await expectRevert.unspecified(piMarket.executeBidOrder(4, 2, true, { from: bob }))

      await piMarket.executeBidOrder(4, 2, true, { from: alice });
      result = await collectionContract.ownerOf(1);
      assert.equal(result, bidder1);

      let balance1 = await web3.eth.getBalance(alice);
      let balance2 = await web3.eth.getBalance(royaltyReceiver);
      let balance3 = await web3.eth.getBalance(feeReceiver);
      let balance4 = await web3.eth.getBalance(validator);
      // assert.equal(
      //     balance1 - _balance1,
      //   (7000 * 9200) / 10000,
      //   "Failed to transfer NFT amount"
      // );
      // console.log("ccc", (70000 * 9200) / 10000);
      assert.equal(
        BigNumber(balance2).minus(BigNumber(_balance2)),
        (70000 * 500) / 10000,
        "Failed to transfer royalty amount"
      );
      assert.equal(
        BigNumber(balance3).minus(BigNumber(_balance3)),
        (70000 * 100) / 10000,
        "Failed to transfer fee amount"
      );
      assert.equal(
        BigNumber(balance4).minus(BigNumber(_balance4)),
        (70000 * 1200) / 10000,
        "Failed to transfer validator amount"
      );
      let commission = await piNftMethods.validatorCommissions(collectionContract.address, 1);
      assert(commission.isValid == false);
      assert(commission.commission.account == validator);
      assert(commission.commission.value == 1000);
    });

    it("should not let wallet withdraw anothers bid", async () => {
      await expectRevert.unspecified(piMarket.withdrawBidMoney(4, 0, { from: bidder2 }))
    })

    it("should let other bidders withdraw their bids", async () => {
      await piMarket.withdrawBidMoney(4, 0, { from: bidder1 });
      await piMarket.withdrawBidMoney(4, 1, { from: bidder2 });
      result = await web3.eth.getBalance(piMarket.address);
      assert.equal(result, 0);
      await collectionContract.safeTransferFrom(bidder1, alice, 1, {from: bidder1});
    });

    it("should not let bidder withdraw again", async () => {
      await expectRevert.unspecified(piMarket.withdrawBidMoney(4, 0, { from: bidder1 }))
    })

    it("should not execute a withdrawn bid", async () => {
      await expectRevert.unspecified(piMarket.executeBidOrder(4, 1, true, { from: alice }))
    })

    it("should let alice place piNFT on auction", async () => {
      await collectionContract.approve(piMarket.address, 1);
      const tx = await piMarket.SellNFT_byBid(
        collectionContract.address,
        1,
        50000,
        300,
        "0x0000000000000000000000000000000000000000"
      );
      assert.equal(
        await collectionContract.ownerOf(1),
        piMarket.address,
        "Failed to put piNFT on Auction"
      );
      const result = await piMarket._tokenMeta(5);
      assert.equal(result.bidSale, true);
    });

    it("should let bidders place bid on piNFT", async () => {
      await piMarket.Bid(5, 70000, { from: bidder1, value: 70000 });

      result = await piMarket.Bids(5, 0);
      assert.equal(result.buyerAddress, bidder1);
    });

    it("should let alice execute highest bid", async () => {
      let _balance1 = await web3.eth.getBalance(alice);
      let _balance2 = await web3.eth.getBalance(royaltyReceiver);
      let _balance3 = await web3.eth.getBalance(feeReceiver);
      let _balance4 = await web3.eth.getBalance(validator);

      // console.log("Ball", _balance1.toString());

      await piMarket.executeBidOrder(5, 0, true, { from: alice });
      result = await collectionContract.ownerOf(1);
      assert.equal(result, bidder1);

      let balance1 = await web3.eth.getBalance(alice);
      let balance2 = await web3.eth.getBalance(royaltyReceiver);
      let balance3 = await web3.eth.getBalance(feeReceiver);
      let balance4 = await web3.eth.getBalance(validator);
      // assert.equal(
      //     balance1-_balance1,
      //   (7000 * 9200) / 10000,
      //   "Failed to transfer NFT amount"
      // );
      // console.log("ccc", (70000 * 9200) / 10000);
      assert.equal(
        BigNumber(balance2).minus(BigNumber(_balance2)),
        (70000 * 500) / 10000,
        "Failed to transfer royalty amount"
      );
      assert.equal(
        BigNumber(balance3).minus(BigNumber(_balance3)),
        (70000 * 100) / 10000,
        "Failed to transfer fee amount"
      );

      assert.equal(
        BigNumber(balance4).minus(BigNumber(_balance4)),
        (70000 * 200) / 10000,
        "Failed to transfer validator amount"
      );
      let commission = await piNftMethods.validatorCommissions(collectionContract.address, 1);
      assert(commission.isValid == false);
      assert(commission.commission.account == validator);
      assert(commission.commission.value == 1000);
    });

    it("should let bidder disintegrate NFT and ERC20 tokens", async () => {
      await collectionContract.approve(piNftMethods.address, 1, {
        from: bidder1,
      });
      await piNftMethods.redeemOrBurnPiNFT(
        collectionContract.address,
        1,
        bob,
        "0x0000000000000000000000000000000000000000",
        sampleERC20.address,
        false,
        {
          from: bidder1,
        }
      );
      const validatorBal = await sampleERC20.balanceOf(validator);
      assert.equal(
        await piNftMethods.viewBalance(
          collectionContract.address,
          1,
          sampleERC20.address
        ),
        0,
        "Failed to remove ERC20 tokens from NFT"
      );
      assert.equal(
        await sampleERC20.balanceOf(validator),
        2000,
        "Failed to transfer ERC20 tokens to validator"
      );
      assert.equal(
        await collectionContract.ownerOf(1),
        bob,
        "Failed to transfer NFT to bob"
      );
      let commission = await piNftMethods.validatorCommissions(collectionContract.address, 1);
      assert(commission.isValid == false);
      assert(commission.commission.account == "0x0000000000000000000000000000000000000000");
      assert(commission.commission.value == 0);
    });

    it("should create a piNFT with 500 erc20 tokens to alice", async () => {
      sampleERC20 = await SampleERC20.deployed();
      piMarket = await PiMarket.deployed();
      await sampleERC20.mint(validator, 1000);
      const tx1 = await collectionContract.mintNFT(alice, "URI2");
      const tokenId = tx1.logs[0].args.tokenId.toNumber();
      assert(tokenId === 2, "Failed to mint or wrong token Id");

      await piNftMethods.addValidator(
        collectionContract.address,
        tokenId,
        validator
      );
      await sampleERC20.approve(piNftMethods.address, 500, {
        from: validator,
      });
      const tx = await piNftMethods.addERC20(
        collectionContract.address,
        tokenId,
        sampleERC20.address,
        500,
        1000,
        [[validator, 200]],
        {
          from: validator,
        }
      );
      let commission = await piNftMethods.validatorCommissions(collectionContract.address, 2);
      assert(commission.isValid == true);
      assert(commission.commission.account == validator);
      assert(commission.commission.value == 1000);
    });

    it("should let alice place piNFT on auction", async () => {
      await collectionContract.approve(piMarket.address, 2);
      const tx = await piMarket.SellNFT_byBid(
        collectionContract.address,
        2,
        50000,
        300,
        "0x0000000000000000000000000000000000000000"
      );
      assert.equal(
        await collectionContract.ownerOf(2),
        piMarket.address,
        "Failed to put piNFT on Auction"
      );
      const result = await piMarket._tokenMeta(6);
      assert.equal(result.bidSale, true);
    });

    it("should let bidders place bid on piNFT", async () => {
      await piMarket.Bid(6, 60000, { from: bidder2, value: 60000 });
      await piMarket.Bid(6, 70000, { from: bidder1, value: 70000 });

      result = await piMarket.Bids(6, 1);
      assert.equal(result.buyerAddress, bidder1);
    });

    it("should let bidder2 withdraw the bid", async () => {
      await piMarket.withdrawBidMoney(6, 0, { from: bidder2 });
      result = await piMarket.Bids(6, 0);
      assert.equal(result.withdrawn, true);
    });

    it("should not allow owner to accept withdrawn bid", async () => {
      await expectRevert.unspecified(piMarket.executeBidOrder(6, 0, true));
    });

    it("should let highest bidder withdraw after auction expires", async () => {
      await time.increase(400);
      await piMarket.withdrawBidMoney(6, 1, { from: bidder1 });
      result = await piMarket.Bids(6, 1);
      assert.equal(result.withdrawn, true);
    });
  });
  describe("Swap NFTs", () => {
    it("should create a piNFT with 500 erc20 tokens to alice", async () => {
      sampleERC20 = await SampleERC20.deployed();
      piMarket = await PiMarket.deployed();
      await sampleERC20.mint(validator, 1000);
      const tx1 = await collectionContract.mintNFT(alice, "URI2");
      const tokenId = tx1.logs[0].args.tokenId.toNumber();
      assert(tokenId === 3, "Failed to mint or wrong token Id");

      await piNftMethods.addValidator(
        collectionContract.address,
        tokenId,
        validator
      );
      await sampleERC20.approve(piNftMethods.address, 500, {
        from: validator,
      });
      const tx = await piNftMethods.addERC20(
        collectionContract.address,
        tokenId,
        sampleERC20.address,
        500,
        0,
        [[validator, 200]],
        {
          from: validator,
        }
      );
    });

    it("should create a piNFT with 1000 erc20 tokens to bob", async () => {
      await sampleERC20.mint(validator, 1000);
      const tx1 = await collectionContract.mintNFT(bob, "URI2");
      const tokenId = tx1.logs[0].args.tokenId.toNumber();
      assert(tokenId === 4, "Failed to mint or wrong token Id");

      await piNftMethods.addValidator(
        collectionContract.address,
        tokenId,
        validator,
        { from: bob }
      );
      await sampleERC20.approve(piNftMethods.address, 500, {
        from: validator,
      });
      const tx = await piNftMethods.addERC20(
        collectionContract.address,
        tokenId,
        sampleERC20.address,
        500,
        0,
        [[validator, 200]],
        {
          from: validator,
        }
      );
    });

    it("should create a piNFT again with 500 erc20 tokens to alice", async () => {
      sampleERC20 = await SampleERC20.deployed();
      piMarket = await PiMarket.deployed();
      await sampleERC20.mint(validator, 1000);
      const tx1 = await collectionContract.mintNFT(alice, "URI2");
      const tokenId = tx1.logs[0].args.tokenId.toNumber();
      assert(tokenId === 5, "Failed to mint or wrong token Id");

      await piNftMethods.addValidator(
        collectionContract.address,
        tokenId,
        validator
      );
      await sampleERC20.approve(piNftMethods.address, 500, {
        from: validator,
      });
      const tx = await piNftMethods.addERC20(
        collectionContract.address,
        tokenId,
        sampleERC20.address,
        500,
        0,
        [[validator, 200]],
        {
          from: validator,
        }
      );
    });

    it("should let alice initiate swap request", async () => {
      await collectionContract.approve(piMarket.address, 3);
      const result = await piMarket.makeSwapRequest(
        collectionContract.address,
        collectionContract.address,
        3,
        4
      );
      const swapId = result.logs[0].args.swapId.toNumber();
      assert(swapId === 0, "Failed to initiate swap request");
      assert.equal(
        await collectionContract.ownerOf(3),
        piMarket.address,
        "Failed to put piNFT on Swap"
      );
    });

    it("should let alice initiate swap request again", async () => {
      await collectionContract.approve(piMarket.address, 5);
      const result = await piMarket.makeSwapRequest(
        collectionContract.address,
        collectionContract.address,
        5,
        4
      );
      const swapId = result.logs[0].args.swapId.toNumber();
      assert(swapId === 1, "Failed to initiate swap request");
      assert.equal(
        await collectionContract.ownerOf(5),
        piMarket.address,
        "Failed to put piNFT on Swap"
      );
    });

    it("should cancel the swap if requested token owner has changed", async () => {
      await collectionContract.safeTransferFrom(bob, carl, 4, { from: bob });
      await collectionContract.approve(piMarket.address, 4, { from: carl });
      await expectRevert(
        piMarket.acceptSwapRequest(0, { from: carl }),
        "requesting token owner has changed"
      );
      await collectionContract.safeTransferFrom(carl, bob, 4, { from: carl });
    });

    it("should not let an address that is not bob accept the swap request", async () => {
      await expectRevert(
        piMarket.acceptSwapRequest(0, { from: carl }),
        "Only requested owner can accept swap"
      );
    });

    it("should let bob accept the swap request", async () => {
      await collectionContract.approve(piMarket.address, 4, { from: bob });
      let res = await piMarket._swaps(0);
      assert.equal(res.status, true);
      const result = await piMarket.acceptSwapRequest(0, { from: bob });
      assert.equal(
        await collectionContract.ownerOf(3),
        bob,
        "Failed to Swap token with Id 3"
      );
      assert.equal(
        await collectionContract.ownerOf(4),
        alice,
        "Failed to Swap token with Id 4"
      );
      res = await piMarket._swaps(0);
      assert.equal(res.status, false);
    });

    it("should let alice cancle the swap request", async () => {
      let res = await piMarket._swaps(1);
      assert.equal(res.status, true);
      const result = await piMarket.cancelSwap(1, { from: alice });
      assert.equal(
        await collectionContract.ownerOf(5),
        alice,
        "Failed to Swap token with Id 5"
      );
      res = await piMarket._swaps(1);
      assert.equal(res.status, false);
    });
  });
});
