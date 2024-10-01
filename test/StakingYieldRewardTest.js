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
      "0x37a6F444c6b3A42fA37476bB1Ed79F567b26b82D",
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

    it("should let owner set RewardsDuration for one Day", async () => {
      await stakingYield.setRewardsDuration(86400);
    });

    it("should let owner depositRewardToken with 100 Token", async () => {
      await sampleERC20.mint(alice, "100000000000000000000");

      await sampleERC20
        .connect(alice)
        .approve(await stakingYield.getAddress(), "100000000000000000000");
      await stakingYield.depositRewardToken("100000000000000000000");
      let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
      console.log("fee 1", b1.toString());
    });

    

    it("should let stake 50 token to contract for bob", async () => {
        // await time.increase(43200);
      await sampleERC20.mint(alice, "50000000000000000000");
      await sampleERC20.approve(
        await stakingYield.getAddress(),
        "50000000000000000000"
      );
      await stakingYield.stake(bob, "50000000000000000000");

      const result = await stakingYield.balanceOf(bob);
      expect(result).to.equal("50000000000000000000");
      const rs = await stakingYield.stakeTimestamps(bob);
      console.log("time", rs);
    });

    it("should let owner notifyRewardAmount with 6M", async () => {
        await stakingYield.notifyRewardAmount("100000000000000000000");
        let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
        console.log("fee 1", b1.toString());
      });

    it("should let bob earned some tokens after 300 seconds", async () => {
        await time.increase(86410);
        console.log("bob earned", (await stakingYield.earned(bob)).toString());
      });

    //   it("should let carl withdraw his reward", async () => {
        
    //     let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
    //     console.log("fee 1", b1.toString());

    //     await stakingYield.connect(bob).getReward();
    //     let b2 = await sampleERC20.balanceOf(await stakingYield.getAddress());
    //     console.log("fee 3", b2.toString());
    //     // expect(b2).to.equal((b1 - carlbal).toString());
  
    //     let b4 = await sampleERC20.balanceOf(bob);
    //     console.log("fee 4", b4.toString());
    //     // expect(b4).to.equal((b3 + carlbal).toString());
    //   });


      it("should let owner set RewardsDuration for one Day", async () => {
        await stakingYield.setRewardsDuration(86400);
      });
  
      it("should let owner depositRewardToken with 100 Token", async () => {
        await sampleERC20.mint(alice, "100000000000000000000");
  
        await sampleERC20
          .connect(alice)
          .approve(await stakingYield.getAddress(), "100000000000000000000");
        await stakingYield.depositRewardToken("100000000000000000000");
        let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
        console.log("fee 1", b1.toString());
      });

      it("should let owner notifyRewardAmount with 6M", async () => {
        await stakingYield.notifyRewardAmount("100000000000000000000");
        let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
        console.log("fee 1", b1.toString());
      });

      it("should let bob earned some tokens after 300 seconds", async () => {
        await time.increase(86410);
        console.log("bob earned", (await stakingYield.earned(bob)).toString());
      });

  });
});
