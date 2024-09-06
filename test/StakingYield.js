const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BN } = require("@openzeppelin/test-helpers");

const BigNumber = require("big-number");

describe("Staking Yield", function () {
  async function deployStakingYield() {
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

    const mintToken = await hre.ethers.deployContract("Aconomy", []);
    sampleERC20 = await mintToken.waitForDeployment();

    const mintToken1 = await hre.ethers.deployContract("Aconomy", []);
    newsampleERC20 = await mintToken1.waitForDeployment();

    const stakingyield = await hre.ethers.deployContract("StakingYield", [
      await sampleERC20.getAddress(),
    ]);
    stakingYield = await stakingyield.waitForDeployment();

    console.log("stakingYield : ", await stakingYield.getAddress());

    return {
      stakingYield,
      sampleERC20,
      newsampleERC20,
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

  describe("Staking Yield", function () {
    it("should deploy the contracts", async () => {
      let {
        stakingYield,
        sampleERC20,
        newsampleERC20,
        alice,
        validator,
        bob,
        carl,
        royaltyReceiver,
        feeReceiver,
        bidder1,
        bidder2,
        bidder3,
      } = await deployStakingYield();
    });

    it("should let owner set RewardsDuration for one year", async () => {
      await stakingYield.setRewardsDuration(31535975);
      // console.log("fee 111",await stakingYield.RewardTokens());
    });

    it("should let owner depositRewardToken with 6M", async () => {
      await sampleERC20.mint(alice, "6000000000000000000000000");

      await sampleERC20
        .connect(alice)
        .approve(await stakingYield.getAddress(), "6000000000000000000000000");
      await stakingYield.depositRewardToken("6000000000000000000000000");
      // await stakingYield.notifyRewardAmount("6000000000000000000000000");
      let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      console.log("fee 1", b1.toString());
    });

    it("should let owner notifyRewardAmount with 6M", async () => {
      // await sampleERC20.mint(alice, "6000000000000000000000000");

      // await sampleERC20.connect(alice).approve(await stakingYield.getAddress(), "6000000000000000000000000");
      // await stakingYield.depositRewardToken("6000000000000000000000000");
      await stakingYield.notifyRewardAmount("6000000000000000000000000");
      let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      console.log("fee 1", b1.toString());
    });

    it("should let stake 3 lacks token to contract for bob", async () => {
      await sampleERC20.mint(alice, "300000000000000000000000");
      await sampleERC20.approve(
        await stakingYield.getAddress(),
        "300000000000000000000000"
      );
      await stakingYield.stake(bob, "300000000000000000000000");

      // let b1 = await sampleERC20.balanceOf(bob);
      //     console.log("fee 1", );
      //     expect(await stakingYield.totalSupply()).to.equal("300000000000000000000000");
      const result = await stakingYield.balanceOf(bob);
      expect(result).to.equal("300000000000000000000000");
      const rs = await stakingYield.stakeTimestamps(bob);
      console.log("time", rs);
    });

    it("should let bob earned some tokens after 300 seconds", async () => {
      await time.increase(300);
      console.log("bob earned", await stakingYield.earned(bob));
    });

    it("should let owner stake 3 lacks token to contract for carl", async () => {
      await time.increase(30000);
      await sampleERC20.mint(alice, "300000000000000000000000");
      await sampleERC20.approve(
        await stakingYield.getAddress(),
        "300000000000000000000000"
      );
      await stakingYield.stake(carl, "300000000000000000000000");

      // let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      //   console.log("fee 1", b1);
      //   expect(await stakingYield.totalSupply()).to.equal("900000000000000000000000");
      const result = await stakingYield.balanceOf(carl);
      expect(result).to.equal("300000000000000000000000");
      //   console.log("time", result.StakingTime);
      const rs = await stakingYield.stakeTimestamps(carl);
      console.log("time", rs);
    });

    it("should let bob earned some tokens after 300 seconds", async () => {
      await time.increase(3000);
      console.log("carl earned", await stakingYield.earned(carl));
      console.log("bob earned", await stakingYield.earned(bob));
    });

    it("should let owner stake 3 lacks token to contract for new one", async () => {
      await time.increase(30000);
      await sampleERC20.mint(alice, "300000000000000000000000");
      await sampleERC20.approve(
        await stakingYield.getAddress(),
        "300000000000000000000000"
      );
      await stakingYield.stake(bidder1, "300000000000000000000000");

      // let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      //   console.log("fee 1", b1);
      //   expect(await stakingYield.totalSupply()).to.equal("900000000000000000000000");
      const result = await stakingYield.balanceOf(bidder1);
      expect(result).to.equal("300000000000000000000000");
      //   console.log("time", result.StakingTime);
      const rs = await stakingYield.stakeTimestamps(bidder1);
      console.log("time", rs);
    });

    it("should let bob earned some tokens after 300 seconds", async () => {
      await time.increase(3000);
      console.log("carl earned", await stakingYield.earned(carl));
      console.log("bob earned", await stakingYield.earned(bob));
      console.log("bidder1 earned", await stakingYield.earned(bidder1));
    });

    it("should not allow non owner to pause stakingYield contract", async () => {
      await expect(
        stakingYield.connect(royaltyReceiver).pause()
      ).to.be.revertedWith("Ownable: caller is not the owner");

      await stakingYield.pause();

      await expect(
        stakingYield.connect(royaltyReceiver).unpause()
      ).to.be.revertedWith("Ownable: caller is not the owner");

      await stakingYield.unpause();
    });

    it("should not allow call stake function when It's paused", async () => {
      await stakingYield.pause();

      await sampleERC20.approve(
        await stakingYield.getAddress(),
        "300000000000000000000000"
      );
      await expect(
        stakingYield.stake(bidder1, "300000000000000000000000")
      ).to.be.revertedWith("Pausable: paused");
      await stakingYield.unpause();
    });

    it("should not allow call depositRewardToken function when It's paused", async () => {
      await stakingYield.pause();

      await sampleERC20.approve(
        await stakingYield.getAddress(),
        "300000000000000000000000"
      );
      await expect(
        stakingYield.depositRewardToken("300000000000000000000000")
      ).to.be.revertedWith("Pausable: paused");
      await stakingYield.unpause();
    });

    it("should not allow call notifyRewardAmount function when It's paused", async () => {
      await stakingYield.pause();

      // await sampleERC20.approve(await stakingYield.getAddress(), "300000000000000000000000");
      await expect(
        stakingYield.notifyRewardAmount("300000000000000000000000")
      ).to.be.revertedWith("Pausable: paused");
      await stakingYield.unpause();
    });

    it("should let bob earned some tokens after 300 seconds", async () => {
      await time.increase(3000);
      console.log("bob earned", await stakingYield.earned(bob));
      console.log("carl earned", await stakingYield.earned(carl));
      console.log("bidder1 earned", await stakingYield.earned(bidder1));
    });

    it("should let not bob withdraw Tokens If permission is not granted", async () => {
      await expect(stakingYield.connect(bob).withdraw()).to.be.revertedWith(
        "Permission Denied"
      );
    });

    it("should not let non owner give the permission to bob for withdraw", async () => {
      await expect(
        stakingYield.connect(bob).withdrawPermission(bob, true)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should not let owner give the permission to bob for withdraw if It's paused", async () => {
      await stakingYield.pause();

      // await sampleERC20.approve(await stakingYield.getAddress(), "300000000000000000000000");
      await expect(
        stakingYield.withdrawPermission(bob, true)
      ).to.be.revertedWith("Pausable: paused");
      await stakingYield.unpause();
    });

    it("should let owner give the permission to bob for withdraw", async () => {
      await stakingYield.withdrawPermission(bob, true);
    });

    it("should let not bob withdraw Tokens within 6 months", async () => {
      await expect(stakingYield.connect(bob).withdraw()).to.be.revertedWith(
        "Can't withdraw tokens within one Year"
      );
    });

    it("should let bob withdraw amount before 1 year", async () => {
      console.log("time", await time.latest());
      console.log("bob time", await stakingYield.stakeTimestamps(bob));
      await time.increase(31556926);

      let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      console.log("fee 1", b1.toString());
      expect(b1).to.equal("6900000000000000000000000");

      let b3 = await sampleERC20.balanceOf(bob);
      console.log("fee 2", b3.toString());
      expect(b3).to.equal("0");

      await stakingYield.connect(bob).withdraw();
      let b2 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      console.log("fee 3", b2.toString());
      expect(b2).to.equal("6600000000000000000000000");

      let b4 = await sampleERC20.balanceOf(bob);
      console.log("fee 4", b4.toString());
      expect(b4).to.equal("150000000000000000000000");
    });

    it("should let bob earned some tokens after 300 seconds", async () => {
      // await time.increase(3000);
      console.log("bob earned", await stakingYield.earned(bob));
      console.log("carl earned", await stakingYield.earned(carl));
      console.log("bidder1 earned", await stakingYield.earned(bidder1));
    });

    // it("should let bob reward should be same after withdraw", async () => {
    //   console.log("bob earned", await stakingYield.earned(bob));
    //   const b = await stakingYield.earned(bob);
    //   await time.increase(30000);
    //   const b1 = await stakingYield.earned(bob);
    //   console.log("bob earned", await stakingYield.earned(bob));
    //   expect(b).to.equal(b1);
    //   console.log("carl earned", await stakingYield.earned(carl));
    //   console.log("bidder1 earned", await stakingYield.earned(bidder1));
    // });

    it("should let carl withdraw amount after 1 year", async () => {
      console.log("time", await time.latest());
      console.log("bob time", await stakingYield.stakeTimestamps(bob));
      // await time.increase(31556951);
      let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      console.log("fee 1", b1.toString());
      expect(b1).to.equal("6600000000000000000000000");

      let b3 = await sampleERC20.balanceOf(carl);
      console.log("fee 2", b3.toString());
      expect(b3).to.equal("0");

      await stakingYield.withdrawPermission(carl, true);

      await stakingYield.connect(carl).withdraw();
      let b2 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      console.log("fee 3", b2.toString());
      expect(b2).to.equal("6300000000000000000000000");

      let b4 = await sampleERC20.balanceOf(carl);
      console.log("fee 4", b4.toString());
      expect(b4).to.equal("150000000000000000000000");
    });

    it("should let bidder withdraw amount after 2 years and before 3 years", async () => {
      console.log("time", await time.latest());
      console.log("bob time", await stakingYield.stakeTimestamps(bidder1));
      await time.increase(31556951);
      let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      console.log("fee 1", b1.toString());
      expect(b1).to.equal("6300000000000000000000000");

      let b3 = await sampleERC20.balanceOf(bidder1);
      console.log("fee 2", b3.toString());
      expect(b3).to.equal("0");

      await stakingYield.withdrawPermission(bidder1, true);

      await stakingYield.connect(bidder1).withdraw();
      let b2 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      console.log("fee 3", b2.toString());
      expect(b2).to.equal("6000000000000000000000000");

      let b4 = await sampleERC20.balanceOf(bidder1);
      console.log("fee 4", b4.toString());
      expect(b4).to.equal("225000000000000000000000");
    });

    it("should let not carl withdraw any amount again", async () => {
      await time.increase(31556951);
      let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      console.log("fee 1", b1.toString());
      expect(b1).to.equal("6000000000000000000000000");

      let b3 = await sampleERC20.balanceOf(carl);
      console.log("fee 2", b3.toString());
      expect(b3).to.equal("150000000000000000000000");

      await stakingYield.connect(carl).withdraw();
      let b2 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      console.log("fee 3", b2.toString());
      expect(b2).to.equal("6000000000000000000000000");

      let b4 = await sampleERC20.balanceOf(carl);
      console.log("fee 4", b4.toString());
      expect(b4).to.equal("150000000000000000000000");
    });

    it("should let carl withdraw his reward", async () => {
      const carlbal = await stakingYield.earned(carl);
      console.log("carl earned", await stakingYield.earned(carl));
      await time.increase(31556951);
      const carlbal1 = await stakingYield.earned(carl);
      expect(carlbal).to.equal(carlbal1);
      let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      console.log("fee 1", b1.toString());
      expect(b1).to.equal("6000000000000000000000000");
      // (b1-carlbal).toString()

      let b3 = await sampleERC20.balanceOf(carl);
      console.log("fee 2", b3.toString());
      expect(b3).to.equal("150000000000000000000000");

      await stakingYield.connect(carl).getReward();
      let b2 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      console.log("fee 3", b2.toString());
      expect(b2).to.equal((b1 - carlbal).toString());

      let b4 = await sampleERC20.balanceOf(carl);
      console.log("fee 4", b4.toString());
      expect(b4).to.equal((b3 + carlbal).toString());
    });

    it("should let bidder2 stake 6 lacks token to contract", async () => {
      await sampleERC20.mint(alice, "600000000000000000000000");
      await sampleERC20.approve(
        await stakingYield.getAddress(),
        "600000000000000000000000"
      );
      await stakingYield.stake(bidder2, "600000000000000000000000");

      const result = await stakingYield.balanceOf(bidder2);
      expect(result).to.equal("600000000000000000000000");
      const rs = await stakingYield.stakeTimestamps(bidder2);
      console.log("time", rs);
    });

    it("should let bidder2 withdraw amount 3 years", async () => {
      await time.increase(31556952 * 3);

      let b3 = await sampleERC20.balanceOf(bidder2);
      console.log("fee 2", b3.toString());
      expect(b3).to.equal("0");

      await stakingYield.withdrawPermission(bidder2, true);

      await stakingYield.connect(bidder2).withdraw();

      let b4 = await sampleERC20.balanceOf(bidder2);
      console.log("fee 4", b4.toString());
      expect(b4).to.equal("600000000000000000000000");
    });

    it("should let not non owner emergency withdraw", async () => {
      let b2 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      await expect(
        stakingYield.connect(royaltyReceiver).recoverERC20(alice, b2)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should let owner emergency withdraw", async () => {
      let b2 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      console.log("fee 4", b2.toString());
      await stakingYield.recoverERC20(royaltyReceiver, b2);
      let b4 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      expect(b4).to.equal("0");

      let b5 = await sampleERC20.balanceOf(royaltyReceiver);
      expect(b5).to.equal(b2);
    });
  });
});
