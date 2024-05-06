const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
  const { ethers } = require("hardhat");
  const moment = require("moment");
  const { BN } = require("@openzeppelin/test-helpers");

describe("Validator fund stake", function() {
    async function deployContractValidatorStake() {

        [alice, validator, bob, royaltyReceiver, carl, random, newFeeAddress] = await ethers.getSigners();

        const VS = await hre.ethers.getContractFactory("validatorStake")

          ValidatorStake = await upgrades.deployProxy(VS, [], {
            initializer: "initialize",
            kind: "uups",
          })

          const mintToken = await hre.ethers.deployContract("mintToken", ["100000000000"]);
    sampleERC20 = await mintToken.waitForDeployment();

          console.log("deployment", await ValidatorStake.getAddress())

          return { ValidatorStake, sampleERC20, alice, bob, carl };
    }



    describe("Deployment", function () {
        it("should deploy the ValidatorStake Contract", async () => {
            let {ValidatorStake, sampleERC20, alice, bob, carl} = await deployContractValidatorStake()
        });

        it("should let validator add fund", async () => {
            await sampleERC20.mint(bob, "100000000000000000000");
            await sampleERC20.connect(bob).approve(await ValidatorStake.getAddress(), "100000000000000000000");
            const tx = await ValidatorStake.connect(bob).Stake("100000000000000000000", await sampleERC20.getAddress());
        });

        it("should let validator add more fund", async () => {
            await sampleERC20.mint(bob, "100000000000000000000");
            await sampleERC20.connect(bob).approve(await ValidatorStake.getAddress(), "100000000000000000000");
            const tx = await ValidatorStake.connect(bob).addStake("100000000000000000000", await sampleERC20.getAddress());
        });

        it("should let validator add more fund", async () => {
            await sampleERC20.mint(bob, "100000000000000000000");
            const tx = await ValidatorStake.RefundStake(await bob.getAddress(), await sampleERC20.getAddress(), "100000000000000000000");
        });
    })
})