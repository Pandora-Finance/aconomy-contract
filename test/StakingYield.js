// const {
//     loadFixture,
//   } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
//   const { time } = require("@nomicfoundation/hardhat-network-helpers");
//   const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
//   const { expect } = require("chai");
//   const { ethers } = require("hardhat");
//   const { BN } = require("@openzeppelin/test-helpers");
  
//   const BigNumber = require("big-number");

//   describe("piMarket", function () {

//     async function deployStakingYield() {
//         [
//           alice,
//           validator,
//           bob,
//           carl,
//           royaltyReceiver,
//           feeReceiver,
//           bidder1,
//           bidder2,
//           bidder3,
//         ] = await ethers.getSigners();

//         const mintToken = await hre.ethers.deployContract("mintToken", [
//             "100000000000",
//           ]);
//           sampleERC20 = await mintToken.waitForDeployment();
  
//       const stakingyield = await hre.ethers.deployContract("StakingYield", [await sampleERC20.getAddress()]);
//       stakingYield = await stakingyield.waitForDeployment();


//       console.log("stakingYield : ", await stakingYield.getAddress());

//       return {
//         stakingYield,
//         sampleERC20,
//         alice,
//         validator,
//         bob,
//         carl,
//         royaltyReceiver,
//         feeReceiver,
//         bidder1,
//         bidder2,
//         bidder3,
//       };

//     }

//     describe("Staking Yield", function () {
//         it("should deploy the contracts", async () => {
//             let {
//               stakingYield,
//               sampleERC20,
//               alice,
//               validator,
//               bob,
//               carl,
//               royaltyReceiver,
//               feeReceiver,
//               bidder1,
//               bidder2,
//               bidder3,
//             } = await deployStakingYield();
//           });

//           it("should let owner set RewardsDuration for one year", async() => {
//             await stakingYield.setRewardsDurationAndRewardTokens(31535975, "6000000000000000000000000");
//             console.log("fee 111",await stakingYield.RewardTokens());
//           })

//           it("should let owner notifyRewardAmount with 6M", async() => {
//               await sampleERC20.mint(await stakingYield.getAddress(), "6000000000000000000000000");
//               await stakingYield.notifyRewardAmount("6000000000000000000000000");
//             let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
//           console.log("fee 1", b1.toString());
//           })


//           it("should let bob stake 3 lacks token to contract", async() => {
//               await sampleERC20.mint(alice, "300000000000000000000000");
//               await sampleERC20.approve(await stakingYield.getAddress(), "300000000000000000000000");
//               await stakingYield.stake(bob,"300000000000000000000000");
              
//               let b1 = await sampleERC20.balanceOf(bob);
//                 console.log("fee 1", );
//                 expect(await stakingYield.totalSupply()).to.equal("300000000000000000000000");
//                 const result = await stakingYield.balanceOf(bob);
//                 expect(result.Amount).to.equal("300000000000000000000000");
//                 console.log("time", result.StakingTime);
//           })

//           it("should let bob earned some tokens after 300 seconds", async() => {
//             await time.increase(300);
//             console.log("bob earned", await stakingYield.earned(bob));
//             })

//             it("should let carl stake 6 lacks token to contract", async() => {
//                 await time.increase(30000);
//                 await sampleERC20.mint(alice, "600000000000000000000000");
//                 await sampleERC20.approve(await stakingYield.getAddress(), "600000000000000000000000");
//                 await stakingYield.stake(carl,"300000000000000000000000");
                
//                 // let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
//                 //   console.log("fee 1", b1);
//                 //   expect(await stakingYield.totalSupply()).to.equal("900000000000000000000000");
//                 //   const result = await stakingYield.balanceOf(carl);
//                 //   expect(result.Amount).to.equal("600000000000000000000000");
//                 //   console.log("time", result.StakingTime);
//             })

//             it("should let bob earned some tokens after 300 seconds", async() => {
//                 await time.increase(3000);
//                 console.log("carl earned", await stakingYield.earned(carl));
//                 console.log("bob earned", await stakingYield.earned(bob));
//                 })


//                 it("should let carl stake 6 lacks token to contract", async() => {
//                     await time.increase(30000);
//                     await sampleERC20.mint(alice, "600000000000000000000000");
//                     await sampleERC20.approve(await stakingYield.getAddress(), "600000000000000000000000");
//                     await stakingYield.stake(bidder1,"300000000000000000000000");
                    
