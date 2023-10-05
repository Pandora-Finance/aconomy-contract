const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
  const { ethers } = require("hardhat");
  const moment = require("moment");
  const { BN } = require("@openzeppelin/test-helpers");
  
  describe("Pool Address", function (){
    let res, poolId1, pool1Address, expiration, poolId, bidId, bidId1, loanId1;
    // let aconomyFee, erc20, poolRegis;
    const erc20Amount = 10000000000;
    const paymentCycleDuration = moment.duration(30, "days").asSeconds();
    const loanDefaultDuration = moment.duration(180, "days").asSeconds();
    const loanExpirationDuration = moment.duration(2, "days").asSeconds();

    async function deployContractFactory() {
      [poolOwner, borrower, account2, receiver, random] = await ethers.getSigners();

      aconomyFee = await hre.ethers.deployContract("AconomyFee", []);
      await aconomyFee.waitForDeployment();

      await aconomyFee.setAconomyPoolFee(50)
      await aconomyFee.setAconomyPiMarketFee(50)
      await aconomyFee.setAconomyNFTLendBorrowFee(50)

      const attestRegistry = await hre.ethers.deployContract("AttestationRegistry", []);
      await attestRegistry.waitForDeployment();

      const attestServices = await hre.ethers.deployContract("AttestationServices", [attestRegistry.getAddress()]);
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
  
      return { aconomyFee, erc20, poolRegis, poolAddressInstance, poolOwner, borrower, account2, receiver, random };
    }
  
    describe("Deployment", function () {

      const advanceBlockAtTime = (time) => {
        return new Promise((resolve, reject) => {
          web3.currentProvider.send(
            {
              jsonrpc: "2.0",
              method: "evm_mine",
              params: [time],
              id: new Date().getTime(),
            },
            (err, _) => {
              if (err) {
                return reject(err);
              }
              const newBlockHash = web3.eth.getBlock("latest").hash;
  
              return resolve(newBlockHash);
            }
          );
        });
        
      };

      it("should create Pool", async () => {
        let { aconomyFee, erc20, poolRegis, poolAddressInstance, poolOwner, borrower, account2, receiver, random } = await deployContractFactory()
        res = await poolRegis.createPool(
          paymentCycleDuration,
          loanExpirationDuration,
          100,
          100,
          "sk.com",
          true,
          true
        );
        poolId1 = 1;
        // console.log(poolId1, "poolId1");
        pool1Address = await poolRegis.getPoolAddress(poolId1);
        // console.log(pool1Address, "poolAdress");
        res = await poolRegis.lenderVerification(poolId1, poolOwner);
        expect(
          res.isVerified_).to.equal(true);
        res = await poolRegis.borrowerVerification(poolId1, poolOwner);
        expect(
          res.isVerified_).to.equal(true);
      });
  
      it("should add Lender to the pool", async () => {
        res = await poolRegis.lenderVerification(poolId1, random);
        expect(
          res.isVerified_).to.equal(false)
        await poolRegis.addLender(poolId1, random);
        res = await poolRegis.lenderVerification(poolId1, random);
        expect(
          res.isVerified_).to.equal(true);
        await poolRegis.removeLender(poolId1, random);
        res = await poolRegis.lenderVerification(poolId1, random);
        expect(
          res.isVerified_).to.equal(false);
        await poolRegis.addLender(poolId1, random);
        res = await poolRegis.lenderVerification(poolId1, random);
        expect(
          res.isVerified_).to.equal(true);
      });
    
      it("should add Borrower to the pool", async () => {
        await poolRegis.addBorrower(poolId1, borrower);
        res = await poolRegis.borrowerVerification(poolId1, borrower);
        expect(
          res.isVerified_).to.equal(true);
        await poolRegis.removeBorrower(poolId1, borrower);
        res = await poolRegis.borrowerVerification(poolId1, borrower);
        expect(
          res.isVerified_).to.equal(false);
        await poolRegis.addBorrower(poolId1, borrower);
        res = await poolRegis.borrowerVerification(poolId1, borrower);
        expect(
          res.isVerified_).to.equal(true);
      });

      it("should not allow non owner to pause poolAddress", async () => {
        await expect(
          poolAddressInstance.connect(random).pause()
        ).to.be.revertedWith("Ownable: caller is not the owner");
  
        await poolAddressInstance.pause();
  
        await expect(
          poolAddressInstance.connect(random).unpause()
        ).to.be.revertedWith("Ownable: caller is not the owner");
  
        await poolAddressInstance.unpause();
      })
    
      it("testing loan request function", async () => {
        await aconomyFee.setAconomyPoolFee(100);
        await erc20.mint(poolOwner, "10000000000");
        res = await poolAddressInstance.connect(borrower).loanRequest(
          await erc20.getAddress(),
          poolId1,
          10000000000,
          loanDefaultDuration,
          loanExpirationDuration,
          100,
          borrower
        );
        loanId1 = 0;
        // let paymentCycleAmount = res.logs[0].args.paymentCycleAmount.toNumber();
        // console.log(paymentCycleAmount, "pca");
        expect(loanId1).to.equal(0);
        let loan = await poolAddressInstance.loans(loanId1);
        expect(loan.state).to.equal(0);
      });
    
      it("should not request if lending token is 0 address", async () => {
        await expect(poolAddressInstance.connect(borrower).loanRequest(
          "0x0000000000000000000000000000000000000000",
          poolId1,
          10000000000,
          loanDefaultDuration,
          loanExpirationDuration,
          100,
          borrower
        )).to.be.revertedWithoutReason()
      })
    
      it("should not request if receiver is 0 address", async () => {
        await expect(poolAddressInstance.connect(borrower).loanRequest(
          await erc20.getAddress(),
          poolId1,
          10000000000,
          loanDefaultDuration,
          loanExpirationDuration,
          100,
          "0x0000000000000000000000000000000000000000"
        )).to.be.revertedWithoutReason()
      })
    
      it("should not request if lender is unverified", async () => {
        await expect(poolAddressInstance.connect(receiver).loanRequest(
          await erc20.getAddress(),
          poolId1,
          10000000000,
          loanDefaultDuration,
          loanExpirationDuration,
          100,
          borrower
        )).to.be.revertedWithoutReason()
      })
    
      it("should not request if duration is not divisible by 30", async () => {
        await expect(poolAddressInstance.connect(borrower).loanRequest(
          await erc20.getAddress(),
          poolId1,
          10000000000,
          loanDefaultDuration + 1,
          loanExpirationDuration,
          100,
          borrower
        )).to.be.revertedWithoutReason()
      })
    
      it("should not request if apr < 100", async () => {
        await expect(poolAddressInstance.connect(borrower).loanRequest(
          await erc20.getAddress(),
          poolId1,
          10000000000,
          loanDefaultDuration,
          loanExpirationDuration,
          10,
          borrower
        )).to.be.revertedWithoutReason()
      })
    
      it("should not request if principal < 1000000", async () => {
        await expect(poolAddressInstance.connect(borrower).loanRequest(
          await erc20.getAddress(),
          poolId1,
          100000,
          loanDefaultDuration,
          loanExpirationDuration,
          100,
          borrower
        )).to.be.revertedWith('low')
      })
    
      it("should not request if expiration duration is 0", async () => {
        await expect(poolAddressInstance.connect(borrower).loanRequest(
          await erc20.getAddress(),
          poolId1,
          10000000000,
          loanDefaultDuration,
          0,
          100,
          borrower
        )).to.be.revertedWithoutReason()
      })
    
      it("should not request if the contract is paused", async () => {
        await poolAddressInstance.pause();
        await expect(
          poolAddressInstance.connect(borrower).loanRequest(
            await erc20.getAddress(),
            poolId1,
            10000000000,
            loanDefaultDuration,
            loanExpirationDuration,
            100,
            borrower
          )
        ).to.be.revertedWith('Pausable: paused')
        await poolAddressInstance.unpause();
      });
    
      it("should not accept loan if caller is not lender", async () => {
        await erc20.connect(account2).approve(await poolAddressInstance.getAddress(), 10000000000);
        await expect(poolAddressInstance.connect(account2).AcceptLoan(loanId1)).to.be.revertedWith("Not verified lender")
      })

      it("should not accept loan if contract is paused", async () => {
        await poolAddressInstance.pause();

        await erc20.approve(await poolAddressInstance.getAddress(), 10000000000);
  
        await expect(
          poolAddressInstance.AcceptLoan(loanId1)
        ).to.be.revertedWith("Pausable: paused");
  
        await poolAddressInstance.unpause();
      });
    
      it("should Accept loan ", async () => {
        await aconomyFee.transferOwnership(random);
        let feeAddress = await aconomyFee.getAconomyOwnerAddress();
        await aconomyFee.connect(random).setAconomyPoolFee(200);
        expect(feeAddress, await random.getAddress());
        let b1 = await erc20.balanceOf(feeAddress);
        // console.log("fee 1", b1.toNumber());
        await erc20.approve(await poolAddressInstance.getAddress(), 10000000000);
        let _balance1 = await erc20.balanceOf(poolOwner);
        // console.log(_balance1.toNumber());
        res = await poolAddressInstance.AcceptLoan(loanId1);
        let b2 = await erc20.balanceOf(feeAddress);
        // console.log("fee 2", b2.toNumber());
        expect(b2 - b1).to.equal(100000000);
        _balance1 = await erc20.balanceOf(borrower);
        //console.log(_balance1.toNumber())
        //Amount that the borrower will get is 999 after cutting fees and market charges
        expect(_balance1).to.equal(9800000000);
        let loan = await poolAddressInstance.loans(loanId1);
        expect(loan.state).to.equal(2)
      });
    
      it("should not accept loan if loan is not pending", async () => {
        await erc20.approve(await poolAddressInstance.getAddress(), 10000000000);
        await expect(poolAddressInstance.AcceptLoan(loanId1)).to.be.revertedWith("loan not pending")
      })
    
      it("should calculate the next due date", async () => {
        //loanId1 = res.logs[0].args.loanId.toNumber();
        let loan = await poolAddressInstance.loans(loanId1);
        
        let dueDate = await poolAddressInstance.calculateNextDueDate(loanId1);
        let acceptedTimeStamp = new BN(loan.loanDetails.acceptedTimestamp)
        let paymentCycle = await new BN(loan.terms.paymentCycle)
        expect(`${new BN(dueDate)}`).to.equal(`${acceptedTimeStamp.add(paymentCycle)}`);
      });
    
      it("should not work after the loan expires", async () => {
        let r = await poolAddressInstance.isLoanExpired(loanId1);
        expect(r).to.equal(false);
      });
    
      it("should check the payment done in time", async () => {
        let r = await poolAddressInstance.isPaymentLate(loanId1);
        expect(r).to.equal(false);
      });
    
      it("should view and pay 1st intallment amount", async () => {
        let loan = await poolAddressInstance.loans(loanId1);
        //console.log(loan);
        // let r = await poolAddressInstance.viewInstallmentAmount(loanId1);
        // console.log("installment before 1 cycle", r.toString());
        // advanceBlockAtTime(loan.loanDetails.lastRepaidTimestamp + paymentCycleDuration + 20)
        await time.increase(paymentCycleDuration + 50000);
        //1
        let dueDate = await poolAddressInstance.calculateNextDueDate(loanId1);
        let acceptedTimeStamp = await new BN(loan.loanDetails.acceptedTimestamp)
        let paymentCycle = await new BN(loan.terms.paymentCycle)
        expect(`${new BN(dueDate)}`).to.equal(`${acceptedTimeStamp.add(paymentCycle)}`);
        
        let r = await poolAddressInstance.viewInstallmentAmount(loanId1);
        console.log(acceptedTimeStamp.toString())
        console.log(await time.latest())
        console.log("installment after 1 cycle", r.toString());
    
        await erc20.connect(borrower).approve(await poolAddressInstance.getAddress(), r);
        let result = await poolAddressInstance.connect(borrower).repayMonthlyInstallment(loanId1);
    
        loan = await poolAddressInstance.loans(loanId1);
        expect(loan.loanDetails.lastRepaidTimestamp).to.equal(
          new BN(loan.loanDetails.acceptedTimestamp).add(
            new BN(loan.terms.paymentCycle)
          )
        );
        expect(
          loan[4][2][0] + loan[4][2][1]).to.equal(loan.terms.paymentCycleAmount
        );
        await time.increase(100);
        // r = await poolAddressInstance.viewInstallmentAmount(loanId1);
        // console.log("installment after paying 1st cycle", r.toString());
      });
    
      it("should continue paying installments after skipping a cycle", async () => {
        let loan = await poolAddressInstance.loans(loanId1);
        expect(await poolAddressInstance.isPaymentLate(loanId1)).to.equal(false);
        let now = await erc20.getTime();
        // console.log(now.toString());
        await time.increase(paymentCycleDuration + paymentCycleDuration + 604800);
        now = await erc20.getTime();
        // console.log(now.toString());
        expect(await poolAddressInstance.isPaymentLate(loanId1)).to.equal(true);
        let dueDate = await poolAddressInstance.calculateNextDueDate(loanId1);
        let acceptedTimeStamp = new BN(loan.loanDetails.acceptedTimestamp)
        let paymentCycle = await new BN(loan.terms.paymentCycle)
        expect(`${new BN(dueDate)}`).to.equal(`${acceptedTimeStamp.add(paymentCycle.mul(new BN(2)))}`);
        //2
        let r = await poolAddressInstance.viewInstallmentAmount(loanId1);
        await erc20.connect(borrower).approve(await poolAddressInstance.getAddress(), r);
        await poolAddressInstance.connect(borrower).repayMonthlyInstallment(loanId1);
    
        loan = await poolAddressInstance.loans(loanId1);
        expect(loan.loanDetails.lastRepaidTimestamp).to.equal(
            new BN(loan.loanDetails.acceptedTimestamp).add((
              new BN(loan.terms.paymentCycle).mul(new BN(2)))
            )
          );
        expect(loan.terms.installmentsPaid).to.equal(2);
        expect(await poolAddressInstance.isPaymentLate(loanId1)).to.equal(true);
        //3
        dueDate = await poolAddressInstance.calculateNextDueDate(loanId1);
        expect(`${new BN(dueDate)}`).to.equal(`${acceptedTimeStamp.add(paymentCycle.mul(new BN(3)))}`);
    
        r = await poolAddressInstance.viewInstallmentAmount(loanId1);
        await erc20.connect(borrower).approve(await poolAddressInstance.getAddress(), r);

        await poolAddressInstance.pause();
  
        await expect(
          poolAddressInstance.connect(borrower).repayMonthlyInstallment(loanId1)
        ).to.be.revertedWith("Pausable: paused");
  
        await poolAddressInstance.unpause();

        await poolAddressInstance.connect(borrower).repayMonthlyInstallment(loanId1);
    
        loan = await poolAddressInstance.loans(loanId1);
        expect(loan.loanDetails.lastRepaidTimestamp).to.equal(
            new BN(loan.loanDetails.acceptedTimestamp).add((
              new BN(loan.terms.paymentCycle).mul(new BN(3)))
            )
          );
        expect(loan.terms.installmentsPaid).to.equal(3);
        expect(await poolAddressInstance.isPaymentLate(loanId1)).to.equal(false);
        //4
        dueDate = await poolAddressInstance.calculateNextDueDate(loanId1);
        expect(`${new BN(dueDate)}`).to.equal(`${acceptedTimeStamp.add(paymentCycle.mul(new BN(4)))}`);
    
        let full1 = await poolAddressInstance.viewFullRepayAmount(loanId1);
        await time.increase(1800)
        let full2 = await poolAddressInstance.viewFullRepayAmount(loanId1);
        expect(full1.toString()).to.equal(full2.toString())
    
        await time.increase(paymentCycleDuration - 1800);
        r = await poolAddressInstance.viewInstallmentAmount(loanId1);
        await erc20.connect(borrower).approve(await poolAddressInstance.getAddress(), r);
        await poolAddressInstance.connect(borrower).repayMonthlyInstallment(loanId1);
    
        loan = await poolAddressInstance.loans(loanId1);
        expect(loan.loanDetails.lastRepaidTimestamp).to.equal(
            new BN(loan.loanDetails.acceptedTimestamp).add((
              new BN(loan.terms.paymentCycle).mul(new BN(4)))
            )
          );
        expect(loan.terms.installmentsPaid).to.equal(4);
        expect(await poolAddressInstance.isPaymentLate(loanId1)).to.equal(false);
        //5
        dueDate = await poolAddressInstance.calculateNextDueDate(loanId1);
        expect(`${new BN(dueDate)}`).to.equal(`${acceptedTimeStamp.add(paymentCycle.mul(new BN(5)))}`);
    
        await time.increase(paymentCycleDuration);
        r = await poolAddressInstance.viewInstallmentAmount(loanId1);
        await erc20.connect(borrower).approve(await poolAddressInstance.getAddress(), r);
        await poolAddressInstance.connect(borrower).repayMonthlyInstallment(loanId1);
    
        loan = await poolAddressInstance.loans(loanId1);
        expect(loan.loanDetails.lastRepaidTimestamp).to.equal(
            new BN(loan.loanDetails.acceptedTimestamp).add((
              new BN(loan.terms.paymentCycle).mul(new BN(5)))
            )
          );
        expect(loan.terms.installmentsPaid).to.equal(5);
        expect(await poolAddressInstance.isPaymentLate(loanId1)).to.equal(false);
        //6
        dueDate = await poolAddressInstance.calculateNextDueDate(loanId1);
        expect(`${new BN(dueDate)}`).to.equal(`${acceptedTimeStamp.add(paymentCycle.mul(new BN(6)))}`);
    
        await time.increase(paymentCycleDuration);
        await erc20.mint(borrower, "1000000000");
        r = await poolAddressInstance.viewInstallmentAmount(loanId1);
        // let full = await poolAddressInstance.viewFullRepayAmount(loanId1);
        await erc20.connect(borrower).approve(await poolAddressInstance.getAddress(), r);
        // console.log("full", full.toString());
        await poolAddressInstance.connect(borrower).repayMonthlyInstallment(loanId1);
    
        loan = await poolAddressInstance.loans(loanId1);
        // expect(loan.loanDetails.lastRepaidTimestamp,
        //   BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(6))
        //   ));
        expect(loan.terms.installmentsPaid).to.equal(5);
        expect(loan.state).to.equal(3);
      });

      it("should show loan is not defaulted if state is not accepted", async () => {
        let r = await poolAddressInstance.isLoanDefaulted(loanId1)
        expect(r).to.equal(false)
      })

      it("should show payment is not late if state is not accepted", async () => {
        let r = await poolAddressInstance.isPaymentLate(loanId1)
        expect(r).to.equal(false)
      })

      it("should return due date of 0 if state is not accepted", async () => {
        let r = await poolAddressInstance.calculateNextDueDate(loanId1)
        expect(r).to.equal(0)
      })
    
      it("should not allow further payment after the loan has been repaid", async () => {
        await expect(poolAddressInstance.connect(borrower).repayMonthlyInstallment(loanId1)).to.be.revertedWithoutReason()
      })
    
      it("should check that full repayment amount is 0", async () => {
        let loan = await poolAddressInstance.loans(loanId1);
        advanceBlockAtTime(
          new BN(loan.loanDetails.lastRepaidTimestamp).add(new BN(paymentCycleDuration + 20))
        );
        let bal = await poolAddressInstance.viewFullRepayAmount(loanId1);
        // console.log(bal.toNumber());
        expect(bal).to.equal(0);
      });
    
      it("should request another loan", async () => {
        res = await poolAddressInstance.connect(borrower).loanRequest(
          await erc20.getAddress(),
          poolId1,
          10000000000,
          loanDefaultDuration,
          loanExpirationDuration,
          100,
          borrower
        );
        loanId1 = 1;
        // console.log(paymentCycleAmount, "pca");
        expect(loanId1).to.equal(1);
      });
    
      it("should Accept loan ", async () => {
        await erc20.approve(await poolAddressInstance.getAddress(), 10000000000);
        let _balance1 = await erc20.balanceOf(poolOwner);
        // console.log(_balance1.toNumber());
        res = await poolAddressInstance.AcceptLoan(loanId1);
        _balance1 = await erc20.balanceOf(borrower);
      });
    
      it("should repay full amount", async () => {
        let loan = await poolAddressInstance.loans(loanId1);
        advanceBlockAtTime(
            new BN(loan.loanDetails.lastRepaidTimestamp).add(new BN(paymentCycleDuration + 20))
        );
        let bal = await poolAddressInstance.viewFullRepayAmount(loanId1);
        // console.log(bal.toNumber());
        let b = await erc20.balanceOf(borrower);
        //await erc20.transfer(borrower, bal - b + 10, { from: poolOwner })
        await erc20.connect(borrower).approve(await poolAddressInstance.getAddress(), bal);
        await poolAddressInstance.pause();
  
        await expect(
          poolAddressInstance.connect(borrower).repayFullLoan(loanId1)
        ).to.be.revertedWith("Pausable: paused");
  
        await poolAddressInstance.unpause();
        let r = await poolAddressInstance.connect(borrower).repayFullLoan(loanId1);
        // console.log(res)
      });
    
      it("should not allow further payment after the loan has been repaid", async () => {
        await expect(poolAddressInstance.connect(borrower).repayFullLoan(loanId1)).to.be.revertedWithoutReason()
      })
    
      it("should check that full repayment amount is 0", async () => {
        let loan = await poolAddressInstance.loans(loanId1);
        advanceBlockAtTime(
            new BN(loan.loanDetails.lastRepaidTimestamp).add(new BN(paymentCycleDuration + 20))
        );
        let bal = await poolAddressInstance.viewFullRepayAmount(loanId1);
        // console.log(bal.toNumber());
        expect(bal).to.equal(0);
      });
    
      it("should request another loan", async () => {
        res = await poolAddressInstance.connect(borrower).loanRequest(
          await erc20.getAddress(),
          poolId1,
          10000000000,
          loanDefaultDuration,
          loanExpirationDuration,
          100,
          borrower
        );
        loanId1 = 2
        // console.log(paymentCycleAmount, "pca");
        expect(loanId1).to.equal(2);
      });
    
      it("should expire after the expiry deadline", async () => {
        await time.increase(loanExpirationDuration + 1);
        let r = await poolAddressInstance.isLoanExpired(loanId1);
        expect(r).to.equal(true);
      });
    
      it("should not allow an expired loan to be accepted", async () => {
        await expect(
          poolAddressInstance.AcceptLoan(loanId1)
        ).to.be.revertedWithoutReason()
      });
    
      it("should request another loan", async () => {
        //await erc20.mint(poolOwner, '10000000000')
        res = await poolAddressInstance.connect(borrower).loanRequest(
          await erc20.getAddress(),
          poolId1,
          10000000000,
          loanDefaultDuration,
          loanExpirationDuration,
          100,
          borrower
        );
        loanId1 = 3;
        // console.log(paymentCycleAmount, "pca");
        expect(loanId1).to.equal(3);
      });
    
      it("should Accept loan ", async () => {
        await erc20.approve(await poolAddressInstance.getAddress(), 10000000000);
        let _balance1 = await erc20.balanceOf(poolOwner);
        // console.log(_balance1.toNumber());
        res = await poolAddressInstance.AcceptLoan(loanId1);
        _balance1 = await erc20.balanceOf(borrower);
      });
    
      it("should show loan defaulted", async () => {
        await time.increase(loanDefaultDuration + paymentCycleDuration - 10);
        let r = await poolAddressInstance.isLoanDefaulted(loanId1);
        expect(r).to.equal(false);
        await time.increase(11);
        r = await poolAddressInstance.isLoanDefaulted(loanId1);
        expect(r).to.equal(true);
      });
    
      it("should request loan again, this time 1 usdt", async () => {
    
        await expect(poolAddressInstance.connect(borrower).loanRequest(
          await erc20.getAddress(),
          poolId1,
          100000,
          loanDefaultDuration,
          loanExpirationDuration,
          100,
          borrower
        )).to.be.revertedWith("low")
    
        res = await poolAddressInstance.connect(borrower).loanRequest(
          await erc20.getAddress(),
          poolId1,
          1000000,
          loanDefaultDuration,
          loanExpirationDuration,
          100,
          borrower
        );
        loanId1 = 4;
        // console.log(paymentCycleAmount, "pca");
        expect(loanId1).to.equal(4);
      });
    
      it("should accept the loan", async () => {
        await erc20.approve(await poolAddressInstance.getAddress(), 1000000);
        res = await poolAddressInstance.AcceptLoan(loanId1);
      });
    
      it("should not allow monthly installments as amount is too low", async () => {
        r = await poolAddressInstance.viewInstallmentAmount(loanId1);
        
        await erc20.approve(await poolAddressInstance.getAddress(), r);
    
        await expect(
          poolAddressInstance.connect(borrower).repayMonthlyInstallment(loanId1)).to.be.revertedWith(
          "low"
        );
      })
    
      it("should repay the full amount", async () => {
        let bal = await poolAddressInstance.viewFullRepayAmount(loanId1);
    
        expect(bal).to.equal(1000000);
    
        await time.increase(3600);
    
        bal = await poolAddressInstance.viewFullRepayAmount(loanId1);
    
        console.log(bal.toString())
        
        await erc20.approve(await poolAddressInstance.getAddress(), bal);
    
        let r = await poolAddressInstance.repayFullLoan(loanId1);
      })

      it("should request another loan", async () => {
        await aconomyFee.connect(random).setAconomyPoolFee(0);
        res = await poolAddressInstance.connect(borrower).loanRequest(
          await erc20.getAddress(),
          poolId1,
          10000000000,
          loanDefaultDuration,
          loanExpirationDuration,
          100,
          borrower
        );
        loanId1 = 5
        
        expect(loanId1).to.equal(5);
      })

      it("should accept loan with aconomy fee of 0", async () => {
        await erc20.approve(await poolAddressInstance.getAddress(), 10000000000);
        let b1 = await erc20.balanceOf(borrower.getAddress())
        res = await poolAddressInstance.AcceptLoan(loanId1);
        let b2 = await erc20.balanceOf(borrower.getAddress())
        expect(b2 - b1).to.equal(9900000000)
      })
    
      it("should request another loan", async () => {
        res = await poolAddressInstance.connect(borrower).loanRequest(
          await erc20.getAddress(),
          poolId1,
          1000000,
          loanDefaultDuration,
          loanExpirationDuration,
          100,
          borrower
        );
        loanId1 = 6
        
        expect(loanId1).to.equal(6);
      })
    
      it("should close the pool", async () => {
        await poolRegis.closePool(poolId1)
        let closed = await poolRegis.ClosedPool(poolId1);
        expect(closed).to.equal(true);
      })
    
      it("should not request loan in a closed pool", async () => {
        await expect(poolAddressInstance.connect(borrower).loanRequest(
          await erc20.getAddress(),
          poolId1,
          10000000000,
          loanDefaultDuration,
          loanExpirationDuration,
          100,
          borrower
        )).to.be.revertedWithoutReason()
      })
    
      it("should not allow accepting the loan in a closed pool", async () => {
        await expect(poolAddressInstance.AcceptLoan(loanId1)).to.be.revertedWith( 
        "pool closed"
        )
      })
    })
  })