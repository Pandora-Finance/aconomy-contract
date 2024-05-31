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


        it("should not pause by non owner", async function() {
            await expect(
             ValidatorStake.connect(carl).pause()
            ).to.be.revertedWith("Ownable: caller is not the owner");

            // const details = await ValidatorStake.validatorStakes(bob);
            // expect(details.stakedAmount).to.equal("100000000000000000000");
        });




        it("should not Unpause by non owner", async function() {
            await expect(
             ValidatorStake.connect(carl).unpause()
            ).to.be.revertedWith("Ownable: caller is not the owner");

            // const details = await ValidatorStake.validatorStakes(bob);
            // expect(details.stakedAmount).to.equal("100000000000000000000");
        });

        it("should let validator add fund", async () => {
            await sampleERC20.mint(bob, "100000000000000000000");
            await sampleERC20.connect(bob).approve(await ValidatorStake.getAddress(), "100000000000000000000");
            const tx = await ValidatorStake.connect(bob).stake("100000000000000000000", await sampleERC20.getAddress());
            let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("100000000000000000000");

            const stakeDetail = await ValidatorStake.validatorStakes(bob.getAddress());
                expect(stakeDetail.stakedAmount).to.equal("100000000000000000000");
                expect(stakeDetail.refundedAmount).to.equal("0");
        });

        it("should let validator add more fund", async () => {
            await sampleERC20.mint(bob, "100000000000000000000");
            await sampleERC20.connect(bob).approve(await ValidatorStake.getAddress(), "100000000000000000000");
            const tx = await ValidatorStake.connect(bob).addStake("100000000000000000000", await sampleERC20.getAddress());
            let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("200000000000000000000");
            
            const stakeDetail = await ValidatorStake.validatorStakes(bob.getAddress());
                expect(stakeDetail.stakedAmount).to.equal("200000000000000000000");
                expect(stakeDetail.refundedAmount).to.equal("0");


        });

        it("should let validator RefundStake", async () => {
            await sampleERC20.mint(bob, "100000000000000000000");
            const tx = await ValidatorStake.refundStake(await bob.getAddress(), await sampleERC20.getAddress(), "100000000000000000000");
        
            await sampleERC20.connect(bob).approve(await ValidatorStake.getAddress(), "100000000000000000000");
            let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("100000000000000000000");
        
        });
        it("should prevent staking when paused", async function() {
            await ValidatorStake.pause();
            await expect(ValidatorStake.connect(bob).stake("50000000000000000000", await sampleERC20.getAddress()))
                .to.be.revertedWith("Pausable: paused");
            await ValidatorStake.unpause();
        });

        it("should allow a validator to stake funds", async function() {
            await sampleERC20.mint(bob, "100000000000000000000");
            await sampleERC20.connect(bob).approve(await ValidatorStake.getAddress(), "100000000000000000000");
            let bal = await sampleERC20.balanceOf(ValidatorStake);
            console.log("kkk",bal.toString());
            expect(bal).to.equal("100000000000000000000");

            await expect(ValidatorStake.connect(bob).stake("100000000000000000000", sampleERC20.getAddress()))
                .to.emit(ValidatorStake, 'Staked')
                .withArgs(bob.address,await sampleERC20.getAddress(),"100000000000000000000", "200000000000000000000", false);
                // expect(bal).to.equal("100000000000000000000");

                let bal1 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal1).to.equal("200000000000000000000");



                const stakeDetail = await ValidatorStake.validatorStakes(bob.getAddress());
                expect(stakeDetail.stakedAmount).to.equal("200000000000000000000");
                expect(stakeDetail.refundedAmount).to.equal("100000000000000000000");
        });

        it("should reject staking of zero amount", async function() {
            let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("200000000000000000000");
    
            await expect(ValidatorStake.connect(bob).stake(0, sampleERC20.getAddress()))
                .to.be.revertedWith("Low Amount");
        });

        it("should reject staking of zero address", async function() {

            let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("200000000000000000000");
    
            await expect(ValidatorStake.connect(bob).stake("100000000000000000000",  "0x0000000000000000000000000000000000000000"))
                .to.be.revertedWith("Zero Address");

                let bal1 = await sampleERC20.balanceOf(ValidatorStake);
                expect(bal1).to.equal("200000000000000000000");
    
    
    
                    const stakeDetail = await ValidatorStake.validatorStakes(bob.getAddress());
                    expect(stakeDetail.stakedAmount).to.equal("200000000000000000000");
                    expect(stakeDetail.refundedAmount).to.equal("100000000000000000000");
        });


        it("should not add stake when paused", async function() {
            await ValidatorStake.pause();
            await expect(ValidatorStake.connect(bob).addStake("50000000000000000000", await sampleERC20.getAddress()))
                .to.be.revertedWith("Pausable: paused");
            await ValidatorStake.unpause();
        });

        it("should not add stake with 0 amount", async function() {

            let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("200000000000000000000");
            await expect(ValidatorStake.connect(bob).addStake("0", await sampleERC20.getAddress()))
                .to.be.revertedWith("Low Amount");

                let bal1 = await sampleERC20.balanceOf(ValidatorStake);
                expect(bal1).to.equal("200000000000000000000");
    
    
    
                    const stakeDetail = await ValidatorStake.validatorStakes(bob.getAddress());
                    expect(stakeDetail.stakedAmount).to.equal("200000000000000000000");
                    expect(stakeDetail.refundedAmount).to.equal("100000000000000000000");

        });


        it("should not add stake with 0 _ERC20Address", async function() {
            await expect(ValidatorStake.connect(bob).addStake("50000000000000000000","0x0000000000000000000000000000000000000000"))
                .to.be.revertedWith("Zero Address");
        });

           
        it("should handle multiple stakes and keep correct total", async function() {
            await sampleERC20.mint(bob, "100000000000000000000");
            await sampleERC20.connect(bob).approve(await ValidatorStake.getAddress(), "100000000000000000000");
            await ValidatorStake.connect(bob).stake("50000000000000000000", sampleERC20.getAddress());
            await ValidatorStake.connect(bob).addStake("50000000000000000000", sampleERC20.getAddress());
            const details = await ValidatorStake.validatorStakes(bob.address);
            expect(details.stakedAmount).to.equal("300000000000000000000");

            let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("300000000000000000000");
    
        });

        it("should not allow the owner to refund stakes when paused", async function() {
            await ValidatorStake.pause();

            await expect(ValidatorStake.connect(alice).refundStake(bob.address, sampleERC20.getAddress(), "300000000000000000000"))
            .to.be.revertedWith("Pausable: paused");

               
                let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("300000000000000000000");
            await ValidatorStake.unpause();

    
        });

        it("should not allow the owner to refund stakes With 0 amount", async function() {

            await expect(ValidatorStake.connect(alice).refundStake(bob.address, sampleERC20.getAddress(), "0"))
            .to.be.revertedWith("Low Amount");

               
                let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("300000000000000000000");

    
        });

        it("should not allow the owner to refund stakes With 0 _ERC20Address", async function() {

            await expect(ValidatorStake.connect(alice).refundStake(bob.address, "0x0000000000000000000000000000000000000000", "300000000000000000000"))
            .to.be.revertedWith("Zero Address");

               
                let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("300000000000000000000");

    
        });


        it("should not allow the owner to refund stakes With 0 _validatorAddress", async function() {

            await expect(ValidatorStake.connect(alice).refundStake("0x0000000000000000000000000000000000000000",  sampleERC20.getAddress(), "300000000000000000000"))
            .to.be.revertedWith("Zero Address");

               
                let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("300000000000000000000");

    
        });




        it("should allow the owner to refund stakes", async function() {
            await expect(ValidatorStake.connect(alice).refundStake(bob.address, sampleERC20.getAddress(), "300000000000000000000"))
                .to.emit(ValidatorStake, 'RefundedStake')
                .withArgs(bob.address,await sampleERC20.getAddress(), "300000000000000000000","0");

                let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("0");
    
        });


        it("should allow a validator to stake funds again", async function() {
            await sampleERC20.mint(bob, "100000000000000000000");
            await sampleERC20.connect(bob).approve(await ValidatorStake.getAddress(), "100000000000000000000");
            let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("0");

            await expect(ValidatorStake.connect(bob).stake("100000000000000000000", sampleERC20.getAddress()))
                .to.emit(ValidatorStake, 'Staked')
                .withArgs(bob.address,await sampleERC20.getAddress(),"100000000000000000000", "100000000000000000000", false);

                let bal1 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal1).to.equal("100000000000000000000");



                const stakeDetail = await ValidatorStake.validatorStakes(bob.getAddress());
                expect(stakeDetail.stakedAmount).to.equal("100000000000000000000");
                expect(stakeDetail.refundedAmount).to.equal("400000000000000000000");
        });

        it("should not refunds by non owner", async function() {
            await expect(
             ValidatorStake.connect(carl).refundStake(bob,await sampleERC20.getAddress(), "50000000000")
            ).to.be.revertedWith("Ownable: caller is not the owner");

            const stakeDetail = await ValidatorStake.validatorStakes(bob.getAddress());
                expect(stakeDetail.stakedAmount).to.equal("100000000000000000000");
                expect(stakeDetail.refundedAmount).to.equal("400000000000000000000");
        });

        it("should manage multiple refunds correctly", async function() {
            await ValidatorStake.connect(alice).refundStake(bob.address, sampleERC20.getAddress(), "50000000000000000000");
            const details = await ValidatorStake.validatorStakes(bob.address);
            expect(details.stakedAmount).to.equal("50000000000000000000");
            await ValidatorStake.connect(alice).refundStake(bob.address, sampleERC20.getAddress(), "50000000000000000000");
            const stakeDetail = await ValidatorStake.validatorStakes(bob.address);
            expect(stakeDetail.stakedAmount).to.equal("0");
        });

        // describe("Upgrade Functionality", function () {
        //     it("should only allow owner to upgrade", async function () {
        //       const { ValidatorStake, carl } = await loadFixture(deployContractValidatorStake);
        //       await expect(ValidatorStake.connect(carl).upgradeTo(ethers.constants.AddressZero)).to.be.revertedWith("Ownable: caller is not the owner");
        //     });
        //   });


        // it("should revert if ERC20 transfer fails", async function () {
            
        //     await expect(ValidatorStake.refundStake(bob.address, sampleERC20.getAddress(),""))
        //         .to.be.revertedWith("Transfer failed");
        // });



        
//  it("should revert if ERC20 transfer fails during stake", async function () {

//                     await sampleERC20.mint(bob, "100000000000000000000");
//                     await sampleERC20.connect(bob).approve(await ValidatorStake.getAddress(), "100000000000000000000");
                    
//                     await expect(
//                         ValidatorStake.connect(bob).stake("100000000000000000000", await sampleERC20.getAddress(), false)
//                     ).to.be.revertedWith("Transfer failed");
//                 });
        

    });
});