//                     // let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
//                     //   console.log("fee 1", b1);
//                     //   expect(await stakingYield.totalSupply()).to.equal("900000000000000000000000");
//                     //   const result = await stakingYield.balanceOf(carl);
//                     //   expect(result.Amount).to.equal("600000000000000000000000");
//                     //   console.log("time", result.StakingTime);
//                 })

//                 it("should let bob earned some tokens after 300 seconds", async() => {
//                     await time.increase(3000);
//                     console.log("carl earned", await stakingYield.earned(carl));
//                     console.log("bob earned", await stakingYield.earned(bob));
//                     console.log("bidder1 earned", await stakingYield.earned(bidder1));
//                     })





//     })


    

//   });





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

        const mintToken = await hre.ethers.deployContract("mintToken", [
            "100000000000",
          ]);
          sampleERC20 = await mintToken.waitForDeployment();

          const mintToken1 = await hre.ethers.deployContract("mintToken", [
            "100000000000",
          ]);
          newsampleERC20 = await mintToken1.waitForDeployment();
  
      const stakingyield = await hre.ethers.deployContract("StakingYield", [await sampleERC20.getAddress()]);
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

          it("should let owner set RewardsDuration for one year", async() => {
            await stakingYield.setRewardsDuration(31535975);
            // console.log("fee 111",await stakingYield.RewardTokens());
          })

          it("should let owner notifyRewardAmount with 6M", async() => {
              await sampleERC20.mint(alice, "6000000000000000000000000");

              await sampleERC20.connect(alice).approve(await stakingYield.getAddress(), "6000000000000000000000000");
              await stakingYield.depositRewardToken("6000000000000000000000000");
              await stakingYield.notifyRewardAmount("6000000000000000000000000");
            let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
          console.log("fee 1", b1.toString());
          })


          it("should let bob stake 3 lacks token to contract", async() => {
              await sampleERC20.mint(bob, "300000000000000000000000");
              await sampleERC20.connect(bob).approve(await stakingYield.getAddress(), "300000000000000000000000");
              await stakingYield.connect(bob).stake("300000000000000000000000");
              
            //   let b1 = await sampleERC20.balanceOf(bob);
            //     console.log("fee 1", );
            //     expect(await stakingYield.totalSupply()).to.equal("300000000000000000000000");
            //     const result = await stakingYield.balanceOf(bob);
            //     expect(result.Amount).to.equal("300000000000000000000000");
            //     console.log("time", result.StakingTime);
          })

          it("should let bob earned some tokens after 300 seconds", async() => {
            await time.increase(300);
            console.log("bob earned", await stakingYield.earned(bob));
            })

            it("should let carl stake 6 lacks token to contract", async() => {
                await time.increase(30000);
                await sampleERC20.mint(carl, "600000000000000000000000");
                await sampleERC20.connect(carl).approve(await stakingYield.getAddress(), "600000000000000000000000");
                await stakingYield.connect(carl).stake("300000000000000000000000");
                
                // let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
                //   console.log("fee 1", b1);
                //   expect(await stakingYield.totalSupply()).to.equal("900000000000000000000000");
                //   const result = await stakingYield.balanceOf(carl);
                //   expect(result.Amount).to.equal("600000000000000000000000");
                //   console.log("time", result.StakingTime);
            })

            it("should let bob earned some tokens after 300 seconds", async() => {
                await time.increase(3000);
                console.log("carl earned", await stakingYield.earned(carl));
                console.log("bob earned", await stakingYield.earned(bob));
                })


                it("should let carl stake 6 lacks token to contract", async() => {
                    await time.increase(30000);
                    await sampleERC20.mint(bidder1, "600000000000000000000000");
                    await sampleERC20.connect(bidder1).approve(await stakingYield.getAddress(), "600000000000000000000000");
                    await stakingYield.connect(bidder1).stake("300000000000000000000000");
                    
                    // let b1 = await sampleERC20.balanceOf(await stakingYield.getAddress());
                    //   console.log("fee 1", b1);
                    //   expect(await stakingYield.totalSupply()).to.equal("900000000000000000000000");
                    //   const result = await stakingYield.balanceOf(carl);
                    //   expect(result.Amount).to.equal("600000000000000000000000");
                    //   console.log("time", result.StakingTime);
                })

                it("should let bob earned some tokens after 300 seconds", async() => {
                    await time.increase(3000);
                    console.log("carl earned", await stakingYield.earned(carl));
                    console.log("bob earned", await stakingYield.earned(bob));
                    console.log("bidder1 earned", await stakingYield.earned(bidder1));
                    })





    })


    

  });