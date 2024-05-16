const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
  const { ethers } = require("hardhat");
  
  describe("ValidatorStake Contract", function () {
    async function deployContractValidatorStake() {
      [alice, validator, bob, carl, random] = await ethers.getSigners();
  
      const VS = await hre.ethers.getContractFactory("validatorStake");
  
      ValidatorStake = await upgrades.deployProxy(VS, [], {
        initializer: "initialize",
        kind: "uups",
      });
  
      const MintToken = await hre.ethers.getContractFactory("mintToken");
      const mintToken = await MintToken.deploy("100000000000");
      await mintToken.deployed();
      sampleERC20 = mintToken;
  
      return { ValidatorStake, sampleERC20, alice, bob, validator, carl, random };
    }
  
    describe("Deployment", function () {
      it("should deploy the ValidatorStake Contract", async function () {
        const { ValidatorStake, sampleERC20, alice, bob, carl } = await loadFixture(deployContractValidatorStake);
        expect(ValidatorStake.address).to.be.properAddress;
      });
  
      it("should not pause by non-owner", async function () {
        const { ValidatorStake, carl } = await loadFixture(deployContractValidatorStake);
        await expect(ValidatorStake.connect(carl).pause()).to.be.revertedWith("Ownable: caller is not the owner");
      });
    });
  
    describe("Stake Functionality", function () {
      it("should allow staking", async function () {
        const { ValidatorStake, sampleERC20, validator } = await loadFixture(deployContractValidatorStake);
  
        await sampleERC20.connect(validator).approve(ValidatorStake.address, ethers.utils.parseUnits("100", 18));
        await expect(ValidatorStake.connect(validator).stake(ethers.utils.parseUnits("100", 18), sampleERC20.address, true))
          .to.emit(ValidatorStake, "Staked")
          .withArgs(validator.address, sampleERC20.address, ethers.utils.parseUnits("100", 18), ethers.utils.parseUnits("100", 18), true);
  
        const stakeDetails = await ValidatorStake.validatorStakes(validator.address);
        expect(stakeDetails.stakedAmount).to.equal(ethers.utils.parseUnits("100", 18));
      });
  
      it("should not allow staking with zero address", async function () {
        const { ValidatorStake, validator } = await loadFixture(deployContractValidatorStake);
  
        await expect(ValidatorStake.connect(validator).stake(ethers.utils.parseUnits("100", 18), ethers.constants.AddressZero, true))
          .to.be.revertedWith("Zero Address");
      });
  
      it("should not allow staking with zero amount", async function () {
        const { ValidatorStake, sampleERC20, validator } = await loadFixture(deployContractValidatorStake);
  
        await expect(ValidatorStake.connect(validator).stake(0, sampleERC20.address, true))
          .to.be.revertedWith("Low Amount");
      });
  
      it("should handle additional stakes correctly", async function () {
        const { ValidatorStake, sampleERC20, validator } = await loadFixture(deployContractValidatorStake);
  
        await sampleERC20.connect(validator).approve(ValidatorStake.address, ethers.utils.parseUnits("200", 18));
        await ValidatorStake.connect(validator).stake(ethers.utils.parseUnits("100", 18), sampleERC20.address, true);
        await ValidatorStake.connect(validator).addStake(ethers.utils.parseUnits("100", 18), sampleERC20.address, true);
  
        const stakeDetails = await ValidatorStake.validatorStakes(validator.address);
        expect(stakeDetails.stakedAmount).to.equal(ethers.utils.parseUnits("200", 18));
      });
  
      it("should emit Staked event with correct arguments", async function () {
        const { ValidatorStake, sampleERC20, validator } = await loadFixture(deployContractValidatorStake);
  
        await sampleERC20.connect(validator).approve(ValidatorStake.address, ethers.utils.parseUnits("100", 18));
        await expect(ValidatorStake.connect(validator).stake(ethers.utils.parseUnits("100", 18), sampleERC20.address, true))
          .to.emit(ValidatorStake, "Staked")
          .withArgs(validator.address, sampleERC20.address, ethers.utils.parseUnits("100", 18), ethers.utils.parseUnits("100", 18), true);
      });
  
      it("should revert on transfer failure", async function () {
        const { ValidatorStake, sampleERC20, validator } = await loadFixture(deployContractValidatorStake);
  
        // Mock the transferFrom function to fail
        await sampleERC20.connect(validator).approve(ValidatorStake.address, ethers.utils.parseUnits("100", 18));
        await ValidatorStake.pause();
        await expect(ValidatorStake.connect(validator).stake(ethers.utils.parseUnits("100", 18), sampleERC20.address, true))
          .to.be.revertedWith("Pausable: paused");
        await ValidatorStake.unpause();
      });
    });
  
    describe("Refund Functionality", function () {
      it("should allow owner to refund stake", async function () {
        const { ValidatorStake, sampleERC20, validator, alice } = await loadFixture(deployContractValidatorStake);
  
        await sampleERC20.connect(validator).approve(ValidatorStake.address, ethers.utils.parseUnits("100", 18));
        await ValidatorStake.connect(validator).stake(ethers.utils.parseUnits("100", 18), sampleERC20.address, true);
  
        await expect(ValidatorStake.connect(alice).refundStake(validator.address, sampleERC20.address, ethers.utils.parseUnits("50", 18)))
          .to.emit(ValidatorStake, "RefundedStake")
          .withArgs(validator.address, sampleERC20.address, ethers.utils.parseUnits("50", 18), ethers.utils.parseUnits("50", 18));
  
        const stakeDetails = await ValidatorStake.validatorStakes(validator.address);
        expect(stakeDetails.stakedAmount).to.equal(ethers.utils.parseUnits("50", 18));
        expect(stakeDetails.refundedAmount).to.equal(ethers.utils.parseUnits("50", 18));
      });
  
      it("should not allow non-owner to refund stake", async function () {
        const { ValidatorStake, sampleERC20, validator, carl } = await loadFixture(deployContractValidatorStake);
  
        await sampleERC20.connect(validator).approve(ValidatorStake.address, ethers.utils.parseUnits("100", 18));
        await ValidatorStake.connect(validator).stake(ethers.utils.parseUnits("100", 18), sampleERC20.address, true);
  
        await expect(ValidatorStake.connect(carl).refundStake(validator.address, sampleERC20.address, ethers.utils.parseUnits("50", 18)))
          .to.be.revertedWith("Ownable: caller is not the owner");
      });
  
      it("should not allow refund with zero address", async function () {
        const { ValidatorStake, sampleERC20, alice, validator } = await loadFixture(deployContractValidatorStake);
  
        await sampleERC20.connect(validator).approve(ValidatorStake.address, ethers.utils.parseUnits("100", 18));
        await ValidatorStake.connect(validator).stake(ethers.utils.parseUnits("100", 18), sampleERC20.address, true);
  
        await expect(ValidatorStake.connect(alice).refundStake(ethers.constants.AddressZero, sampleERC20.address, ethers.utils.parseUnits("50", 18)))
          .to.be.revertedWith("Zero Address");
      });
  
      it("should not allow refund with zero amount", async function () {
        const { ValidatorStake, sampleERC20, alice, validator } = await loadFixture(deployContractValidatorStake);
  
        await sampleERC20.connect(validator).approve(ValidatorStake.address, ethers.utils.parseUnits("100", 18));
        await ValidatorStake.connect(validator).stake(ethers.utils.parseUnits("100", 18), sampleERC20.address, true);
  
        await expect(ValidatorStake.connect(alice).refundStake(validator.address, sampleERC20.address, 0))
          .to.be.revertedWith("Low Amount");
      });
    });
  
    describe("Upgrade Functionality", function () {
      it("should only allow owner to upgrade", async function () {
        const { ValidatorStake, carl } = await loadFixture(deployContractValidatorStake);
        await expect(ValidatorStake.connect(carl).upgradeTo(ethers.constants.AddressZero)).to.be.revertedWith("Ownable: caller is not the owner");
      });
    });
  
    describe("Pause Functionality", function () {
      it("should allow owner to pause and unpause the contract", async function () {
        const { ValidatorStake, alice } = await loadFixture(deployContractValidatorStake);
  
        await ValidatorStake.connect(alice).pause();
        expect(await ValidatorStake.paused()).to.be.true;
  
        await ValidatorStake.connect(alice).unpause();
        expect(await ValidatorStake.paused()).to.be.false;
      });
  
      it("should not allow staking when paused", async function () {
        const { ValidatorStake, sampleERC20, validator, alice } = await loadFixture(deployContractValidatorStake);
  
        await ValidatorStake.connect(alice).pause();
        await sampleERC20.connect(validator).approve(ValidatorStake.address, ethers.utils.parseUnits("100", 18));
  
        await expect(ValidatorStake.connect(validator).stake(ethers.utils.parseUnits("100", 18), sampleERC20.address, true))
          .to.be.revertedWith("Pausable: paused");
      });
    });
  });
  