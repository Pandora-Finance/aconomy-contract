const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

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

    console.log("AconomyFee : ", await aconomyFee.getAddress());
    console.log("CollectionMethods : ", await CollectionMethod.getAddress());
    console.log("CollectionFactory : ", await collectionFactory.getAddress());
    console.log("mintToken : ", await sampleERC20.getAddress());
    console.log("piNFT: ", await piNFT.getAddress());
    console.log("piNFTMethods", await piNftMethods.getAddress());
    console.log("piMarket:", await piMarket.getAddress());

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
      } = await deploypiMarket();
    });

    it("should create a piNFT with 500 erc20 tokens to carl", async () => {
      await aconomyFee.setAconomyPiMarketFee(100);
      await aconomyFee.transferOwnership(feeReceiver.getAddress());
      await sampleERC20.mint(validator.getAddress(), 1000);
      const tx1 = await piNFT.mintNFT(carl.getAddress(), "URI1", [
        [royaltyReceiver.getAddress(), 500],
      ]);

      const owner = await piNFT.ownerOf(0);
      // console.log("dhvdh",alice.getAddress())
      expect(owner).to.equal(await carl.getAddress());
      const bal = await piNFT.balanceOf(carl);
      expect(bal).to.equal(1);

      await piNftMethods
        .connect(carl)
        .addValidator(piNFT.getAddress(), 0, validator.getAddress());
      await sampleERC20
        .connect(validator)
        .approve(piNftMethods.getAddress(), 500);
      const tx = await piNftMethods
        .connect(validator)
        .addERC20(piNFT.getAddress(), 0, sampleERC20.getAddress(), 500, 1000, [
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
      await piNFT.connect(carl).safeTransferFrom(carl.getAddress(), alice.getAddress(), 0);
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
    })

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
    })

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


    it("should edit the price after listing on sale", async () => {
      await piMarket.connect(alice).editSalePrice(1, 60000);
      await expect(
        piMarket.connect(bob).editSalePrice(1, 60000)
      ).to.be.revertedWith("You are not the owner");

      await expect(
        piMarket.connect(alice).editSalePrice(1, 60)
      ).to.be.revertedWithoutReason();
      let meta = await piMarket._tokenMeta(1);
      let price = meta.price;
      expect(price).to.equal(60000);
      await piMarket.connect(alice).editSalePrice(1, 50000);
      let newmeta = await piMarket._tokenMeta(1);
      expect(newmeta.price).to.equal(50000);
    });

    it("should not let seller buy their own nft", async () => {
      await expect(
        piMarket.connect(alice).BuyNFT(1, false, {  value: 50000 })
      ).to.be.revertedWithoutReason();
    })

    it("should let bob buy piNFT", async () => {
      let meta = await piMarket._tokenMeta(1);
      expect(meta.status).to.equal(true);
      // assert.equal(meta.status, true);
      alice.getBalance();

      // let _balance1 = await alice.getBalance();
      const contractBalance = await ethers.provider.getBalance(alice.getAddress())
      // let _balance2 = await royaltyReceiver.getBalance();
      // let _balance3 = await feeReceiver.getBalance();
      // let _balance4 = await validator.getBalance();

      result2 = await piMarket.connect(bob).BuyNFT(1, false, { value: 50000 });
      // console.log(result2.receipt.rawLogs)
      // assert.equal(await piNFT.ownerOf(0), bob);

      // //validator 200
      // //royalties 500
      // //fee 50

      // let balance1 = await web3.eth.getBalance(alice);
      // let balance2 = await web3.eth.getBalance(royaltyReceiver);
      // let balance3 = await web3.eth.getBalance(feeReceiver);
      // let balance4 = await web3.eth.getBalance(validator);
      // let temp = BigNumber(balance1).minus(BigNumber(_balance1));
      // // console.log(balance1, " ", _balance1, " ", temp.toString());
      // assert.equal(
      //   BigNumber(balance1).minus(BigNumber(_balance1)),
      //   (50000 * 8200) / 10000,
      //   "Failed to transfer NFT amount"
      // );

      // assert.equal(
      //   BigNumber(balance2).minus(BigNumber(_balance2)),
      //   (50000 * 500) / 10000,
      //   "Failed to transfer royalty amount"
      // );

      // // console.log(Number(web3.utils.toBN(balance2)-(web3.utils.toBN(_balance2))))

      // // console.log(Number(BigNumber(balance3).minus(BigNumber(_balance3))));
      // assert.equal(
      //   BigNumber(balance3).minus(BigNumber(_balance3)),
      //   (50000 * 100) / 10000,
      //   "Failed to transfer fee amount"
      // );

      // assert.equal(
      //   BigNumber(balance4).minus(BigNumber(_balance4)),
      //   (50000 * 1200) / 10000,
      //   "Failed to transfer validator amount"
      // );

      // meta = await piMarket._tokenMeta(1);
      // assert.equal(meta.status, false);
      // let commission = await piNftMethods.validatorCommissions(piNFT.address, 0);
      // assert(commission.isValid == false);
      // assert(commission.commission.account == validator);
      // assert(commission.commission.value == 1000);
    });







  });
});
