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
                let bal1 = await sampleERC20.balanceOf(bob);
            expect(bal1).to.equal("0");
        });


        it("should not let same validator stake again", async () => {

            let bal1 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal1).to.equal("100000000000000000000");
            await expect(ValidatorStake.connect(bob).stake("100000000000000000000", await sampleERC20.getAddress()))
            .to.be.revertedWith("more than one time");
            let bal2 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal2).to.equal("100000000000000000000");

            const stakeDetail = await ValidatorStake.validatorStakes(bob.getAddress());
                expect(stakeDetail.stakedAmount).to.equal("100000000000000000000");
                expect(stakeDetail.refundedAmount).to.equal("0");
                let bal3 = await sampleERC20.balanceOf(bob);
                expect(bal3).to.equal("0");
        });

        it("should let validator add more fund", async () => {
            await sampleERC20.mint(bob, "100000000000000000000");
            await sampleERC20.connect(bob).approve(await ValidatorStake.getAddress(), "100000000000000000000");
            const tx = await ValidatorStake.connect(bob).addStake("100000000000000000000", await sampleERC20.getAddress());
            let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("200000000000000000000");
            let bal2 = await sampleERC20.balanceOf(bob);
            expect(bal2).to.equal("0");
            
            const stakeDetail = await ValidatorStake.validatorStakes(bob.getAddress());
                expect(stakeDetail.stakedAmount).to.equal("200000000000000000000");
                expect(stakeDetail.refundedAmount).to.equal("0");


        });

        it("should let validator RefundStake", async () => {
            await sampleERC20.mint(bob, "100000000000000000000");
            let bal3 = await sampleERC20.balanceOf(bob);
            expect(bal3).to.equal("100000000000000000000");
            const tx = await ValidatorStake.refundStake(await bob.getAddress(), await sampleERC20.getAddress(), "200000000000000000000");
                    let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("0");

            let bal1 = await sampleERC20.balanceOf(bob);
            expect(bal1).to.equal("300000000000000000000");

            const stakeDetail = await ValidatorStake.validatorStakes(carl.getAddress());
                expect(stakeDetail.stakedAmount).to.equal("0");
                expect(stakeDetail.refundedAmount).to.equal("0");
                const stakeDetail1 = await ValidatorStake.validatorStakes(bob.getAddress());
                expect(stakeDetail1.stakedAmount).to.equal("0");
                expect(stakeDetail1.refundedAmount).to.equal("200000000000000000000");
        
        });
        it("should prevent staking when paused", async function() {
            await ValidatorStake.pause();
            await expect(ValidatorStake.connect(bob).stake("50000000000000000000", await sampleERC20.getAddress()))
                .to.be.revertedWith("Pausable: paused");
            await ValidatorStake.unpause();
            const stakeDetail = await ValidatorStake.validatorStakes(carl.getAddress());
            expect(stakeDetail.stakedAmount).to.equal("0");
            expect(stakeDetail.refundedAmount).to.equal("0");
            const stakeDetail1 = await ValidatorStake.validatorStakes(bob.getAddress());
            expect(stakeDetail1.stakedAmount).to.equal("0");
            expect(stakeDetail1.refundedAmount).to.equal("200000000000000000000");

            let bal1 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal1).to.equal("0");

            let bal2 = await sampleERC20.balanceOf(bob);
            expect(bal2).to.equal("300000000000000000000");
        });

        it("should allow a validator to stake funds", async function() {
            await sampleERC20.mint(carl, "100000000000000000000");
            let bal1 = await sampleERC20.balanceOf(carl);
            expect(bal1).to.equal("100000000000000000000");
            let bal2 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal2).to.equal("0");
            
            await sampleERC20.connect(carl).approve(await ValidatorStake.getAddress(), "100000000000000000000");
           

            await expect(ValidatorStake.connect(carl).stake("100000000000000000000", sampleERC20.getAddress()))
                .to.emit(ValidatorStake, 'Staked')
                .withArgs(carl.address,await sampleERC20.getAddress(),"100000000000000000000", "100000000000000000000", false);
                let bal3 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal3).to.equal("100000000000000000000");

            let bal4 = await sampleERC20.balanceOf(carl);
            expect(bal4).to.equal("0");




                const stakeDetail = await ValidatorStake.validatorStakes(carl.getAddress());
                expect(stakeDetail.stakedAmount).to.equal("100000000000000000000");
                expect(stakeDetail.refundedAmount).to.equal("0");
        });

        it("should reject staking of zero amount", async function() {
            let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("100000000000000000000");
    
            await expect(ValidatorStake.connect(carl).stake(0, sampleERC20.getAddress()))
                .to.be.revertedWith("Low Amount");

                let bal1 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal1).to.equal("100000000000000000000");

                const stakeDetail = await ValidatorStake.validatorStakes(carl.getAddress());
                expect(stakeDetail.stakedAmount).to.equal("100000000000000000000");
                expect(stakeDetail.refundedAmount).to.equal("0");
        });

        it("should reject staking of zero address", async function() {

            let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("100000000000000000000");
    
            await expect(ValidatorStake.connect(carl).stake("100000000000000000000",  "0x0000000000000000000000000000000000000000"))
                .to.be.revertedWith("Zero Address");

                let bal1 = await sampleERC20.balanceOf(ValidatorStake);
                expect(bal1).to.equal("100000000000000000000");


                let bal2 = await sampleERC20.balanceOf(carl);
                expect(bal2).to.equal("0");
    
    
    
                    const stakeDetail = await ValidatorStake.validatorStakes(carl.getAddress());
                    expect(stakeDetail.stakedAmount).to.equal("100000000000000000000");
                    expect(stakeDetail.refundedAmount).to.equal("0");
        });

        it("should not let same validator(carl) stake again", async () => {

            let bal1 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal1).to.equal("100000000000000000000");
            await expect(ValidatorStake.connect(carl).stake("100000000000000000000", await sampleERC20.getAddress()))
            .to.be.revertedWith("more than one time");
            let bal2 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal2).to.equal("100000000000000000000");

            const stakeDetail = await ValidatorStake.validatorStakes(carl.getAddress());
                expect(stakeDetail.stakedAmount).to.equal("100000000000000000000");
                expect(stakeDetail.refundedAmount).to.equal("0");

                let bal3 = await sampleERC20.balanceOf(carl);
                expect(bal3).to.equal("0");
        });


        it("should not add stake when paused", async function() {
            let bal1 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal1).to.equal("100000000000000000000");

            await ValidatorStake.pause();
            await expect(ValidatorStake.connect(carl).addStake("50000000000000000000", await sampleERC20.getAddress()))
                .to.be.revertedWith("Pausable: paused");
            await ValidatorStake.unpause();

            const stakeDetail = await ValidatorStake.validatorStakes(carl.getAddress());
            expect(stakeDetail.stakedAmount).to.equal("100000000000000000000");
            expect(stakeDetail.refundedAmount).to.equal("0");

            let bal3 = await sampleERC20.balanceOf(carl);
            expect(bal3).to.equal("0");
        });

        it("should not add stake with 0 amount", async function() {

            let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("100000000000000000000");
            await expect(ValidatorStake.connect(carl).addStake("0", await sampleERC20.getAddress()))
                .to.be.revertedWith("Low Amount");

                let bal1 = await sampleERC20.balanceOf(ValidatorStake);
                expect(bal1).to.equal("100000000000000000000");
    
    
    
                    const stakeDetail = await ValidatorStake.validatorStakes(carl.getAddress());
                    expect(stakeDetail.stakedAmount).to.equal("100000000000000000000");
                    expect(stakeDetail.refundedAmount).to.equal("0");

        });


        it("should not add stake with 0 _ERC20Address", async function() {
            await expect(ValidatorStake.connect(carl).addStake("50000000000000000000","0x0000000000000000000000000000000000000000"))
                .to.be.revertedWith("Zero Address");

                let bal1 = await sampleERC20.balanceOf(ValidatorStake);
                expect(bal1).to.equal("100000000000000000000");
    
    
    
                    const stakeDetail = await ValidatorStake.validatorStakes(carl.getAddress());
                    expect(stakeDetail.stakedAmount).to.equal("100000000000000000000");
                    expect(stakeDetail.refundedAmount).to.equal("0");


        });

           
        it("should handle multiple add stakes and keep correct total", async function() {

            let bal1 = await sampleERC20.balanceOf(carl);
            expect(bal1).to.equal("0");
            await sampleERC20.mint(carl, "100000000000000000000");
            let bal2 = await sampleERC20.balanceOf(carl);
            expect(bal2).to.equal("100000000000000000000");
            await sampleERC20.connect(carl).approve(await ValidatorStake.getAddress(), "100000000000000000000");
            
            let bal5 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal5).to.equal("100000000000000000000");


            await ValidatorStake.connect(carl).addStake("50000000000000000000", sampleERC20.getAddress());
            await ValidatorStake.connect(carl).addStake("50000000000000000000", sampleERC20.getAddress());
            const details = await ValidatorStake.validatorStakes(carl.address);
            expect(details.stakedAmount).to.equal("200000000000000000000");
            expect(details.refundedAmount).to.equal("0");


            let bal3 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal3).to.equal("200000000000000000000");

            let bal4 = await sampleERC20.balanceOf(carl);
            expect(bal4).to.equal("0");
    
    
        });

        it("should not allow the owner to refund stakes when paused", async function() {
            await ValidatorStake.pause();
            let bal3 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal3).to.equal("200000000000000000000");

            let bal4 = await sampleERC20.balanceOf(carl);
            expect(bal4).to.equal("0");
    

            await expect(ValidatorStake.connect(alice).refundStake(bob.address, sampleERC20.getAddress(), "300000000000000000000"))
            .to.be.revertedWith("Pausable: paused");

               
                let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("200000000000000000000");


            let bal5 = await sampleERC20.balanceOf(carl);
            expect(bal5).to.equal("0");
            await ValidatorStake.unpause();

    
        });

        it("should not allow the owner to refund stakes With 0 amount", async function() {

            let bal3 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal3).to.equal("200000000000000000000");

            let bal4 = await sampleERC20.balanceOf(carl);
            expect(bal4).to.equal("0");
    


            await expect(ValidatorStake.connect(alice).refundStake(bob.address, sampleERC20.getAddress(), "0"))
            .to.be.revertedWith("Low Amount");

               
                let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("200000000000000000000");

                

            let bal5 = await sampleERC20.balanceOf(carl);
            expect(bal5).to.equal("0");

    
        });

        it("should not allow the owner to refund stakes With 0 _ERC20Address", async function() {
            let bal3 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal3).to.equal("200000000000000000000");

            let bal4 = await sampleERC20.balanceOf(carl);
            expect(bal4).to.equal("0");
    

            await expect(ValidatorStake.connect(alice).refundStake(bob.address, "0x0000000000000000000000000000000000000000", "300000000000000000000"))
            .to.be.revertedWith("Zero Address");

               
                let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("200000000000000000000");

            let bal5 = await sampleERC20.balanceOf(carl);
            expect(bal5).to.equal("0");


    
        });


        it("should not allow the owner to refund stakes With 0 _validatorAddress", async function() {
            let bal3 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal3).to.equal("200000000000000000000");

            let bal4 = await sampleERC20.balanceOf(carl);
            expect(bal4).to.equal("0");
    

            await expect(ValidatorStake.connect(alice).refundStake("0x0000000000000000000000000000000000000000",  sampleERC20.getAddress(), "300000000000000000000"))
            .to.be.revertedWith("Zero Address");

               
                let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("200000000000000000000");

            let bal5 = await sampleERC20.balanceOf(carl);
            expect(bal5).to.equal("0");

    
        });




        it("should allow the owner to refund stakes", async function() {
            let bal2 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal2).to.equal("200000000000000000000");


            let bal3 = await sampleERC20.balanceOf(carl);
            expect(bal3).to.equal("0");

            await expect(ValidatorStake.connect(alice).refundStake(carl.address, sampleERC20.getAddress(), "200000000000000000000"))
                .to.emit(ValidatorStake, 'RefundedStake')
                .withArgs(carl.address,await sampleERC20.getAddress(), "200000000000000000000","0");

                let bal1 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal1).to.equal("0");


            let bal = await sampleERC20.balanceOf(carl);
            expect(bal).to.equal("200000000000000000000");

            const details = await ValidatorStake.validatorStakes(carl.address);
            expect(details.stakedAmount).to.equal("0");
            expect(details.refundedAmount).to.equal("200000000000000000000");

    
        });


        it("should allow a validator(validator) to stake funds ", async function() {
            await sampleERC20.mint(validator, "100000000000000000000");
            await sampleERC20.connect(validator).approve(await ValidatorStake.getAddress(), "100000000000000000000");
            let bal = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal).to.equal("0");

            let bal5 = await sampleERC20.balanceOf(validator);
            expect(bal5).to.equal("100000000000000000000");


          
            await expect(ValidatorStake.connect(validator).stake("100000000000000000000", sampleERC20.getAddress()))
                .to.emit(ValidatorStake, 'Staked')
                .withArgs(validator.address,await sampleERC20.getAddress(),"100000000000000000000", "100000000000000000000", false);
  
                let bal2 = await sampleERC20.balanceOf(validator);
                expect(bal2).to.equal("0");
    

                let bal1 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal1).to.equal("100000000000000000000");



                const stakeDetail = await ValidatorStake.validatorStakes(validator.getAddress());
                expect(stakeDetail.stakedAmount).to.equal("100000000000000000000");
                expect(stakeDetail.refundedAmount).to.equal("0");
        });

        it("should not let same validator(validator) stake again", async () => {

            let bal1 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal1).to.equal("100000000000000000000");
            await expect(ValidatorStake.connect(validator).stake("100000000000000000000", await sampleERC20.getAddress()))
            .to.be.revertedWith("more than one time");
            let bal2 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal2).to.equal("100000000000000000000");

            const stakeDetail = await ValidatorStake.validatorStakes(validator.getAddress());
                expect(stakeDetail.stakedAmount).to.equal("100000000000000000000");
                expect(stakeDetail.refundedAmount).to.equal("0");
                let bal3 = await sampleERC20.balanceOf(validator);
                expect(bal3).to.equal("0");
        });

        it("should not refunds by non owner", async function() {

            let bal2 = await sampleERC20.balanceOf(validator);
            expect(bal2).to.equal("0");


            let bal1 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal1).to.equal("100000000000000000000");


            await expect(
             ValidatorStake.connect(carl).refundStake(validator,await sampleERC20.getAddress(), "50000000000")
            ).to.be.revertedWith("Ownable: caller is not the owner");

            const stakeDetail = await ValidatorStake.validatorStakes(validator.getAddress());
                expect(stakeDetail.stakedAmount).to.equal("100000000000000000000");
                expect(stakeDetail.refundedAmount).to.equal("0");
        });

        it("should manage multiple refunds correctly", async function() {
            let bal2 = await sampleERC20.balanceOf(validator);
            expect(bal2).to.equal("0");


            let bal1 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal1).to.equal("100000000000000000000");


            await ValidatorStake.connect(alice).refundStake(validator.address, sampleERC20.getAddress(), "50000000000000000000");
            const details = await ValidatorStake.validatorStakes(validator.address);
            expect(details.stakedAmount).to.equal("50000000000000000000");
            expect(details.refundedAmount).to.equal("50000000000000000000");

            await ValidatorStake.connect(alice).refundStake(validator.address, sampleERC20.getAddress(), "50000000000000000000");
            const stakeDetail = await ValidatorStake.validatorStakes(validator.address);
            expect(stakeDetail.stakedAmount).to.equal("0");
            expect(stakeDetail.refundedAmount).to.equal("100000000000000000000");

            let bal3 = await sampleERC20.balanceOf(validator);
            expect(bal3).to.equal("100000000000000000000");


            let bal4 = await sampleERC20.balanceOf(ValidatorStake);
            expect(bal4).to.equal("0");

        });




        

    });
});

