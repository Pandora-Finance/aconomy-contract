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
      royaltyReciever,
      feeReceiver,
      bidder1,
      bidder2,
    ] = await ethers.getSigners();

    const aconomyFee = await hre.ethers.deployContract("AconomyFee", []);
    await aconomyFee.waitForDeployment();

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
    const piNftMethods = await upgrades.deployProxy(
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
    const piNFT = await upgrades.deployProxy(
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
    const piMarket = await upgrades.deployProxy(
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
      royaltyReciever,
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
        royaltyReciever,
        feeReceiver,
        bidder1,
        bidder2,
      } = await deploypiMarket();

      console.log("jgvhg", await aconomyFee.getAddress());
    });

    it("should create a piNFT with 500 erc20 tokens to carl", async () => {
      console.log("jgqqqqqqqvhg", await sampleERC20.getAddress());

      console.log("jgqqqqqqqq1111vhg", await validator.getAddress());

      // await aconomyFee.setAconomyPiMarketFee(100);
      // await aconomyFee.transferOwnership(feeReceiver.getAddress());
      await sampleERC20.mint(validator.getAddress(), 1000);
      const tx1 = await piNFT.mintNFT(carl.getAddress(), "URI1", [
        [royaltyReceiver.getAddress(), 500],
      ]);

      const owner = await piNFT.ownerOf(0);
      // console.log("dhvdh",alice.getAddress())
      expect(owner).to.equal(await alice.getAddress());
      const bal = await piNFT.balanceOf(alice);
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
      expect(commission.commission.account).to.equal(validator.getAddress());
      expect(commission.commission.value).to.equal(1000);
    });
  });
});
