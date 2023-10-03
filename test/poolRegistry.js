const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
  const { ethers } = require("hardhat");
  const moment = require("moment");
  const { BN } = require("@openzeppelin/test-helpers");
  
  describe("Pool Registry", function (){
    let res, poolId1, poolId2, loanId1, newpoolId;
    const paymentCycleDuration = moment.duration(30, "days").asSeconds();
    const expiration = moment.duration(2, "days").asSeconds();
    const loanDuration = moment.duration(150, "days").asSeconds();
    const loanDefaultDuration = moment.duration(90, "days").asSeconds();
    const loanExpirationDuration = moment.duration(180, "days").asSeconds();

    async function deployContractFactory() {
      [account0, account1, account2, account3, random] = await ethers.getSigners();

      aconomyFee = await hre.ethers.deployContract("AconomyFee", []);
      await aconomyFee.waitForDeployment();

      await aconomyFee.setAconomyPoolFee(50)
      await aconomyFee.setAconomyPiMarketFee(50)
      await aconomyFee.setAconomyNFTLendBorrowFee(50)

      const attestRegistry = await hre.ethers.deployContract("AttestationRegistry", []);
      await attestRegistry.waitForDeployment();

      attestServices = await hre.ethers.deployContract("AttestationServices", [attestRegistry.getAddress()]);
      await attestServices.waitForDeployment();

      const LibCalculations = await hre.ethers.deployContract("LibCalculations", []);
      await LibCalculations.waitForDeployment();
  
      const LibPool = await hre.ethers.deployContract("LibPool", []);
      await LibPool.waitForDeployment();

      const FundingPool = await hre.ethers.getContractFactory("FundingPool", {
        libraries: {
          LibCalculations: await LibCalculations.getAddress()
        }
      })
      const fundingPool = await FundingPool.deploy();
      await fundingPool.waitForDeployment();

      const poolRegistry = await hre.ethers.getContractFactory("poolRegistry", {
        libraries: {
          LibPool: await LibPool.getAddress()
        }
      })
      poolRegis = await upgrades.deployProxy(poolRegistry, [await attestServices.getAddress(), await aconomyFee.getAddress(), await fundingPool.getAddress()], {
        initializer: "initialize",
        kind: "uups",
        unsafeAllow: ["external-library-linking"],
      })

      const LibPoolAddress = await hre.ethers.getContractFactory("LibPoolAddress", {
        libraries: {
          LibCalculations: await LibCalculations.getAddress()
        }
      })
      const libPoolAddress = await LibPoolAddress.deploy();
      await libPoolAddress.waitForDeployment();
    
      const poolAddress = await hre.ethers.getContractFactory("poolAddress", {
        libraries: {
          LibCalculations: await LibCalculations.getAddress(),
          LibPoolAddress: await libPoolAddress.getAddress()
        }
      })
      poolAddressInstance = await upgrades.deployProxy(poolAddress, [await poolRegis.getAddress(), await aconomyFee.getAddress()], {
        initializer: "initialize",
        kind: "uups",
        unsafeAllow: ["external-library-linking"],
      })
  
      const mintToken = await hre.ethers.deployContract("mintToken", ["100000000000"]);
      erc20 = await mintToken.waitForDeployment();
  
      return { aconomyFee, attestServices, erc20, poolRegis, poolAddressInstance, account0, account1, account2, account3, random };
    }
  
    describe("Deployment", function () {
        it("should set Aconomyfee", async () => {
            let{ aconomyFee, attestServices, erc20, poolRegis, poolAddressInstance, account0, account1, account2, account3, random } = await deployContractFactory()
            await aconomyFee.setAconomyPoolFee(200);
            let protocolFee = await aconomyFee.AconomyPoolFee();
            let aconomyFeeOwner = await aconomyFee.getAconomyOwnerAddress();
            expect(aconomyFeeOwner).to.equal(await account0.getAddress());
            expect(protocolFee).to.equal(200);
          });

          it("should not let non owner to pause and unpause the contract", async () => {
            await expect(
              poolRegis.connect(random).pause()
            ).to.be.revertedWith("Ownable: caller is not the owner");
      
            await poolRegis.pause();
      
            await expect(
              poolRegis.connect(random).unpause()
            ).to.be.revertedWith("Ownable: caller is not the owner");
      
            await poolRegis.unpause();
          })
        
          it("should create attestRegistry, attestationService", async () => {
            expect(
              await attestServices.getAddress()).to.not.equal(
              null || undefined
            );
          });
        
          it("should create Pool", async () => {
            res = await poolRegis.createPool(
              loanDefaultDuration,
              loanExpirationDuration,
              100,
              1000,
              "sk.com",
              true,
              true
            );
            poolId1 = 1;
            // console.log(poolId1, "poolId1");
            pool1Address = await poolRegis.getPoolAddress(poolId1);
            // console.log(pool1Address, "poolAdress");
            res = await poolRegis.lenderVerification(poolId1, account0);
            expect(
              res.isVerified_).to.equal(
              true
            );
            res = await poolRegis.borrowerVerification(poolId1, account0);
            expect(
              res.isVerified_).to.equal(
              true);
          });
        
          it("should create a new Pool", async () => {
            res = await poolRegis.createPool(
              211111111,
              2111111222,
              100,
              1000,
              "sk.com",
              false,
              false
            );
        
            poolId2 = 2;
            // console.log(poolId2, "poolId2");
            pool1Address = await poolRegis.getPoolAddress(poolId1);
            // console.log(pool1Address, "poolAdress");
            res = await poolRegis.lenderVerification(poolId2, account0);
            expect(
              res.isVerified_).to.equal(
              true);
            res = await poolRegis.borrowerVerification(poolId2, account0);
            expect(
              res.isVerified_).to.equal(
              true);
          });
        
          it("should create an other new Pool", async () => {
            res = await poolRegis.createPool(
              211111111,
              2111111222,
              100,
              1000,
              "sk.com",
              true,
              true
            );
        
            newpoolId = 3;
            newpool1Address = await poolRegis.getPoolAddress(poolId1);
            
            res = await poolRegis.lenderVerification(newpoolId, account0);
            expect(
              res.isVerified_).to.equal(
              true);
            res = await poolRegis.borrowerVerification(newpoolId, account0);
            expect(
              res.isVerified_).to.equal(
              true);
          });

          it("should change the URI", async () => {
            let uri = await poolRegis.getPoolUri(3);
            expect(uri).to.equal("sk.com");
            await poolRegis.setPoolURI(3, "sk.com")
            await expect(poolRegis.connect(random).setPoolURI(3, "sk.com")).to.be.revertedWith("Not the owner")
            await poolRegis.setPoolURI(3, "XYZ");
            uri = await poolRegis.getPoolUri(3);
            expect(uri).to.equal("XYZ");
          })
        
          it("should change the APR", async () => {
            let apr = await poolRegis.getPoolApr(3);
            expect(apr).to.equal(1000);
            await poolRegis.setApr(3, 1000)
            await expect(poolRegis.connect(random).setApr(3, 1000)).to.be.revertedWith("Not the owner")
            await expect(
              poolRegis.setApr(3, 99)).to.be.revertedWith(
              "given apr too low"
            );
            await poolRegis.setApr(3, 200);
            let newAPR = await poolRegis.getPoolApr(3);
            expect(newAPR).to.equal(200);
          });
        
          it("should change the payment default duration", async () => {
            let DefaultDuration = await poolRegis.getPaymentDefaultDuration(3);
            expect(DefaultDuration).to.equal(211111111);
            await poolRegis.setPaymentDefaultDuration(3, 211111111)
            await expect(poolRegis.connect(random).setPaymentDefaultDuration(3, 211111111)).to.be.revertedWith("Not the owner")
            await expect(
              poolRegis.setPaymentDefaultDuration(3, 0)).to.be.revertedWith(
              "default duration cannot be 0"
            );
            await poolRegis.setPaymentDefaultDuration(3, 211111112);
            let newDefaultDuration = await poolRegis.getPaymentDefaultDuration(3);
            expect(
              newDefaultDuration).to.equal(
              211111112);
          });
        
          it("should change the Pool Fee percent", async () => {
            let PoolFeePercent = await poolRegis.getPoolFeePercent(3);
            expect(PoolFeePercent).to.equal(100);
            await poolRegis.setPoolFeePercent(3, 100);
            await expect(poolRegis.connect(random).setPoolFeePercent(3, 100)).to.be.revertedWith("Not the owner")
            await expect(
              poolRegis.setPoolFeePercent(3, 1001)).to.be.revertedWith(
              "cannot exceed 10%"
            );
            await poolRegis.setPoolFeePercent(3, 200);
            let newPoolFeePercent = await poolRegis.getPoolFeePercent(3);
            expect(newPoolFeePercent).to.equal(200);
          });
        
          it("should change the loan Expiration Time", async () => {
            let loanExpirationTime = await poolRegis.getloanExpirationTime(3);
            await expect(
              poolRegis.setloanExpirationTime(3, 0)).to.be.revertedWithoutReason()
            expect(
              loanExpirationTime).to.equal(
              2111111222);
            await poolRegis.setloanExpirationTime(3, 2111111222);
            await expect(poolRegis.connect(random).setloanExpirationTime(3, 2111111223)).to.be.revertedWith("Not the owner")
            await poolRegis.setloanExpirationTime(3, 2111111223);
            let newloanExpirationTime = await poolRegis.getloanExpirationTime(3);
            expect(
              newloanExpirationTime).to.equal(
              2111111223);
          });

          it("should not allow adding lender if contract is paused", async () => {
            await poolRegis.pause();
      
            await expect(
              poolRegis.addLender(newpoolId, account3)
            ).to.be.revertedWith("Pausable: paused");
      
            await poolRegis.unpause();
          });

          it("should not allow adding borrower if contract is paused", async () => {
            await poolRegis.pause();
      
            await expect(
              poolRegis.addBorrower(newpoolId, account1)
            ).to.be.revertedWith("Pausable: paused");
      
            await poolRegis.unpause();
          });
        
          it("should check only owner can add lender and borrower", async () => {
            await expect(
              poolRegis.connect(account2).addBorrower(newpoolId, account1)).to.be.revertedWith(
              "Not the owner"
            );
        
            res = await poolRegis.lenderVerification(poolId1, account3);
            expect(
              res.isVerified_).to.equal(
              false);
        
            await expect(
              poolRegis.connect(account2).addLender(newpoolId, account3)).to.be.revertedWith(
              "Not the owner"
            );
          });
        
          it("should check lender and borrower are romoved or not", async () => {
            res = await poolRegis.lenderVerification(newpoolId, account3);
            expect(
              res.isVerified_).to.equal(
              false)
            await poolRegis.addLender(newpoolId, account3);
            res = await poolRegis.lenderVerification(newpoolId, account3);
            expect(
              res.isVerified_).to.equal(
              true);
                
            await expect(poolRegis.connect(random).removeLender(newpoolId, account3)).to.be.revertedWith("Not the owner")

            await poolRegis.pause();

            await expect(
              poolRegis.removeLender(newpoolId, account3)
            ).to.be.revertedWith("Pausable: paused");

            await poolRegis.unpause();

            await poolRegis.removeLender(newpoolId, account3);
            res = await poolRegis.lenderVerification(newpoolId, account3);
            expect(
              res.isVerified_).to.equal(
              false);
        
            await poolRegis.addBorrower(newpoolId, account1);
            res = await poolRegis.borrowerVerification(newpoolId, account1);
            expect(
              res.isVerified_).to.equal(
              true);
                
            await expect(poolRegis.connect(random).removeBorrower(newpoolId, account1)).to.be.revertedWith("Not the owner")

            await poolRegis.pause();

            await expect(
              poolRegis.removeBorrower(newpoolId, account1)
            ).to.be.revertedWith("Pausable: paused");

            await poolRegis.unpause();

            await poolRegis.removeBorrower(newpoolId, account1);
            res = await poolRegis.borrowerVerification(newpoolId, account1);
            expect(
              res.isVerified_).to.equal(
              false);
          });
        
          it("should verify the details of pool2", async () => {
            let DefaultDuration = await poolRegis.getPaymentDefaultDuration(poolId2);
            // console.log("aaa",DefaultDuration.toString())
        
            expect(DefaultDuration).to.equal(211111111);
        
            let ExpirationTime = await poolRegis.getloanExpirationTime(poolId2);
            // console.log("aaa111",ExpirationTime.toString())
            expect(ExpirationTime).to.equal(2111111222);
        
            res = await poolRegis.lenderVerification(poolId2, account2);
            expect(
              res.isVerified_).to.equal(
              true);
            res = await poolRegis.borrowerVerification(poolId2, account2);
            expect(
              res.isVerified_).to.equal(
              true);
          });
        
          it("should change the setting of new pool", async () => {
            await expect(poolRegis.connect(random).changePoolSetting(
              poolId2,
              11111111,
              111111222,
              200,
              2000,
              "srs.com"
            )).to.be.revertedWith("Not the owner")

            res = await poolRegis.changePoolSetting(
              poolId2,
              11111111,
              111111222,
              200,
              2000,
              "srs.com"
            );
        
            let apr = await poolRegis.getPoolApr(poolId2);
            expect(
              apr).to.equal(
              2000);
        
            let DefaultDuration = await poolRegis.getPaymentDefaultDuration(poolId2);
            // console.log("aaa",DefaultDuration.toString())
        
            expect(DefaultDuration).to.equal(11111111);
        
            let ExpirationTime = await poolRegis.getloanExpirationTime(poolId2);
            // console.log("aaa111",ExpirationTime.toString())
            expect(ExpirationTime).to.equal(111111222);
        
            res = await poolRegis.lenderVerification(poolId2, account2);
            expect(
              res.isVerified_).to.equal(
              true);
            res = await poolRegis.borrowerVerification(poolId2, account2);
            expect(
              res.isVerified_).to.equal(
              true);
          });
        
          it("should not create if the contract is paused", async () => {
            await poolRegis.pause();
            await expect(
              poolRegis.createPool(
                loanDefaultDuration,
                loanExpirationDuration,
                100,
                1000,
                "sk.com",
                true,
                true
              )).to.be.revertedWith('Pausable: paused')
            await poolRegis.unpause();
          });
        
          it("should add Lender to the pool", async () => {
            res = await poolRegis.lenderVerification(poolId1, account3);
            expect(
              res.isVerified_).to.equal(
              false);
            await poolRegis.addLender(poolId1, account3);
            res = await poolRegis.lenderVerification(poolId1, account3);
            expect(
              res.isVerified_).to.equal(
              true);
          });
        
          it("should add Borrower to the pool", async () => {
            await poolRegis.addBorrower(poolId1, account1);
            res = await poolRegis.borrowerVerification(poolId1, account1);
            expect(
              res.isVerified_).to.equal(
              true);
          });
        
          it("should allow Attested Borrower to Request Loan in a Pool", async () => {
            await erc20.mint(account0, 10000000000);
        
            res = await poolAddressInstance.connect(account1).loanRequest(
              await erc20.getAddress(),
              poolId1,
              10000000000,
              loanDuration,
              expiration,
              1000,
              account1
            );
            // console.log(res.logs[0].args)
            loanId1 = 0;
        
            //  let res2 = await poolAddressInstance.calculateNextDueDate(loanId1)
            //  console.log(res2.toNumber())
            // console.log(paymentCycleAmount, "pca");
            expect(loanId1).to.equal(0);
          });
        
          it("should Accept loan ", async () => {
            await erc20.approve(await poolAddressInstance.getAddress(), 10000000000);
            let _balance1 = await erc20.balanceOf(account0);
            // console.log(_balance1.toNumber())
            res = await poolAddressInstance.AcceptLoan(loanId1);
            _balance1 = await erc20.balanceOf(account1);
            // console.log(_balance1.toNumber())
            //Amount that the borrower will get is 979 after cutting fees and market charges
            // expect(_balance1.toNumber(), 979, "Not able to accept loan");
          });
        
          it("anyone can repay Loan ", async () => {
            //First Installment
            await time.increase(paymentCycleDuration + 1);
            let rr = await poolAddressInstance.viewInstallmentAmount(loanId1);
            await erc20.approve(await poolAddressInstance.getAddress(), rr);
            res = await poolAddressInstance.repayMonthlyInstallment(loanId1);
            // console.log(res.logs[1]);
            // console.log(res.logs[0].args.Amount.toNumber());
        
            //Second installment
            await time.increase(1000);
            await expect(
              poolAddressInstance.connect(account1).repayMonthlyInstallment(loanId1)).to.be.revertedWithoutReason()
            //res = await poolAddressInstance.repayMonthlyInstallment(loanId1, { from: account1 })
            //console.log(res.logs[0].args.Amount.toNumber())
        
            //Full loan Repay
            let b = await poolAddressInstance.viewFullRepayAmount(loanId1);
            await erc20.approve(await poolAddressInstance.getAddress(), b);
            res = await poolAddressInstance.repayFullLoan(loanId1);
            // console.log(res.logs[0].args.Amount.toNumber());
        
            //Full loan repaid, should revert.
            await time.increase(paymentCycleDuration + 1);
        
            expect(
              (await poolAddressInstance.viewFullRepayAmount(loanId1))).to.equal(0);
            await erc20.approve(await poolAddressInstance.getAddress(), 205000000);
            await expect(
              poolAddressInstance.repayFullLoan(loanId1, { from: account0 })
            ).to.be.revertedWithoutReason();
          });

          it("should not allow closing pool if contract is paused", async () => {
            await poolRegis.pause();
      
            await expect(
              poolRegis.closePool(3)
            ).to.be.revertedWith("Pausable: paused");
      
            await poolRegis.unpause();
          });

          it("should not allow closing pool if caller is not pool owner", async () => {
      
            await expect(
              poolRegis.connect(random).closePool(3)
            ).to.be.revertedWith("Not the owner");
          });
      
    })
  })