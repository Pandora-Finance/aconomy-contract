const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const moment = require("moment");
const { BN } = require("@openzeppelin/test-helpers");

describe("NFT Lending and Borrowing", function () {

  let res, poolId1, pool1Address, expiration, poolId, bidId, bidId1, loanId1;

  async function deployContractFactory() {
    [alice, validator, bob, royaltyReceiver, carl, random, newFeeAddress] = await ethers.getSigners();

    aconomyFee = await hre.ethers.deployContract("AconomyFee", []);
    await aconomyFee.waitForDeployment();

    await aconomyFee.setAconomyPoolFee(50)
    await aconomyFee.setAconomyPiMarketFee(50)
    await aconomyFee.setAconomyNFTLendBorrowFee(50)

    const LibShare = await hre.ethers.deployContract("LibShare", []);
    await LibShare.waitForDeployment();

    const piNFTMethods = await hre.ethers.getContractFactory("piNFTMethods", {
        libraries: {
        LibShare: await LibShare.getAddress(),
        }
    })
    const piNftMethods = await upgrades.deployProxy(piNFTMethods, ["0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"], {
        initializer: "initialize",
        kind: "uups",
        unsafeAllow: ["external-library-linking"],
    })

    const mintToken = await hre.ethers.deployContract("mintToken", ["100000000000"]);
    sampleERC20 = await mintToken.waitForDeployment();

    const pi = await hre.ethers.getContractFactory("piNFT")
    piNFT = await upgrades.deployProxy(pi, ["Aconomy", "ACO", await piNftMethods.getAddress(), "0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"], {
        initializer: "initialize",
        kind: "uups"
    })

    const LibEscrowMarket = await hre.ethers.deployContract("LibEscrowMarket", []);
    await LibEscrowMarket.waitForDeployment();

    const EscrowMarketplace = await hre.ethers.getContractFactory("EscrowMarketplace",{
      libraries: {
          LibEscrowMarket: await LibEscrowMarket.getAddress(),
          }
    })
    escrowMarketplace = await upgrades.deployProxy(EscrowMarketplace, ["0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"], {
        initializer: "initialize",
        kind: "uups",
        unsafeAllow: ["external-library-linking"],
    })

  //   return { escrowMarketplace };


    return { escrowMarketplace, piNFT, sampleERC20, aconomyFee, alice, validator, bob, royaltyReceiver, carl, random, newFeeAddress };
  }

  describe("Deployment", function () {

      it("should deploy the NFTlendingBorrowing Contract", async () => {
          let {escrowMarketplace, piNFT, sampleERC20, aconomyFee, alice, validator, bob, royaltyReceiver, carl, random, newFeeAddress} = await deployContractFactory()
          // let {escrowMarketplace} = await deployContractFactory()
        console.log("pinft", piNFT.getAddress())
      });

      it("should not let non owner set aconomy fees", async () => {
          await expect(aconomyFee.connect(royaltyReceiver).setAconomyNFTLendBorrowFee(100)
          ).to.be.revertedWith("Ownable: caller is not the owner")
  
          await expect(aconomyFee.connect(royaltyReceiver).setAconomyPoolFee(100)
          ).to.be.revertedWith("Ownable: caller is not the owner")
  
          await expect(aconomyFee.connect(royaltyReceiver).setAconomyPiMarketFee(100)
          ).to.be.revertedWith("Ownable: caller is not the owner")
  
          await aconomyFee.setAconomyNFTLendBorrowFee(100)
          await aconomyFee.setAconomyPoolFee(100)
          await aconomyFee.setAconomyPiMarketFee(100)
        })


        it("should allow user to list an NFT for sale", async () => {
          // First mint an NFT
          await piNFT.connect(alice).mintNFT(alice.address, "NFT_URI", []);
          
          // Get the contract addresses
          const escrowAddress = await escrowMarketplace.getAddress();
          const piNFTAddress = await piNFT.getAddress();
          const sampleERC20Address = await sampleERC20.getAddress();
          
          // Approve and sell
          await piNFT.connect(alice).approve(escrowAddress, 0);
          await escrowMarketplace.connect(alice).sellNFT(piNFTAddress, sampleERC20Address, 0, 1000);

          const escrow = await escrowMarketplace.escrows(0);
          expect(escrow.seller).to.equal(alice.address);
          expect(escrow.price).to.equal(1000);
      });

      it("should not allow a non-owner to list an NFT", async () => {
        // Ensure Alice mints an NFT
        await piNFT.connect(alice).mintNFT(alice.address, "NFT_URI", []);
        
        await expect(
            escrowMarketplace.connect(bob).sellNFT(piNFT.getAddress(), sampleERC20.getAddress(), 0, 1000)
        ).to.be.revertedWith("Only token owner can execute");
    });

    it("should allow buyer to deposit payment", async () => {
      // await piNFT.connect(alice).mintNFT(alice.address, "NFT_URI", []);
      // await piNFT.connect(alice).approve(escrowMarketplace.getAddress(), 0);

      // await escrowMarketplace.connect(alice).sellNFT(piNFT.getAddress(), sampleERC20.getAddress(), 0, 1000);

      await sampleERC20.mint(bob.address, 1000);
      await sampleERC20.connect(bob).approve(escrowMarketplace.getAddress(), 1000);

      await escrowMarketplace.connect(bob).depositPayment(0);

      const escrow = await escrowMarketplace.escrows(0);
      expect(escrow.buyer).to.equal(bob.address);
      expect(escrow.state).to.equal(1); // AWAITING_PAYMENT
    });


    it("should allow seller to ship an asset", async () => {
          
          await escrowMarketplace.connect(bob).redeemAsset(0);
          await escrowMarketplace.connect(alice).shipAsset(0);
    
          const escrow = await escrowMarketplace.escrows(0);
          expect(escrow.state).to.equal(3); // AWAITING_CONFIRMATION
        });
  

        it("should allow buyer to confirm delivery", async () => {
          
              const initialContractTokenBalance = await sampleERC20.balanceOf(escrowMarketplace.getAddress());
              console.log("Initial Contract Token Balance:", initialContractTokenBalance.toString());

              await escrowMarketplace.connect(bob).confirmDelivery(0);
      
              const escrow = await escrowMarketplace.escrows(0);
              expect(escrow.state).to.equal(4); // COMPLETED
          });

            it("should prevent dispute after confirmation period", async function () {

            // First, mint and list the NFT
            
            await sampleERC20.mint(alice, 1000);
            await piNFT.connect(alice).mintNFT(alice, "NFT_URI", []);
            await piNFT.connect(alice).approve(escrowMarketplace.getAddress(), 1);
            await escrowMarketplace.connect(alice).sellNFT(piNFT.getAddress(), sampleERC20.getAddress(), 1, 1000);
        
            // Mint and approve tokens for buyer
            await sampleERC20.mint(bob.address, 1000);
            await sampleERC20.connect(bob).approve(escrowMarketplace.getAddress(), 1000);
        
            // Deposit payment
            await escrowMarketplace.connect(bob).depositPayment(1);
            
            // Redeem asset
            await escrowMarketplace.connect(bob).redeemAsset(1);
            
            // Ship asset
            await escrowMarketplace.connect(alice).shipAsset(1);
        
            // Check current escrow state before dispute
            let escrow = await escrowMarketplace.escrows(1);
            console.log("Current Escrow State:", escrow.state);

             // Simulate time passing beyond confirmation period
             await ethers.provider.send("evm_increaseTime", [11 * 24 * 60 * 60]); // 11 days
             await ethers.provider.send("evm_mine");
 
             // Attempt to raise dispute should fail
             await expect(
                 escrowMarketplace.connect(bob).raiseDispute(1)
             ).to.be.revertedWith("Dispute period expired");
            });


             it("should allow raising a dispute", async function () {
              await sampleERC20.mint(alice, 1000);
            await piNFT.connect(alice).mintNFT(alice, "NFT_URI", []);
            await piNFT.connect(alice).approve(escrowMarketplace.getAddress(), 2);
            await escrowMarketplace.connect(alice).sellNFT(piNFT.getAddress(), sampleERC20.getAddress(), 2, 1000);
        
            // Mint and approve tokens for buyer
            await sampleERC20.mint(bob.address, 1000);
            await sampleERC20.connect(bob).approve(escrowMarketplace.getAddress(), 1000);
        
            // Deposit payment
            await escrowMarketplace.connect(bob).depositPayment(2);
            
            // Redeem asset
            await escrowMarketplace.connect(bob).redeemAsset(2);
            
            // Ship asset
            await escrowMarketplace.connect(alice).shipAsset(2);
        
            // Check current escrow state before dispute
            let escrow = await escrowMarketplace.escrows(2);
            console.log("Current Escrow State:", escrow.state);

        
            // Simulate time passing (but within dispute period)
            await ethers.provider.send("evm_increaseTime", [9 * 24 * 60 * 60]); // 9 days
            await ethers.provider.send("evm_mine");
        
            // Raise dispute
            await escrowMarketplace.connect(bob).raiseDispute(2);
        
            // Verify dispute state
            escrow = await escrowMarketplace.escrows(2);
            expect(escrow.state).to.equal(5); // DISPUTED
        });
          

           
        // });

    //     it("should handle timeout for seller not shipping", async function () {
    //         // Deposit payment
    //         await escrowMarketplace.connect(bob).depositPayment(0);
            
    //         // Redeem asset
    //         await escrowMarketplace.connect(bob).redeemAsset(0);
            
    //         // Simulate time passing
    //         await ethers.provider.send("evm_increaseTime", [4 * 24 * 60 * 60]); // 4 days
    //         await ethers.provider.send("evm_mine");

    //         // Handle timeout
    //         await escrowMarketplace.handleTimeouts(0);

    //         // Check escrow state and balances
    //         const escrow = await escrowMarketplace.escrows(0);
    //         const bobBalance = await sampleERC20.balanceOf(bob.address);

    //         expect(escrow.state).to.equal(4); // COMPLETED
    //         expect(bobBalance).to.equal(1000);
    //     });

    it("should prevent non-owner from resolving dispute", async function () {

      // Non-owner attempts to resolve dispute
      await expect(
          escrowMarketplace.connect(bob).resolveDispute(2, true)
      ).to.be.revertedWith("Ownable: caller is not the owner");
  });

        it("should resolve dispute by owner", async function () {


            // Owner resolves dispute in seller's favor
            await escrowMarketplace.resolveDispute(2, true);

            // Check seller's balance
            const aliceBalance = await sampleERC20.balanceOf(alice.address);
            // expect(aliceBalance).to.equal(1000);
        });

      
    // });

        // it("should allow seller to cancel listing before deposit", async function () {
        //     // Cancel sale
        //     await escrowMarketplace.connect(alice).cancelSale(2);

        //     // Check escrow state
        //     const escrow = await escrowMarketplace.escrows(2);
        //     expect(escrow.state).to.equal(6); // LISTING_CANCELED

        //     // Verify NFT returned to seller
        //     const nftOwner = await piNFT.ownerOf(2);
        //     expect(nftOwner).to.equal(alice.address);
        // });

    //     it("should prevent cancellation after deposit", async function () {
    //         // Deposit payment
    //         await escrowMarketplace.connect(bob).depositPayment(0);

    //         // Attempt to cancel should fail
    //         await expect(
    //             escrowMarketplace.connect(alice).cancelSale(0)
    //         ).to.be.revertedWith("Invalid escrow state for this action");
    //     });

  })
 

})