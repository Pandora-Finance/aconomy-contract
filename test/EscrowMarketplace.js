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

    })


  })