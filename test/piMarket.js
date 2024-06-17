const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BN } = require("@openzeppelin/test-helpers");

const BigNumber = require("big-number");

describe("piMarket", function () {
  async function deploypiMarket() {
    [
      alice,
      validator,
      bob,
      carl,
      royaltyReceiver,
      feeReceiver,
      bidder1,
      bidder2,
      bidder3,
    ] = await ethers.getSigners();

    const aconomyfee = await hre.ethers.deployContract("AconomyFee", []);
    aconomyFee = await aconomyfee.waitForDeployment();

    await aconomyFee.setAconomyPoolFee(50);
    await aconomyFee.setAconomyPiMarketFee(50);
    await aconomyFee.setAconomyNFTLendBorrowFee(50);

    const LibShare = await hre.ethers.deployContract("LibShare", []);
    await LibShare.waitForDeployment();

    const piNFTMethods = await hre.ethers.getContractFactory("piNFTMethods", {
      libraries: {
        LibShare: await LibShare.getAddress(),
      },
    });
    piNftMethods = await upgrades.deployProxy(
      piNFTMethods,
      ["0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"],
      {
        initializer: "initialize",
        kind: "uups",
        unsafeAllow: ["external-library-linking"],
      }
    );

    const LibCollection = await hre.ethers.deployContract("LibCollection", []);
    await LibCollection.waitForDeployment();

    const CollectionFactory = await hre.ethers.getContractFactory(
      "CollectionFactory",
      {
        libraries: {
          LibCollection: await LibCollection.getAddress(),
        },
      }
    );

    const CollectionMethods = await hre.ethers.deployContract(
      "CollectionMethods",
      []
    );
    let CollectionMethod = await CollectionMethods.waitForDeployment();

    const collectionFactory = await upgrades.deployProxy(
      CollectionFactory,
      [await CollectionMethod.getAddress(), await piNftMethods.getAddress()],
      {
        initializer: "initialize",
        kind: "uups",
        unsafeAllow: ["external-library-linking"],
      }
    );

    await CollectionMethods.initialize(
      alice.getAddress(),
      await collectionFactory.getAddress(),
      "xyz",
      "xyz"
    );

    const piNfT = await hre.ethers.getContractFactory("piNFT");
    piNFT = await upgrades.deployProxy(
      piNfT,
      [
        "Aconomy",
        "ACO",
        await piNftMethods.getAddress(),
        "0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d",
      ],
      {
        initializer: "initialize",
        kind: "uups",
      }
    );

    const LibMarket = await hre.ethers.deployContract("LibMarket", []);
    await LibMarket.waitForDeployment();

    const pimarket = await hre.ethers.getContractFactory("piMarket", {
      libraries: {
        LibMarket: await LibMarket.getAddress(),
      },
    });
    piMarket = await upgrades.deployProxy(
      pimarket,
      [
        await aconomyFee.getAddress(),
        await collectionFactory.getAddress(),
        await piNftMethods.getAddress(),
      ],
      {
        initializer: "initialize",
        kind: "uups",
        unsafeAllow: ["external-library-linking"],
      }
    );

    await piNftMethods.setPiMarket(piMarket.getAddress());

    const mintToken = await hre.ethers.deployContract("mintToken", [
      "100000000000",
    ]);
    sampleERC20 = await mintToken.waitForDeployment();

    // console.log("AconomyFee : ", await aconomyFee.getAddress());
    // console.log("CollectionMethods : ", await CollectionMethod.getAddress());
    // console.log("CollectionFactory : ", await collectionFactory.getAddress());
    // console.log("mintToken : ", await sampleERC20.getAddress());
    // console.log("piNFT: ", await piNFT.getAddress());
    // console.log("piNFTMethods", await piNftMethods.getAddress());
    // console.log("piMarket:", await piMarket.getAddress());

    return {
      piNFT,
      piMarket,
      sampleERC20,
      piNftMethods,
      aconomyFee,
      alice,
      validator,
      bob,
      carl,
      royaltyReceiver,
      feeReceiver,
      bidder1,
      bidder2,
      bidder3,
    };
  }

  describe("Direct Sale", function () {
    it("should deploy the contracts", async () => {
      let {
        piNFT,
        piMarket,
        sampleERC20,
        piNftMethods,
        aconomyFee,
        alice,
        validator,
        bob,
        carl,
        royaltyReceiver,
        feeReceiver,
        bidder1,
        bidder2,
        bidder3,
      } = await deploypiMarket();
    });

    it("should not allow non owner to pause piMarket", async () => {
      await expect(
        piMarket.connect(royaltyReceiver).pause()
      ).to.be.revertedWith("Ownable: caller is not the owner");

      await piMarket.pause();

      await expect(
        piMarket.connect(royaltyReceiver).unpause()
      ).to.be.revertedWith("Ownable: caller is not the owner");

      await piMarket.unpause();
    })

    it("should create a piNFT with 500 erc20 tokens to carl", async () => {
      await aconomyFee.setAconomyPiMarketFee(100);
      await aconomyFee.transferOwnership(feeReceiver.getAddress());
      await sampleERC20.mint(validator.getAddress(), 1000);
      const tx1 = await piNFT.mintNFT(carl.getAddress(), "URI1", [
        [royaltyReceiver.getAddress(), 500],
      ]);

      const owner = await piNFT.ownerOf(0);
      expect(owner).to.equal(await carl.getAddress());
      const bal = await piNFT.balanceOf(carl);
      expect(bal).to.equal(1);

      let exp = new BN(await time.latest()).add(new BN(3600));
      // await time.increase(7501);

      await piNftMethods
        .connect(carl)
        .addValidator(piNFT.getAddress(), 0, validator.getAddress());
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
      const tx = await piNftMethods
        .connect(validator)
        .addERC20(piNFT.getAddress(), 0, sampleERC20.getAddress(), 500, 1000, "uri", [
          [validator.getAddress(), 200],
        ]);

      const tokenBal = await piNftMethods.viewBalance(
        piNFT.getAddress(),
        0,
        sampleERC20.getAddress()
      );

      expect(tokenBal).to.equal(500);

      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        0
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(1000);
    });

    it("should let carl transfer piNFT to alice", async () => {
      await piNFT
        .connect(carl)
        .safeTransferFrom(carl.getAddress(), alice.getAddress(), 0);
      expect(await piNFT.ownerOf(0)).to.equal(await alice.getAddress());
    });

    it("should not put on sale if the contract is paused", async () => {
      await piMarket.pause();

      await expect(
        piMarket.sellNFT(
          piNFT.getAddress(),
          0,
          50000,
          "0x0000000000000000000000000000000000000000"
        )
      ).to.be.revertedWith("Pausable: paused");
      await piMarket.unpause();
    });

    it("should not place nft on sale if price < 10000", async () => {
      await piNFT.approve(piMarket.getAddress(), 0);
      await expect(
        piMarket.sellNFT(
          piNFT.getAddress(),
          0,
          100,
          "0x0000000000000000000000000000000000000000"
        )
      ).to.be.revertedWithoutReason();
    });

    it("should not place nft on sale if contract address is 0", async () => {
      await piNFT.approve(piMarket.getAddress(), 0);
      await expect(
        piMarket.sellNFT(
          "0x0000000000000000000000000000000000000000",
          0,
          50000,
          "0x0000000000000000000000000000000000000000"
        )
      ).to.be.revertedWithoutReason();
    });

    it("should let alice place piNFT on sale", async () => {
      await piNFT.approve(piMarket.getAddress(), 0);
      const result = await piMarket.sellNFT(
        piNFT.getAddress(),
        0,
        50000,
        "0x0000000000000000000000000000000000000000"
      );
      expect(await piNFT.ownerOf(0)).to.equal(await piMarket.getAddress());
    });

    it("should not allow sale price edit if contract is paused", async () => {
      await piMarket.pause();

      await expect(
        piMarket.connect(alice).editSalePrice(1, 60000, 200)
      ).to.be.revertedWith("Pausable: paused");

      await piMarket.unpause();
    });

    it("should edit the price after listing on sale", async () => {
      await piMarket.connect(alice).editSalePrice(1, 60000, 200);
      await expect(
        piMarket.connect(bob).editSalePrice(1, 60000, 200)
      ).to.be.revertedWith("You are not the owner");

      await expect(
        piMarket.connect(alice).editSalePrice(1, 60, 200)
      ).to.be.revertedWithoutReason();
      let meta = await piMarket._tokenMeta(1);
      let price = meta.price;
      expect(price).to.equal(60000);
      await piMarket.connect(alice).editSalePrice(1, 60000, 200);
      await piMarket.connect(alice).editSalePrice(1, 50000, 200);
      let newmeta = await piMarket._tokenMeta(1);
      expect(newmeta.price).to.equal(50000);
    });

    it("should not let seller buy their own nft", async () => {
      await expect(
        piMarket.connect(alice).BuyNFT(1, false, { value: 50000 })
      ).to.be.revertedWithoutReason();
    });

    it("should not let bob buy nft if contract is paused", async () => {
      await piMarket.pause();

      await expect(
        piMarket.connect(bob).BuyNFT(1, false, { value: 50000 })
      ).to.be.revertedWith("Pausable: paused");

      await piMarket.unpause();
    });

    it("should not let bidder place bid on direct sale NFT", async () => {
      await expect(piMarket.connect(bob).Bid(1, 50000, {value: 50000})).to.be.revertedWithoutReason()
    })

    it("should let bob buy piNFT", async () => {
      let meta = await piMarket._tokenMeta(1);
      expect(meta.status).to.equal(true);

      const _balance1 = await ethers.provider.getBalance(alice.getAddress());
      const _balance2 = await ethers.provider.getBalance(
        royaltyReceiver.getAddress()
      );
      const _balance3 = await ethers.provider.getBalance(
        feeReceiver.getAddress()
      );
      const _balance4 = await ethers.provider.getBalance(
        validator.getAddress()
      );

      result2 = await piMarket.connect(bob).BuyNFT(1, false, { value: 50000 });
      expect(await piNFT.ownerOf(0)).to.equal(await bob.getAddress());
      const balance1 = await ethers.provider.getBalance(alice.getAddress());
      const balance2 = await ethers.provider.getBalance(
        royaltyReceiver.getAddress()
      );
      const balance3 = await ethers.provider.getBalance(
        feeReceiver.getAddress()
      );
      const balance4 = await ethers.provider.getBalance(validator.getAddress());
      let temp = BigNumber(balance1.toString()).minus(
        BigNumber(_balance1.toString())
      );
      let alicegotAmount = (50000 * 8200) / 10000;
      expect(temp.toString()).to.equal(alicegotAmount.toString());
      let temp2 = BigNumber(balance2.toString()).minus(
        BigNumber(_balance2.toString())
      );
      let gotAmount2 = (50000 * 500) / 10000;
      expect(temp2.toString()).to.equal(gotAmount2.toString());

      let temp3 = BigNumber(balance3.toString()).minus(
        BigNumber(_balance3.toString())
      );
      let gotAmount3 = (50000 * 100) / 10000;
      expect(temp3.toString()).to.equal(gotAmount3.toString());

      let temp4 = BigNumber(balance4.toString()).minus(
        BigNumber(_balance4.toString())
      );
      let gotAmount4 = (50000 * 1200) / 10000;
      expect(temp4.toString()).to.equal(gotAmount4.toString());

      let newMeta = await piMarket._tokenMeta(1);
      expect(newMeta.status).to.equal(false);

      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        0
      );
      expect(commission.isValid).to.equal(false);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(1000);
    });

    it("should not let owner cancel sale if sale status is false", async () => {
      await expect(
        piMarket.connect(alice).cancelSale(1)
      ).to.be.revertedWithoutReason();
    });

    it("should not allow sale price edit if sale status is false", async () => {
      await expect(
        piMarket.connect(alice).editSalePrice(1, 60000, 200)
      ).to.be.revertedWithoutReason();
    });

    it("should let bob withdraw funds from the NFT", async () => {
      await piNFT.connect(bob).approve(piNftMethods.getAddress(), 0);
      await piNftMethods
        .connect(bob)
        .withdraw(piNFT.getAddress(), 0, sampleERC20.getAddress(), 200);
      expect(await sampleERC20.balanceOf(bob)).to.equal(200);
      expect(await piNFT.ownerOf(0)).to.equal(await piNftMethods.getAddress());
    });

    it("should let bob withdraw more funds from the NFT", async () => {
      await piNftMethods
        .connect(bob)
        .withdraw(piNFT.getAddress(), 0, sampleERC20.getAddress(), 100);
      expect(await sampleERC20.balanceOf(bob)).to.equal(300);
      expect(await piNFT.ownerOf(0)).to.equal(await piNftMethods.getAddress());
    });

    it("should let bob repay funds to the NFT", async () => {
      await sampleERC20.connect(bob).approve(piNftMethods.getAddress(), 300);
      await piNftMethods
        .connect(bob)
        .Repay(piNFT.getAddress(), 0, sampleERC20.getAddress(), 300);
      expect(await sampleERC20.balanceOf(bob)).to.equal(0);
      expect(await piNFT.ownerOf(0)).to.equal(await bob.getAddress());
    });

    it("should allow validator to add erc20 and change commission and royalties", async () => {
      let exp = new BN(await time.latest()).add(new BN(7500));
      await time.increase(3601);
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
      await piNftMethods
        .connect(validator)
        .addERC20(piNFT.getAddress(), 0, sampleERC20.getAddress(), 500, 100, "uri", [
          [validator.getAddress(), 300],
        ]);
      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        0
      );
      expect(commission.isValid).to.equal(false);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(100);
    });

    it("should let bob place piNFT on sale again", async () => {
      await piNFT.connect(bob).approve(piMarket.getAddress(), 0, { from: bob });
      const result = await piMarket
        .connect(bob)
        .sellNFT(
          piNFT.getAddress(),
          0,
          50000,
          "0x0000000000000000000000000000000000000000"
        );
      expect(await piNFT.ownerOf(0)).to.equal(await piMarket.getAddress());
    });

    it("should let alice buy piNFT", async () => {
      let meta = await piMarket._tokenMeta(2);
      expect(meta.status).to.equal(true);
      const _balance1 = await ethers.provider.getBalance(bob.getAddress());
      const _balance2 = await ethers.provider.getBalance(
        royaltyReceiver.getAddress()
      );
      const _balance3 = await ethers.provider.getBalance(
        feeReceiver.getAddress()
      );
      const _balance4 = await ethers.provider.getBalance(
        validator.getAddress()
      );

      result2 = await piMarket
        .connect(alice)
        .BuyNFT(2, false, { value: 50000 });
      expect(await piNFT.ownerOf(0)).to.equal(await alice.getAddress());
      const balance1 = await ethers.provider.getBalance(bob.getAddress());
      const balance2 = await ethers.provider.getBalance(
        royaltyReceiver.getAddress()
      );
      const balance3 = await ethers.provider.getBalance(
        feeReceiver.getAddress()
      );
      const balance4 = await ethers.provider.getBalance(validator.getAddress());
      let temp1 = BigNumber(balance1.toString()).minus(
        BigNumber(_balance1.toString())
      );
      let gotAmount1 = (50000 * 9100) / 10000;
      expect(temp1.toString()).to.equal(gotAmount1.toString());

      let temp2 = BigNumber(balance2.toString()).minus(
        BigNumber(_balance2.toString())
      );
      let gotAmount2 = (50000 * 500) / 10000;
      expect(temp2.toString()).to.equal(gotAmount2.toString());

      let temp3 = BigNumber(balance3.toString()).minus(
        BigNumber(_balance3.toString())
      );
      let gotAmount3 = (50000 * 100) / 10000;
      expect(temp2.toString()).to.equal(gotAmount2.toString());

      let temp4 = BigNumber(balance4.toString()).minus(
        BigNumber(_balance4.toString())
      );
      let gotAmount4 = (50000 * 300) / 10000;
      expect(temp4.toString()).to.equal(gotAmount4.toString());

      let newMeta = await piMarket._tokenMeta(1);
      expect(newMeta.status).to.equal(false);

      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        0
      );
      expect(commission.isValid).to.equal(false);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(100);
      await piNFT
        .connect(alice)
        .safeTransferFrom(alice.getAddress(), bob.getAddress(), 0);
    });

    it("should let bob place piNFT on sale again", async () => {
      await piNFT.connect(bob).approve(piMarket.getAddress(), 0);
      await piMarket
        .connect(bob)
        .sellNFT(
          piNFT.getAddress(),
          0,
          10000,
          "0x0000000000000000000000000000000000000000"
        );
      expect(await piNFT.ownerOf(0)).to.equal(await piMarket.getAddress());
    });
    
    it("should not allow cancelling sale if contract is paused", async () => {
      await piMarket.pause();

      await expect(
        piMarket.connect(alice).cancelSale(3)
      ).to.be.revertedWith("Pausable: paused");

      await piMarket.unpause();
    });

    it("should not let non owner cancel sale", async () => {
      await expect(
        piMarket.connect(alice).cancelSale(3)
      ).to.be.revertedWithoutReason();
    });

    it("should let bob cancel sale", async () => {
      await piMarket.connect(bob).cancelSale(3);
      meta = await piMarket._tokenMeta(2);
      expect(meta.status).to.equal(false);
    });

    it("should let bob redeem piNFT", async () => {
      await piNFT.connect(bob).approve(piNftMethods.getAddress(), 0);
      await piNftMethods
        .connect(bob)
        .redeemOrBurnPiNFT(
          piNFT.getAddress(),
          0,
          alice,
          "0x0000000000000000000000000000000000000000",
          sampleERC20.getAddress(),
          false
        );
      const validatorBal = await sampleERC20.balanceOf(validator.getAddress());
      expect(
        await piNftMethods.viewBalance(
          piNFT.getAddress(),
          0,
          sampleERC20.getAddress()
        )
      ).to.equal(0);

      expect(await sampleERC20.balanceOf(validator.getAddress())).to.equal(
        1000
      );

      expect(await piNFT.ownerOf(0)).to.equal(await alice.getAddress());

      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        0
      );
      expect(commission.isValid).to.equal(false);
      expect(commission.commission.account).to.equal(
        "0x0000000000000000000000000000000000000000"
      );
      expect(commission.commission.value).to.equal(0);
    });
  });

  describe("Auction sale", () => {
    it("should create a piNFT with 500 erc20 tokens to alice", async () => {
      await sampleERC20.mint(validator.getAddress(), 1000);
      await piNFT.mintNFT(alice.getAddress(), "URI2", [
        [royaltyReceiver.getAddress(), 500],
      ]);
      let tokenId = 1;
      const owner = await piNFT.ownerOf(tokenId);
      expect(owner).to.equal(await alice.getAddress());
      const bal = await piNFT.balanceOf(alice.getAddress());
      expect(bal).to.equal(2);

      let exp = new BN(await time.latest()).add(new BN(3600));
      // await time.increase(7501);

      await piNftMethods.addValidator(
        piNFT.getAddress(),
        tokenId,
        validator.getAddress()
      );
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
      await piNftMethods
        .connect(validator)
        .addERC20(
          piNFT.getAddress(),
          tokenId,
          sampleERC20.getAddress(),
          500,
          900,
          "uri",
          [[validator.getAddress(), 200]]
        );

      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        1
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(900);
    });

    it("should not place nft on auction if contract is paused", async () => {
      await piMarket.pause();

      await piNFT.approve(piMarket.getAddress(), 1);

      await expect(
        piMarket.SellNFT_byBid(
          piNFT.getAddress(),
          1,
          100,
          300,
          "0x0000000000000000000000000000000000000000"
        )
      ).to.be.revertedWith("Pausable: paused");

      await piMarket.unpause();
    });

    it("should not place nft on auction if price < 10000", async () => {
      await piNFT.approve(piMarket.getAddress(), 1);
      await expect(
        piMarket.SellNFT_byBid(
          piNFT.getAddress(),
          1,
          100,
          300,
          "0x0000000000000000000000000000000000000000"
        )
      ).to.be.revertedWithoutReason();
    });

    it("should not place nft on auction if contract address is 0", async () => {
      await piNFT.approve(piMarket.getAddress(), 1);
      await expect(
        piMarket.SellNFT_byBid(
          "0x0000000000000000000000000000000000000000",
          1,
          50000,
          300,
          "0x0000000000000000000000000000000000000000"
        )
      ).to.be.revertedWithoutReason();
    });

    it("should not place nft on auction if auction time is 0", async () => {
      await piNFT.approve(piMarket.getAddress(), 1);
      await expect(
        piMarket.SellNFT_byBid(
          piNFT.getAddress(),
          1,
          50000,
          0,
          "0x0000000000000000000000000000000000000000"
        )
      ).to.be.revertedWithoutReason();
    });

    // it("should let alice place piNFT on auction", async () => {
    //   await piNFT.approve(piMarket.getAddress(), 1);
    //   await piMarket.SellNFT_byBid(
    //     piNFT.getAddress(),
    //     1,
    //     50000,
    //     300,
    //     "0x0000000000000000000000000000000000000000"
    //   );
    //   expect(await piNFT.ownerOf(1)).to.equal(await piMarket.getAddress());

    //   const result = await piMarket._tokenMeta(4);
    //   expect(result.bidSale).to.equal(true);
    // });

    // it("should let alice change the start price of the auction", async () => {
    //   await piMarket.editSalePrice(4, 10000, 200);
    //   let result = await piMarket._tokenMeta(4);
    //   expect(result.price).to.equal(10000);
    //   await piMarket.editSalePrice(4, 50000, 200);
    //   result = await piMarket._tokenMeta(4);
    //   expect(result.price).to.equal(50000);
    // });

    it("should allow validator to add erc20 and change commission and royalties", async () => {
      let exp = new BN(await time.latest()).add(new BN(7500));
      await time.increase(3601);
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
      await piNftMethods
        .connect(validator)
        .addERC20(piNFT.getAddress(), 1, sampleERC20.getAddress(), 500, 1000, "uri", [
          [validator, 300],
        ]);
      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        1
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(1000);
    });

    it("should let alice place piNFT on auction", async () => {
      await piNFT.approve(piMarket.getAddress(), 1);
      await piMarket.SellNFT_byBid(
        piNFT.getAddress(),
        1,
        50000,
        300,
        "0x0000000000000000000000000000000000000000"
      );
      expect(await piNFT.ownerOf(1)).to.equal(await piMarket.getAddress());

      const result = await piMarket._tokenMeta(4);
      expect(result.bidSale).to.equal(true);
    });

    it("should let alice change the start price of the auction", async () => {
      await piMarket.editSalePrice(4, 10000, 200);
      let result = await piMarket._tokenMeta(4);
      expect(result.price).to.equal(10000);
      await piMarket.editSalePrice(4, 50000, 200);
      result = await piMarket._tokenMeta(4);
      expect(result.price).to.equal(50000);
    });

    it("should not place bids if contract is paused", async () => {
      await piMarket.pause();

      await expect(
        piMarket.connect(bidder1).Bid(4, 60000, { value: 60000 })
      ).to.be.revertedWith("Pausable: paused");

      await piMarket.unpause();
    });

    it("should not place bids bid price is not equal to msg.value", async () => {
      await expect(
        piMarket.connect(bidder1).Bid(4, 50000, { value: 60000 })
      ).to.be.revertedWithoutReason();
    });

    it("should let bidders place bid on piNFT", async () => {
      await expect(
        piMarket.connect(alice).Bid(4, 60000, { value: 60000 })
      ).to.be.revertedWithoutReason();

      await expect(
        piMarket.connect(bidder1).Bid(4, 50000, { value: 50000 })
      ).to.be.revertedWithoutReason();

      await piMarket.connect(bidder1).Bid(4, 60000, { value: 60000 });
      await piMarket.connect(bidder2).Bid(4, 65000, { value: 65000 });
      await piMarket.connect(bidder1).Bid(4, 70000, { value: 70000 });
      
      //should not let highest bidder withdraw before auction end time
      await expect(piMarket.connect(bidder1).withdrawBidMoney(4, 2)).to.be.revertedWithoutReason()

      await time.increase(300);
      await expect(piMarket.connect(bidder2).Bid(4, 75000, { value: 75000 })
      ).to.be.revertedWithoutReason()

      result = await piMarket.Bids(4, 2);
      expect(result.buyerAddress).to.equal(await bidder1.getAddress());
    });

    it("should not let alice change the auction price after bidding has begun", async () => {
      await expect(piMarket.editSalePrice(4, 10000, 200)).to.be.revertedWith(
        "Bid has started"
      );
    });

    it("should not execute bid if contract is paused", async () => {
      await piMarket.pause();

      await expect(
        piMarket.connect(alice).executeBidOrder(4, 2, false)
      ).to.be.revertedWith("Pausable: paused");

      await piMarket.unpause();
    });

    it("should let alice execute highest bid", async () => {
      const _balance1 = await ethers.provider.getBalance(alice.getAddress());
      const _balance2 = await ethers.provider.getBalance(
        royaltyReceiver.getAddress()
      );
      const _balance3 = await ethers.provider.getBalance(
        feeReceiver.getAddress()
      );
      const _balance4 = await ethers.provider.getBalance(
        validator.getAddress()
      );

      await expect(
        piMarket.connect(bob).executeBidOrder(4, 2, false)
      ).to.be.revertedWithoutReason();

      await piMarket.connect(alice).executeBidOrder(4, 2, false);
      // result = await piNFT.ownerOf(1);
      expect(await piNFT.ownerOf(1)).to.equal(await bidder1.getAddress());

      const balance1 = await ethers.provider.getBalance(alice.getAddress());
      const balance2 = await ethers.provider.getBalance(
        royaltyReceiver.getAddress()
      );
      const balance3 = await ethers.provider.getBalance(
        feeReceiver.getAddress()
      );
      const balance4 = await ethers.provider.getBalance(validator.getAddress());

      let bal1 = BigNumber(balance2.toString()).minus(
        BigNumber(_balance2.toString())
      );
      let _bal1 = (70000 * 500) / 10000;
      expect(bal1.toString()).to.equal(_bal1.toString());

      let bal2 = BigNumber(balance3.toString()).minus(
        BigNumber(_balance3.toString())
      );
      let _bal2 = (70000 * 100) / 10000;
      expect(bal2.toString()).to.equal(_bal2.toString());

      let bal3 = BigNumber(balance4.toString()).minus(
        BigNumber(_balance4.toString())
      );
      let _bal3 = (70000 * 1300) / 10000;
      expect(bal3.toString()).to.equal(_bal3.toString());

      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        1
      );
      expect(commission.isValid).to.equal(false);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(1000);
    });

    it("should not let wallet withdraw anothers bid", async () => {
      await expect(
        piMarket.connect(bidder2).withdrawBidMoney(4, 0)
      ).to.be.revertedWithoutReason();
    });

    it("should not allow bids to be withdrawn if contract is paused", async () => {
      await piMarket.pause();

      await expect(
        piMarket.connect(bidder1).withdrawBidMoney(4, 0)
      ).to.be.revertedWith("Pausable: paused");

      await piMarket.unpause();
    });

    it("should let other bidders withdraw their bids", async () => {
      await piMarket.connect(bidder1).withdrawBidMoney(4, 0);
      await piMarket.connect(bidder2).withdrawBidMoney(4, 1);
      const balance1 = await ethers.provider.getBalance(piMarket.getAddress());
      expect(balance1.toString()).to.equal("0");
      await piNFT
        .connect(bidder1)
        .safeTransferFrom(bidder1.getAddress(), alice.getAddress(), 1);
    });

    it("should not let bidder withdraw again", async () => {
      await expect(
        piMarket.connect(bidder1).withdrawBidMoney(4, 0)
      ).to.be.revertedWithoutReason();
    });

    it("should not execute a withdrawn bid", async () => {
      await expect(
        piMarket.connect(alice).executeBidOrder(4, 1, false)
      ).to.be.revertedWithoutReason();
    });

    it("should let alice place piNFT on auction", async () => {
      await piNFT.approve(piMarket.getAddress(), 1);
      await piMarket.SellNFT_byBid(
        piNFT.getAddress(),
        1,
        50000,
        300,
        "0x0000000000000000000000000000000000000000"
      );
      expect(await piNFT.ownerOf(1)).to.equal(await piMarket.getAddress());
      const result = await piMarket._tokenMeta(5);
      expect(result.bidSale).to.equal(true);
    });

    it("should let bidders place bid on piNFT", async () => {
      await piMarket.connect(bidder1).Bid(5, 70000, { value: 70000 });
      result = await piMarket.Bids(5, 0);

      expect(result.buyerAddress).to.equal(await bidder1.getAddress());
    });

    it("should let alice execute highest bid", async () => {
      const _balance1 = await ethers.provider.getBalance(alice.getAddress());
      const _balance2 = await ethers.provider.getBalance(
        royaltyReceiver.getAddress()
      );
      const _balance3 = await ethers.provider.getBalance(
        feeReceiver.getAddress()
      );
      const _balance4 = await ethers.provider.getBalance(
        validator.getAddress()
      );

      await piMarket.connect(alice).executeBidOrder(5, 0, false);

      expect(await piNFT.ownerOf(1)).to.equal(await bidder1.getAddress());

      const balance1 = await ethers.provider.getBalance(alice.getAddress());
      const balance2 = await ethers.provider.getBalance(
        royaltyReceiver.getAddress()
      );
      const balance3 = await ethers.provider.getBalance(
        feeReceiver.getAddress()
      );
      const balance4 = await ethers.provider.getBalance(validator.getAddress());

      let bal1 = BigNumber(balance2.toString()).minus(
        BigNumber(_balance2.toString())
      );
      let _bal1 = (70000 * 500) / 10000;
      expect(bal1.toString()).to.equal(_bal1.toString());

      let bal2 = BigNumber(balance3.toString()).minus(
        BigNumber(_balance3.toString())
      );
      let _bal2 = (70000 * 100) / 10000;
      expect(bal2.toString()).to.equal(_bal2.toString());

      let bal3 = BigNumber(balance4.toString()).minus(
        BigNumber(_balance4.toString())
      );
      let _bal3 = (70000 * 300) / 10000;
      expect(bal3.toString()).to.equal(_bal3.toString());

      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        1
      );
      expect(commission.isValid).to.equal(false);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(1000);
    });

    it("should let bidder disintegrate NFT and ERC20 tokens", async () => {
      await piNFT.connect(bidder1).approve(piNftMethods.getAddress(), 1);
      await piNftMethods
        .connect(bidder1)
        .redeemOrBurnPiNFT(
          piNFT.getAddress(),
          1,
          bob,
          "0x0000000000000000000000000000000000000000",
          sampleERC20.getAddress(),
          false
        );
      const validatorBal = await sampleERC20.balanceOf(validator.getAddress());
      expect(
        await piNftMethods.viewBalance(
          piNFT.getAddress(),
          1,
          sampleERC20.getAddress()
        )
      ).to.equal(0);
      expect(await sampleERC20.balanceOf(validator.getAddress())).to.equal(
        2000
      );
      expect(await piNFT.ownerOf(1)).to.equal(await bob.getAddress());

      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        1
      );
      expect(commission.isValid).to.equal(false);
      expect(commission.commission.account).to.equal(
        "0x0000000000000000000000000000000000000000"
      );
      expect(commission.commission.value).to.equal(0);
    });

    it("should create a piNFT with 500 erc20 tokens to alice", async () => {
      await sampleERC20.mint(validator.getAddress(), 1000);
      await piNFT.mintNFT(alice.getAddress(), "URI2", [
        [royaltyReceiver.getAddress(), 500],
      ]);
      let exp = new BN(await time.latest()).add(new BN(3600));
      // await time.increase(7501);
      let tokenId = 2;
      const owner = await piNFT.ownerOf(tokenId);
      expect(owner).to.equal(await alice.getAddress());
      const bal = await piNFT.balanceOf(alice.getAddress());
      expect(bal).to.equal(2);

      await piNftMethods.addValidator(
        piNFT.getAddress(),
        tokenId,
        validator.getAddress()
      );
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
      await piNftMethods
        .connect(validator)
        .addERC20(
          piNFT.getAddress(),
          tokenId,
          sampleERC20.getAddress(),
          500,
          900,
          "uri",
          [[validator.getAddress(), 200]]
        );

      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        2
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(900);
    });

    it("should let alice place piNFT on auction", async () => {
      await piNFT.approve(piMarket.getAddress(), 2);
      await piMarket.SellNFT_byBid(
        piNFT.getAddress(),
        2,
        50000,
        300,
        "0x0000000000000000000000000000000000000000"
      );
      expect(await piNFT.ownerOf(2)).to.equal(await piMarket.getAddress());

      const result = await piMarket._tokenMeta(6);
      expect(result.bidSale).to.equal(true);
    });

    it("should let bidders place bid on piNFT", async () => {
      await expect(
        piMarket.connect(alice).Bid(6, 60000, { value: 60000 })
      ).to.be.revertedWithoutReason();

      await expect(
        piMarket.connect(bidder1).Bid(6, 50000, { value: 50000 })
      ).to.be.revertedWithoutReason();

      await piMarket.connect(bidder2).Bid(6, 60000, { value: 60000 });
      await piMarket.connect(bidder1).Bid(6, 70000, { value: 70000 });

      result = await piMarket.Bids(6, 1);
      expect(result.buyerAddress).to.equal(await bidder1.getAddress());
    });

    it("should let bidder2 withdraw the bid", async () => {
      await piMarket.connect(bidder2).withdrawBidMoney(6, 0);
      result = await piMarket.Bids(6, 0);
      expect(result.withdrawn).to.equal(true);
    });

    it("should not allow owner to accept withdrawn bid", async () => {
      await expect(
        piMarket.executeBidOrder(6, 0, false)
      ).to.be.revertedWithoutReason();
    });

    it("should not let bidder1 withdraw the highest bid", async () => {
      await expect(piMarket.connect(bidder1).withdrawBidMoney(6, 1)).to.be.revertedWithoutReason();
    });

    it("should let highest bidder withdraw after auction expires", async () => {
      await time.increase(400);
      await piMarket.connect(bidder1).withdrawBidMoney(6, 1);
      result = await piMarket.Bids(6, 1);
      expect(result.withdrawn).to.equal(true);
    });

    it("should let alice cancel the auction after expiration", async () => {
      await piMarket.cancelSale(6);
      result = await piMarket._tokenMeta(6);
      expect(result.status).to.equal(false)
      expect(await piNFT.ownerOf(2)).to.equal(await alice.getAddress());
    })

    it("should let alice place piNFT on auction", async () => {
      await piNFT.approve(piMarket.getAddress(), 2);
      await piMarket.SellNFT_byBid(
        piNFT.getAddress(),
        2,
        50000,
        300,
        "0x0000000000000000000000000000000000000000"
      );
      expect(await piNFT.ownerOf(2)).to.equal(await piMarket.getAddress());

      const result = await piMarket._tokenMeta(7);
      expect(result.bidSale).to.equal(true);
    });

    it("should let bidders place bid on piNFT", async () => {
      await expect(
        piMarket.connect(alice).Bid(7, 60000, { value: 60000 })
      ).to.be.revertedWithoutReason();

      await expect(
        piMarket.connect(bidder1).Bid(7, 50000, { value: 50000 })
      ).to.be.revertedWithoutReason();

      await piMarket.connect(bidder2).Bid(7, 60000, { value: 60000 });
      await piMarket.connect(bidder1).Bid(7, 70000, { value: 70000 });

      result = await piMarket.Bids(7, 1);
      expect(result.buyerAddress).to.equal(await bidder1.getAddress());
    });

    it("should not let bidder1 withdraw the highest bid", async () => {
      await expect(piMarket.connect(bidder1).withdrawBidMoney(7, 1)).to.be.revertedWithoutReason();
    });

    it("should let alice cancel the auction", async () => {
      await piMarket.cancelSale(7);
      result = await piMarket._tokenMeta(7);
      expect(result.status).to.equal(false)
      expect(await piNFT.ownerOf(2)).to.equal(await alice.getAddress());
    })

    it("should let bidder1 withdraw the highest bid", async () => {
      await piMarket.connect(bidder1).withdrawBidMoney(7, 1)
      result = await piMarket.Bids(7, 1);
      expect(result.withdrawn).to.equal(true)
    });

    it("should let alice place piNFT on auction", async () => {
      await piNFT.approve(piMarket.getAddress(), 2);
      await piMarket.SellNFT_byBid(
        piNFT.getAddress(),
        2,
        50000,
        300,
        "0x0000000000000000000000000000000000000000"
      );
      expect(await piNFT.ownerOf(2)).to.equal(await piMarket.getAddress());

      const result = await piMarket._tokenMeta(8);
      expect(result.bidSale).to.equal(true);
    });
  });

  describe("Swap NFTs", () => {
    it("should create a piNFT with 500 erc20 tokens to alice", async () => {
      await sampleERC20.mint(validator.getAddress(), 1000);
      await piNFT.mintNFT(alice.getAddress(), "URI2", [
        [royaltyReceiver.getAddress(), 500],
      ]);
      let tokenId = 3;
      const owner = await piNFT.ownerOf(tokenId);
      expect(owner).to.equal(await alice.getAddress());
      const bal = await piNFT.balanceOf(alice.getAddress());
      expect(bal).to.equal(2);

      let exp = new BN(await time.latest()).add(new BN(3600));
      // await time.increase(7501);

      await piNftMethods.addValidator(
        piNFT.getAddress(),
        tokenId,
        validator.getAddress()
      );
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
      await piNftMethods
        .connect(validator)
        .addERC20(
          piNFT.getAddress(),
          tokenId,
          sampleERC20.getAddress(),
          500,
          900,
          "uri",
          [[validator.getAddress(), 200]]
        );

      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        3
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(900);
    });

    it("should create a piNFT with 1000 erc20 tokens to bob", async () => {
      await sampleERC20.mint(validator.getAddress(), 1000);
      await piNFT.mintNFT(bob.getAddress(), "URI2", [
        [royaltyReceiver.getAddress(), 500],
      ]);
      let tokenId = 4;
      const owner = await piNFT.ownerOf(tokenId);
      expect(owner).to.equal(await bob.getAddress());
      const bal = await piNFT.balanceOf(bob.getAddress());
      expect(bal).to.equal(2);
      let exp = new BN(await time.latest()).add(new BN(3600));
      // await time.increase(7501);

      await piNftMethods
        .connect(bob)
        .addValidator(piNFT.getAddress(), tokenId, validator.getAddress());
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
      await piNftMethods
        .connect(validator)
        .addERC20(
          piNFT.getAddress(),
          tokenId,
          sampleERC20.getAddress(),
          500,
          900,
          "uri",
          [[validator.getAddress(), 200]]
        );

      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        4
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(900);
    });

    it("should create a piNFT again with 500 erc20 tokens to alice", async () => {
      await sampleERC20.mint(validator.getAddress(), 1000);
      await piNFT.mintNFT(alice.getAddress(), "URI2", [
        [royaltyReceiver.getAddress(), 500],
      ]);
      let tokenId = 5;
      const owner = await piNFT.ownerOf(tokenId);
      expect(owner).to.equal(await alice.getAddress());
      const bal = await piNFT.balanceOf(alice.getAddress());
      expect(bal).to.equal(3);

      await piNftMethods.addValidator(
        piNFT.getAddress(),
        tokenId,
        validator.getAddress()
      );
      let exp = new BN(await time.latest()).add(new BN(3600));
      // await time.increase(7501);
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
      await piNftMethods
        .connect(validator)
        .addERC20(
          piNFT.getAddress(),
          tokenId,
          sampleERC20.getAddress(),
          500,
          900,
          "uri",
          [[validator.getAddress(), 200]]
        );

      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        3
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(900);
    });

    it("should not allow initiating a swap if contract is paused", async () => {
      await piMarket.pause();

      await expect(
        piMarket.makeSwapRequest(
          piNFT.getAddress(),
          piNFT.getAddress(),
          3,
          4
        )
      ).to.be.revertedWith("Pausable: paused");

      await piMarket.unpause();
    });

    it("should not allow initiating a swap if caller is not token owner", async () => {
      await expect(
        piMarket.connect(bob).makeSwapRequest(
          piNFT.getAddress(),
          piNFT.getAddress(),
          3,
          4
        )
      ).to.be.revertedWith("Only token owner can execute");
    });

    it("should not allow initiating a swap if either contract address is 0", async () => {
      await expect(
        piMarket.connect(bob).makeSwapRequest(
          "0x0000000000000000000000000000000000000000",
          piNFT.getAddress(),
          3,
          4
        )
      ).to.be.revertedWithoutReason();

      await expect(
        piMarket.connect(bob).makeSwapRequest(
          piNFT.getAddress(),
          "0x0000000000000000000000000000000000000000",
          3,
          4
        )
      ).to.be.revertedWith("Only token owner can execute");
    });

    it("should not allow initiating a swap if caller is token2 owner", async () => {
      await expect(
        piMarket.makeSwapRequest(
          piNFT.getAddress(),
          piNFT.getAddress(),
          3,
          5
        )
      ).to.be.revertedWithoutReason();
    });

    it("should let alice initiate swap request", async () => {
      await piNFT.approve(piMarket.getAddress(), 3);

      await expect(
        piMarket.makeSwapRequest(
          piNFT.getAddress(),
          "0x0000000000000000000000000000000000000000",
          5,
          4
        )
      ).to.be.revertedWithoutReason();

      await expect(
        piMarket.makeSwapRequest(
          "0x0000000000000000000000000000000000000000",
          piNFT.getAddress(),
          5,
          4
        )
      ).to.be.revertedWithoutReason();

      await piMarket.makeSwapRequest(
        piNFT.getAddress(),
        piNFT.getAddress(),
        3,
        4
      );

      // let data = await piMarket._swaps(0);

      // expect(await data.initiator).to.equal(await alice.getAddress());

      expect(await piNFT.ownerOf(3)).to.equal(await piMarket.getAddress());
    });

    it("should let alice initiate swap request again", async () => {
      await piNFT.approve(piMarket.getAddress(), 5);
      await piMarket.makeSwapRequest(
        piNFT.getAddress(),
        piNFT.getAddress(),
        5,
        4
      );

      // let data = await piMarket._swaps(0);

      // expect(await data.initiator).to.equal(await alice.getAddress());

      expect(await piNFT.ownerOf(5)).to.equal(await piMarket.getAddress());
    });

    it("should cancel the swap if requested token owner has changed", async () => {
      await piNFT
        .connect(bob)
        .safeTransferFrom(bob.getAddress(), carl.getAddress(), 4);
      await piNFT.connect(carl).approve(piMarket.getAddress(), 4);

      await expect(
        piMarket.connect(carl).acceptSwapRequest(0)
      ).to.be.revertedWith("requesting token owner has changed");
      await piNFT
        .connect(carl)
        .safeTransferFrom(carl.getAddress(), bob.getAddress(), 4);
    });

    it("should not let an address that is not bob accept the swap request", async () => {
      await expect(
        piMarket.connect(carl).acceptSwapRequest(0)
      ).to.be.revertedWith("Only requested owner can accept swap");
    });

    it("should not allow accepting a swap if contract is paused", async () => {
      await piMarket.pause();
      await piNFT.connect(bob).approve(piMarket.getAddress(), 4);

      await expect(
        piMarket.connect(bob).acceptSwapRequest(0)
      ).to.be.revertedWith("Pausable: paused");

      await piMarket.unpause();
    });

    it("should let bob accept the swap request", async () => {
      await piNFT.connect(bob).approve(piMarket.getAddress(), 4);
      // let res = await piMarket._swaps(0);
      // expect(await res.status).to.equal(true);
      await piMarket.connect(bob).acceptSwapRequest(0);
      expect(await piNFT.ownerOf(3)).to.equal(await bob.getAddress());
      expect(await piNFT.ownerOf(4)).to.equal(await alice.getAddress());
      // res = await piMarket._swaps(0);
      // expect(await res.status).to.equal(false);
    });

    it("should not allow cancelling a swap if contract is paused", async () => {
      await piMarket.pause();

      await expect(
        piMarket.connect(alice).cancelSwap(1)
      ).to.be.revertedWith("Pausable: paused");

      await piMarket.unpause();
    });

    it("should not allow non initiator cancelling a swap", async () => {
      await expect(
        piMarket.connect(bob).cancelSwap(1)
      ).to.be.revertedWithoutReason();
    });

    it("should let alice cancel the swap request", async () => {
      // let res = await piMarket._swaps(1);
      // expect(await res.status).to.equal(true);
      await piMarket.connect(alice).cancelSwap(1);
      expect(await piNFT.ownerOf(5)).to.equal(await alice.getAddress());
      // res = await piMarket._swaps(1);
      // expect(await res.status).to.equal(false);
    });

    it("should not allow cancelling an already cancelled swap", async () => {
      await expect(
        piMarket.cancelSwap(1)
      ).to.be.revertedWithoutReason();
    });

    it("should let alice initiate swap request", async () => {
      await piNFT.approve(piMarket.getAddress(), 5);
      await piMarket.makeSwapRequest(
        piNFT.getAddress(),
        piNFT.getAddress(),
        5,
        3
      );

      // let data = await piMarket._swaps(2);

      // expect(await data.initiator).to.equal(await alice.getAddress());

      expect(await piNFT.ownerOf(5)).to.equal(await piMarket.getAddress());
    });

    it("should let alice cancle the swap request", async () => {
      // let res = await piMarket._swaps(2);
      // expect(await res.status).to.equal(true);
      await piMarket.connect(alice).cancelSwap(2);
      expect(await piNFT.ownerOf(5)).to.equal(await alice.getAddress());
      // res = await piMarket._swaps(2);
      // expect(await res.status).to.equal(false);
    });

    it("should not allow accepting a swap with a false status", async () => {
      await piNFT.connect(bob).approve(piMarket.getAddress(), 3);

      await expect(
        piMarket.connect(bob).acceptSwapRequest(2)
      ).to.be.revertedWithoutReason();
    });
  });



  describe("Sale Test", function () {
    it("should create a piNFT with 500 erc20 tokens to carl", async () => {
      await aconomyFee.connect(feeReceiver).setAconomyPiMarketFee(0);

      await sampleERC20.mint(validator.getAddress(), 1000);
      const tx1 = await piNFT.mintNFT(carl.getAddress(), "URI1", [
        [royaltyReceiver.getAddress(), 500],
      ]);

      const owner = await piNFT.ownerOf(6);
      expect(owner).to.equal(await carl.getAddress());
      const bal = await piNFT.balanceOf(carl);
      expect(bal).to.equal(1);
      let exp = new BN(await time.latest()).add(new BN(3600));
      // await time.increase(7501);

      await piNftMethods
        .connect(carl)
        .addValidator(piNFT.getAddress(), 6, validator.getAddress());
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
      const tx = await piNftMethods
        .connect(validator)
        .addERC20(piNFT.getAddress(), 6, sampleERC20.getAddress(), 500, 0, "uri", [
          [validator.getAddress(), 200],
        ]);

      const tokenBal = await piNftMethods.viewBalance(
        piNFT.getAddress(),
        6,
        sampleERC20.getAddress()
      );

      expect(tokenBal).to.equal(500);

      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        6
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(0);
    });

    it("should let carl transfer piNFT to alice", async () => {
      await piNFT
        .connect(carl)
        .safeTransferFrom(carl.getAddress(), alice.getAddress(), 6);
      expect(await piNFT.ownerOf(6)).to.equal(await alice.getAddress());
    });

    it("should let alice place piNFT on sale", async () => {
      await piNFT.approve(piMarket.getAddress(), 6);
      expect(await piNFT.ownerOf(6)).to.equal(await alice.getAddress());

      await expect(await piMarket.sellNFT(
        piNFT.getAddress(),
        6,
        50000,
        "0x0000000000000000000000000000000000000000"
      ))
      .to.emit(piMarket, "SaleCreated")
      .withArgs(6, await piNFT.getAddress(), 9, 0, 50000);



      let meta = await piMarket._tokenMeta(9);
      expect(meta.status).to.equal(true);
      expect(meta.bidSale).to.equal(false);

      expect(await piNFT.ownerOf(6)).to.equal(await piMarket.getAddress());
    });

    it("should let bob buy piNFT", async () => {
      let meta = await piMarket._tokenMeta(9);
      expect(meta.status).to.equal(true);
      expect(meta.bidSale).to.equal(false);

      await expect(
        piMarket.connect(bob).BuyNFT(9, false, { value: 5000 })
      ).to.be.revertedWithoutReason();

      result2 = await piMarket.connect(bob).BuyNFT(9, false, { value: 50000 });

      await expect(
        piMarket.connect(bob).BuyNFT(9, false, { value: 50000 })
      ).to.be.revertedWithoutReason();


      // await piMarket.connect(bob).BuyNFT(7, false, { value: 50000 });
      expect(await piNFT.ownerOf(6)).to.equal(await bob.getAddress());
    });

    it("should create a piNFT with 500 erc20 tokens to carl", async () => {
      await sampleERC20.mint(validator.getAddress(), 1000);
      const tx1 = await piNFT.mintNFT(carl.getAddress(), "URI1", [
        [royaltyReceiver.getAddress(), 500],
      ]);

      const owner = await piNFT.ownerOf(7);
      expect(owner).to.equal(await carl.getAddress());
      const bal = await piNFT.balanceOf(carl);
      expect(bal).to.equal(1);
      let exp = new BN(await time.latest()).add(new BN(3600));
      // await time.increase(7501);

      await piNftMethods
        .connect(carl)
        .addValidator(piNFT.getAddress(), 7, validator.getAddress());
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
      const tx = await piNftMethods
        .connect(validator)
        .addERC20(piNFT.getAddress(), 7, sampleERC20.getAddress(), 500, 0, "uri", [
          [validator.getAddress(), 200],
        ]);

      const tokenBal = await piNftMethods.viewBalance(
        piNFT.getAddress(),
        7,
        sampleERC20.getAddress()
      );

      expect(tokenBal).to.equal(500);

      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        7
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(0);
    });

    it("should let carl transfer piNFT to alice", async () => {
      await piNFT
        .connect(carl)
        .safeTransferFrom(carl.getAddress(), alice.getAddress(), 7);
      expect(await piNFT.ownerOf(7)).to.equal(await alice.getAddress());
    });

    it("should let alice place piNFT on sale", async () => {
      await piNFT.approve(piMarket.getAddress(), 7);
      expect(await piNFT.ownerOf(7)).to.equal(await alice.getAddress());

      await expect(await piMarket.SellNFT_byBid(
        piNFT.getAddress(),
        7,
        50000,
        300,
        "0x0000000000000000000000000000000000000000"
      ))

      .to.emit(piMarket, "SaleCreated")
      .withArgs(7, await piNFT.getAddress(), 10, 300, 50000);



      let meta = await piMarket._tokenMeta(10);
      expect(meta.status).to.equal(true);
      expect(meta.bidSale).to.equal(true);

      expect(await piNFT.ownerOf(7)).to.equal(await piMarket.getAddress());
    });

    it("should let bidders place bid on piNFT", async () => {
      await expect(
        piMarket.connect(alice).Bid(10, 60000, { value: 60000 })
      ).to.be.revertedWithoutReason();

      await expect(
        piMarket.connect(bidder1).Bid(10, 50000, { value: 50000 })
      ).to.be.revertedWithoutReason();

      await piMarket.connect(bidder1).Bid(10, 60000, { value: 60000 });
      await piMarket.connect(bidder2).Bid(10, 65000, { value: 65000 });
      await piMarket.connect(bidder1).Bid(10, 70000, { value: 70000 });

      result = await piMarket.Bids(10, 2);
      expect(result.buyerAddress).to.equal(await bidder1.getAddress());
    });

    it("should let alice execute bid order and not allow buying the NFT", async () => {
      let meta = await piMarket._tokenMeta(10);
      expect(meta.status).to.equal(true);
      expect(meta.bidSale).to.equal(true);

      await expect(piMarket.connect(bob).BuyNFT(10, false, { value: 70000 })).to.be.revertedWithoutReason()

      await piMarket.connect(alice).executeBidOrder(10, 2, false);
    });



    // ///////


    it("should create a piNFT with 500 erc20 tokens to carl", async () => {
      await aconomyFee.connect(feeReceiver).setAconomyPiMarketFee(0);

      await sampleERC20.mint(validator.getAddress(), 1000);
      const tx1 = await piNFT.mintNFT(carl.getAddress(), "URI1", [
        [royaltyReceiver.getAddress(), 500],
      ]);

      const owner = await piNFT.ownerOf(8);
      expect(owner).to.equal(await carl.getAddress());
      const bal = await piNFT.balanceOf(carl);
      expect(bal).to.equal(1);

      await piNftMethods
        .connect(carl)
        .addValidator(piNFT.getAddress(), 8, validator.getAddress());
        let exp = new BN(await time.latest()).add(new BN(3600));
      // await time.increase(7501);
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
      const tx = await piNftMethods
        .connect(validator)
        .addERC20(piNFT.getAddress(), 8, sampleERC20.getAddress(), 500, 0, "uri", [
          [validator.getAddress(), 200],
        ]);

      const tokenBal = await piNftMethods.viewBalance(
        piNFT.getAddress(),
        8,
        sampleERC20.getAddress()
      );

      expect(tokenBal).to.equal(500);

      let commission = await piNftMethods.validatorCommissions(
        piNFT.getAddress(),
        8
      );
      expect(commission.isValid).to.equal(true);
      expect(commission.commission.account).to.equal(
        await validator.getAddress()
      );
      expect(commission.commission.value).to.equal(0);
    });

    it("should let carl transfer piNFT to alice", async () => {
      await piNFT
        .connect(carl)
        .safeTransferFrom(carl.getAddress(), alice.getAddress(), 8);
      expect(await piNFT.ownerOf(8)).to.equal(await alice.getAddress());
    });

    it("should let alice place piNFT on sale", async () => {
      await piNFT.approve(piMarket.getAddress(), 8);
      expect(await piNFT.ownerOf(8)).to.equal(await alice.getAddress());

      await expect(await piMarket.sellNFT(
        piNFT.getAddress(),
        8,
        50000,
        "0x0000000000000000000000000000000000000000"
      ))
      .to.emit(piMarket, "SaleCreated")
      .withArgs(8, await piNFT.getAddress(), 11, 0, 50000);



      let meta = await piMarket._tokenMeta(11);
      expect(meta.status).to.equal(true);
      expect(meta.bidSale).to.equal(false);

      expect(await piNFT.ownerOf(8)).to.equal(await piMarket.getAddress());
    });

    it("should let alice cancel sale", async () => {
      await piMarket.cancelSale(11);
      meta = await piMarket._tokenMeta(11);
      expect(meta.status).to.equal(false);
    });

    it("should not let bidders place bid on piNFT", async () => {
      await expect(
        piMarket.connect(bidder1).Bid(11, 60000, { value: 60000 })
      ).to.be.revertedWithoutReason();
    });


    it("should let alice again put on sale", async () => {
      await piNFT.approve(piMarket.getAddress(), 8);
      expect(await piNFT.ownerOf(8)).to.equal(await alice.getAddress());

      await expect(await piMarket.SellNFT_byBid(
        piNFT.getAddress(),
        8,
        50000,
        300,
        "0x0000000000000000000000000000000000000000"
      ))
    });

    it("should let bidders place bid on piNFT", async () => {
      await expect(
        piMarket.connect(alice).Bid(12, 60000, { value: 60000 })
      ).to.be.revertedWithoutReason();

      await expect(
        piMarket.connect(bidder1).Bid(12, 50000, { value: 50000 })
      ).to.be.revertedWithoutReason();

      await piMarket.connect(bidder1).Bid(12, 60000, { value: 60000 });
      await piMarket.connect(bidder2).Bid(12, 65000, { value: 65000 });
      await piMarket.connect(bidder1).Bid(12, 70000, { value: 70000 });

      result = await piMarket.Bids(12, 2);
      expect(result.buyerAddress).to.equal(await bidder1.getAddress());
    });



    it("should let other bidders withdraw others bids", async () => {
      await piMarket.connect(bidder1).withdrawBidMoney(12, 0);

      await time.increase(400);

      await expect(
        piMarket.connect(bidder1).withdrawBidMoney(12, 1)
          ).to.be.revertedWithoutReason();
      await expect(
        piMarket.connect(bidder1).withdrawBidMoney(12, 0)
          ).to.be.revertedWithoutReason();

      });

    it("should let alice cancel sale", async () => {
      await piMarket.cancelSale(12);
      meta = await piMarket._tokenMeta(12);
      expect(meta.status).to.equal(false);
    });

    it("should not let bidders place bid on piNFT", async () => {
      await expect(
        piMarket.connect(bidder1).Bid(12, 60000, { value: 60000 })
      ).to.be.revertedWithoutReason();
    });



  })
  
});
