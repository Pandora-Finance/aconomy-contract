const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
  const { ethers } = require("hardhat");
  const moment = require("moment");
  const { BN } = require("@openzeppelin/test-helpers");
  
  describe("Funding pool", function (){
    let fundingpoolInstance, res, poolId1, pool1Address, expiration, poolId, bidId, bidId1;
    // let aconomyFee, erc20, poolRegis;
    const erc20Amount = 10000000000;
    const paymentCycleDuration = moment.duration(30, "days").asSeconds();
    const loanDefaultDuration = moment.duration(180, "days").asSeconds();
    const loanExpirationDuration = moment.duration(1, "days").asSeconds();

    async function deployContractFactory() {
      [poolOwner, lender, nonLender, receiver, newFeeOwner] = await ethers.getSigners();

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
  
      const mintToken = await hre.ethers.deployContract("mintToken", ["100000000000"]);
      erc20 = await mintToken.waitForDeployment();
  
      return { aconomyFee, erc20, poolRegis, poolOwner, lender, nonLender, receiver, newFeeOwner };
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
        let { aconomyFee, erc20, poolRegis, poolOwner, lender, nonLender, receiver } = await deployContractFactory()
        await aconomyFee.setAconomyPoolFee(100);
        const feee = await aconomyFee.AconomyPoolFee();
        // console.log("protocolFee", feee.toString());
        res = await poolRegis.connect(poolOwner).createPool(
            loanExpirationDuration,
            loanExpirationDuration,
            100,
            1000,
            "sk.com",
            true,
            true
        );
        poolId1 = 1;
        // console.log(poolId1, "poolId1");
        poolId = poolId1;
        pool1Address = await poolRegis.getPoolAddress(poolId1);
        fundingpooladdress = pool1Address;
        res = await poolRegis.lenderVerification(poolId1, poolOwner);
        expect(res.isVerified_).to.equal(true)
        res = await poolRegis.borrowerVerification(poolId1, poolOwner);
        expect(res.isVerified_).to.equal(true)
      });
  
      it("should add Lender to the pool", async () => {
        //const { aconomyFee, erc20, poolRegis, poolOwner, lender, nonLender, receiver } = await loadFixture(deployContractFactory)
        pool1Address = await poolRegis.getPoolAddress(poolId1);
        res = await poolRegis.lenderVerification(poolId1, lender);
        expect(res.isVerified_).to.equal(false)
        await poolRegis.addLender(poolId1, lender, { from: poolOwner });
        res = await poolRegis.lenderVerification(poolId1, lender);
        expect(
          res.isVerified_).to.equal(true)
      });
  
      it("should add Borrower to the pool", async () => {
        await poolRegis.addBorrower(poolId1, nonLender, { from: poolOwner });
        res = await poolRegis.borrowerVerification(poolId1, nonLender);
        expect(
          res.isVerified_,
          true,
          "Borrower Not added to pool, borrowerVarification failed"
        );
      });
  
      it("should allow lender to supply funds to the pool", async () => {
        const provider = ethers.provider;
        const currentBlock = await provider.getBlockNumber();
        const blockTimestamp = (await provider.getBlock(currentBlock)).timestamp;
        expiration = blockTimestamp + 3600;
        let fundingpooladdress = await poolRegis.getPoolAddress(poolId1);
        console.log(fundingpooladdress)
        fundingpoolInstance = await hre.ethers.getContractAt("FundingPool", fundingpooladdress);
  
        await erc20.connect(poolOwner).transfer(await lender.getAddress(), erc20Amount);
  
        await erc20.connect(lender).approve(await fundingpoolInstance.getAddress(), erc20Amount);
        const tx = await fundingpoolInstance.connect(lender).supplyToPool(
          poolId,
          await erc20.getAddress(),
          erc20Amount,
          loanDefaultDuration,
          expiration,
          1000
        );
        bidId = 0;
        //console.log(bidId, "bidid111");
  
        await erc20.connect(poolOwner).transfer(await lender.getAddress(), 10000000000);
        await erc20.connect(lender).approve(await fundingpoolInstance.getAddress(), 10000000000);
  
        const tx1 = await fundingpoolInstance.connect(lender).supplyToPool(
          poolId,
          await erc20.getAddress(),
          10000000000,
          loanDefaultDuration,
          expiration,
          1000
        );
        bidId1 = 1;
        const balance = await erc20.balanceOf(lender);
        expect(balance).to.equal(0)
  
        // console.log(bidId1, "bidid");
        // console.log(tx.logs[0].args);
        const fundDetail = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId
        );
        // console.log(fundDetail);
        expect(fundDetail.amount).to.equal(erc20Amount);
        expect(fundDetail.maxDuration).to.equal(loanDefaultDuration);
        expect(fundDetail.interestRate).to.equal(1000);
        // console.log(expiration.toString());
        expect(fundDetail.expiration).to.equal(expiration.toString());
        expect(fundDetail.state).to.equal(0); // BidState.PENDING
      });
  
      it("should not allow non-lender to supply funds to the pool", async () => {
        const provider = ethers.provider;
        const currentBlock = await provider.getBlockNumber();
        const blockTimestamp = (await provider.getBlock(currentBlock)).timestamp;
        expiration = blockTimestamp + 3600;
        await erc20.connect(nonLender).approve(await fundingpoolInstance.getAddress(), erc20Amount);
        await expect(
          fundingpoolInstance.connect(nonLender).supplyToPool(
            poolId,
            await erc20.getAddress(),
            erc20Amount,
            loanDefaultDuration,
            expiration,
            1000
          )).to.be.revertedWith("Not verified lender")
      });
  
      it("should not allow lender to supply 0 address to the pool", async () => {
        const provider = ethers.provider;
        const currentBlock = await provider.getBlockNumber();
        const blockTimestamp = (await provider.getBlock(currentBlock)).timestamp;
        expiration = blockTimestamp + 3600;
        await erc20.connect(lender).approve(await fundingpoolInstance.getAddress(), erc20Amount);
        await expect(
          fundingpoolInstance.connect(lender).supplyToPool(
            poolId,
            "0x0000000000000000000000000000000000000000",
            erc20Amount,
            loanDefaultDuration,
            expiration,
            1000
          )).to.be.revertedWith("you can't do this with zero address")
      });
  
      it("should not allow lender to input a duration not divisible by 30 days", async () => {
        const provider = ethers.provider;
        const currentBlock = await provider.getBlockNumber();
        const blockTimestamp = (await provider.getBlock(currentBlock)).timestamp;
        expiration = blockTimestamp + 3600;
        await erc20.connect(lender).approve(await fundingpoolInstance.getAddress(), erc20Amount);
        await expect(
          fundingpoolInstance.supplyToPool(
            poolId,
            await erc20.getAddress(),
            erc20Amount,
            loanDefaultDuration + 1,
            expiration,
            1000,
            { from: lender }
          )
        );
      });
  
      it("should not allow lender to supply an apr less than 100 bps", async () => {
        const provider = ethers.provider;
        const currentBlock = await provider.getBlockNumber();
        const blockTimestamp = (await provider.getBlock(currentBlock)).timestamp;
        expiration = blockTimestamp + 3600;
        await erc20.connect(lender).approve(await fundingpoolInstance.getAddress(), erc20Amount);
        await expect(
          fundingpoolInstance.connect(lender).supplyToPool(
            poolId,
            await erc20.getAddress(),
            erc20Amount,
            loanDefaultDuration,
            expiration,
            10
          )).to.be.revertedWith("apr too low")
      });
  
      it("should not allow lender to supply 100000 amount to the pool", async () => {
        const provider = ethers.provider;
        const currentBlock = await provider.getBlockNumber();
        const blockTimestamp = (await provider.getBlock(currentBlock)).timestamp;
        expiration = blockTimestamp + 3600;
        await erc20.connect(lender).approve(await fundingpoolInstance.getAddress(), erc20Amount);
        await expect(
          fundingpoolInstance.connect(lender).supplyToPool(
            poolId,
            await erc20.getAddress(),
            100000,
            loanDefaultDuration,
            expiration,
            1000
          )).to.be.revertedWith("amount too low")
      });
  
      it("should not allow lender to supply a faulty expiration", async () => {
        const provider = ethers.provider;
        const currentBlock = await provider.getBlockNumber();
        const blockTimestamp = (await provider.getBlock(currentBlock)).timestamp;
        expiration = blockTimestamp + 3600;
        await erc20.connect(lender).approve(await fundingpoolInstance.getAddress(), erc20Amount);
        await expect(
          fundingpoolInstance.connect(lender).supplyToPool(
            poolId,
            await erc20.getAddress(),
            erc20Amount,
            loanDefaultDuration,
            10,
            1000
          )).to.be.revertedWith("wrong timestamp")
      });
  
      it("should not allow non-lender to cancel a bid", async () => {
        await expect(
          fundingpoolInstance.connect(nonLender).Withdraw(poolId, await erc20.getAddress(), bidId, lender)).to.be.revertedWith("You are not a Lender")
      });
  
      it("should accept the bid and emit AcceptedBid event", async () => {
        await aconomyFee.transferOwnership(newFeeOwner);
        let feeAddress = await aconomyFee.getAconomyOwnerAddress();
        await aconomyFee.connect(newFeeOwner).setAconomyPoolFee(200);
        expect(feeAddress).to.equal(await newFeeOwner.getAddress());
        const feee = await aconomyFee.AconomyPoolFee();
        // console.log("protocolFee", feee.toString());
        let b1 = await erc20.balanceOf(feeAddress);
  
        await expect(fundingpoolInstance.connect(receiver).AcceptBid(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender,
          receiver
        )).to.be.revertedWith("You are not the Pool Owner")
  
        // console.log("owner1", b1.toString());
        const tx = await fundingpoolInstance.AcceptBid(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender,
          receiver
        );
        let b2 = await erc20.balanceOf(feeAddress);
        // console.log("owner2", b2.toString());
        // console.log(poolId);
        expect(b2 - b1).to.equal(100000000);
        // const expectedPaymentCycleAmount = ethers.utils.parseEther('0.421875'); // calculated using LibCalculations      // expect(tx)
        //   .to.emit(fundingpoolInstance, 'AcceptedBid')
        //   .withArgs(
        //     receiver,
        //     bidId,
        //     poolId,
        //     ethers.utils.parseEther('10'),
        //     expectedPaymentCycleAmount
        //   );
  
        const fundDetail = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId
        );
        expect(fundDetail.state).to.equal(1); // BidState.ACCEPTED
        // expect(fundDetail.paymentCycleAmount).to.equal(
        //   expectedPaymentCycleAmount
        // );
        expect(fundDetail.acceptBidTimestamp).to.not.equal(moment.now());
        // expect(bidid)
      });
      it("should revert if bid is not pending", async function () {
        // await fundingpoolInstance.AcceptBid(
        //   poolId,
        //   await erc20.getAddress(),
        //   bidId,
        //   lender,
        //   receiver
        // );
        await expect(
          fundingpoolInstance.AcceptBid(
            poolId,
            await erc20.getAddress(),
            bidId,
            lender,
            receiver
          ),
          "Bid must be pending"
        );
      });
  
      it("should revert reject if bid is not pending", async () => {
        await expect(
          fundingpoolInstance.RejectBid(
            poolId,
            await erc20.getAddress(),
            bidId,
            lender
          ), "Bid must be pending"
        )
      })
  
      it("should reject the bid and emit RejectBid event", async () => {
        const balance = await erc20.balanceOf(lender);
        // console.log("bbb", balance.toString());
        const tx = await fundingpoolInstance.RejectBid(
          poolId,
          await erc20.getAddress(),
          bidId1,
          lender
        );
  
        const fundDetail = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId1
        );
        expect(fundDetail.state).to.equal(4); 
        // console.log(poolId)
        const balance1 = await erc20.balanceOf(lender);
        // console.log("bbb", balance1.toString());
        expect(balance1).to.equal(10000000000);
  
        await expect(
          fundingpoolInstance.connect(lender).RejectBid(poolId, await erc20.getAddress(), bidId1, lender)).to.be.revertedWith("You are not the Pool Owner")
        // const expectedPaymentCycleAmount = ethers.utils.parseEther('0.421875'); // calculated using LibCalculations      // expect(tx)
        //   .to.emit(fundingpoolInstance, 'AcceptedBid')
        //   .withArgs(
        //     receiver,
        //     bidId,
        //     poolId,
        //     ethers.utils.parseEther('10'),
        //     expectedPaymentCycleAmount
        //   );
      });
  
      it("should not allow cancelling a bid that is not pending", async () => {
        await expect(
          fundingpoolInstance.connect(lender).Withdraw(poolId, await erc20.getAddress(), bidId, lender)).to.be.revertedWith("Bid must be pending");
      });
  
      it("should view and pay 1st intallment amount", async () => {
        loanId1 = bidId;
        let loan = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId
        );
        // console.log(loan);
        let r = await fundingpoolInstance.viewInstallmentAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        // console.log("installment before 1 cycle", r.toString());
        // advanceBlockAtTime(loan.loanDetails.lastRepaidTimestamp + paymentCycleDuration + 20)
        await time.increase(paymentCycleDuration + 5);
        r = await fundingpoolInstance.viewInstallmentAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        // console.log("installment after 1 cycle", r.toString());
        //1
        let dueDate = await fundingpoolInstance.calculateNextDueDate(poolId, await erc20.getAddress(), bidId, lender);
        let acceptedTimeStamp = loan.acceptBidTimestamp
        let paymentCycle = paymentCycleDuration
        expect(`${new BN(dueDate)}`).to.equal(`${new BN(acceptedTimeStamp).add(new BN(paymentCycle).mul(new BN(1)))}`);
  
        await erc20.approve(await fundingpoolInstance.getAddress(), r);
        await erc20.connect(receiver).approve(await fundingpoolInstance.getAddress(), r);
  
        await expect(fundingpoolInstance.connect(receiver).repayMonthlyInstallment(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender)).to.be.revertedWith("You are not the Pool Owner")
  
        let result = await fundingpoolInstance.repayMonthlyInstallment(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
  
        loan = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId
        );
        console.log(loan[11])
        // console.log(result.logs[0].args.PaidAmount);
        expect(
          loan[11][0] + loan[11][1]).to.equal(loan.paymentCycleAmount
        );
        await time.increase(100);
        r = await fundingpoolInstance.viewInstallmentAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        // console.log("installment after paying 1st cycle", r.toString());
      });
  
      it("should continue paying installments after skipping a cycle", async () => {
        loanId1 = bidId;
        let loan = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId
        );
        expect(
          await fundingpoolInstance.isPaymentLate(
            poolId,
            await erc20.getAddress(),
            bidId,
            lender
          )).to.equal(false
        );
        let now = await erc20.getTime();
        // console.log(now.toString());
        await time.increase(paymentCycleDuration + paymentCycleDuration + 604800);
        now = await erc20.getTime();
        // console.log(now.toString());
        expect(
          await fundingpoolInstance.isPaymentLate(
            poolId,
            await erc20.getAddress(),
            bidId,
            lender
          )).to.equal(true
        );
        //2
        let dueDate = await fundingpoolInstance.calculateNextDueDate(poolId, await erc20.getAddress(), bidId, lender);
        let acceptedTimeStamp = new BN(loan.acceptBidTimestamp)
        let paymentCycle = new BN(paymentCycleDuration)
        expect(`${new BN(dueDate)}`).to.equal(`${acceptedTimeStamp.add(paymentCycle.mul(new BN(2)))}`);
  
        let r = await fundingpoolInstance.viewInstallmentAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        expect(loan.paymentCycleAmount.toString()).to.equal(r.toString());
        await erc20.approve(await fundingpoolInstance.getAddress(), r);
        await fundingpoolInstance.repayMonthlyInstallment(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
  
        loan = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId
        );
        // expect(loan.loanDetails.lastRepaidTimestamp,
        //   BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(2))
        //   ));
        expect(loan.installment.installmentsPaid).to.equal(2);
        expect(
          await fundingpoolInstance.isPaymentLate(
            poolId,
            await erc20.getAddress(),
            bidId,
            lender
          )).to.equal(true
        );
        //3
        dueDate = await fundingpoolInstance.calculateNextDueDate(poolId, await erc20.getAddress(), bidId, lender);
        expect(`${new BN(dueDate)}`).to.equal(`${acceptedTimeStamp.add(paymentCycle.mul(new BN(3)))}`);
  
        r = await fundingpoolInstance.viewInstallmentAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        await erc20.approve(await fundingpoolInstance.getAddress(), r);
        await fundingpoolInstance.repayMonthlyInstallment(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
  
        loan = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId
        );
        // expect(loan.lastRepaidTimestamp,
        //   BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(3))
        //   ));
        expect(loan.installment.installmentsPaid).to.equal(3);
        expect(
          await fundingpoolInstance.isPaymentLate(
            poolId,
            await erc20.getAddress(),
            bidId,
            lender
          )).to.equal(false
        );
        //4
        dueDate = await fundingpoolInstance.calculateNextDueDate(poolId, await erc20.getAddress(), bidId, lender);
        expect(`${new BN(dueDate)}`).to.equal(`${acceptedTimeStamp.add(paymentCycle.mul(new BN(4)))}`);
  
        await time.increase(paymentCycleDuration);
        r = await fundingpoolInstance.viewInstallmentAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        await erc20.approve(await fundingpoolInstance.getAddress(), r);
        await fundingpoolInstance.repayMonthlyInstallment(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
  
        loan = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId
        );
        // expect(loan.loanDetails.lastRepaidTimestamp,
        //   BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(4))
        //   ));
        expect(loan.installment.installmentsPaid).to.equal(4);
        expect(
          await fundingpoolInstance.isPaymentLate(
            poolId,
            await erc20.getAddress(),
            bidId,
            lender
          )).to.equal(
          false
        );
        //5
        dueDate = await fundingpoolInstance.calculateNextDueDate(poolId, await erc20.getAddress(), bidId, lender);
        expect(`${new BN(dueDate)}`).to.equal(`${acceptedTimeStamp.add(paymentCycle.mul(new BN(5)))}`);
  
        await time.increase(paymentCycleDuration);
        r = await fundingpoolInstance.viewInstallmentAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        await erc20.approve(await fundingpoolInstance.getAddress(), r);
        await fundingpoolInstance.repayMonthlyInstallment(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
  
        loan = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId
        );
        // expect(loan.loanDetails.lastRepaidTimestamp,
        //   BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(5))
        //   ));
        expect(loan.installment.installmentsPaid).to.equal(5);
        expect(
          await fundingpoolInstance.isPaymentLate(
            poolId,
            await erc20.getAddress(),
            bidId,
            lender
          )).to.equal(false
        );
        //6
        dueDate = await fundingpoolInstance.calculateNextDueDate(poolId, await erc20.getAddress(), bidId, lender);
        expect(`${new BN(dueDate)}`).to.equal(`${acceptedTimeStamp.add(paymentCycle.mul(new BN(6)))}`);
  
        await time.increase(paymentCycleDuration);
        //await erc20.mint(lender, '100000000');
        r = await fundingpoolInstance.viewInstallmentAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        // let full = await fundingpoolInstance.viewFullRepayAmount(
        //   poolId,
        //   await erc20.getAddress(),
        //   bidId,
        //   lender
        // );
        await erc20.approve(await fundingpoolInstance.getAddress(), r);
        // console.log("full", full.toString());
        await fundingpoolInstance.repayMonthlyInstallment(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
  
        loan = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId
        );
        // expect(loan.loanDetails.lastRepaidTimestamp,
        //   BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(6))
        //   ));
        expect(loan.installment.installmentsPaid).to.equal(5);
        expect(loan.state).to.equal(2);
      });
  
      it("should check that full repayment amount is 0", async () => {
        let loan = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId
        );
        advanceBlockAtTime(new BN(loan.lastRepaidTimestamp).add(new BN(paymentCycleDuration + 20)));
        let bal = await fundingpoolInstance.viewFullRepayAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        // console.log(bal.toNumber());
        expect(bal).to.equal(0);
      });
  
      it("should supply funds to pool again", async () => {
        const provider = ethers.provider;
        const currentBlock = await provider.getBlockNumber();
        const blockTimestamp = (await provider.getBlock(currentBlock)).timestamp;
        expiration = blockTimestamp + 3600;
        await erc20.connect(lender).approve(await fundingpoolInstance.getAddress(), erc20Amount);
        const tx = await fundingpoolInstance.connect(lender).supplyToPool(
          poolId,
          await erc20.getAddress(),
          erc20Amount,
          loanDefaultDuration,
          expiration,
          1000
        );
        bidId = 2;
        expect(bidId).to.equal(2);
      });
  
      it("should accept the bid", async () => {
        const tx = await fundingpoolInstance.AcceptBid(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender,
          receiver
        );
      });
  
      it("should repay full amount", async () => {
        let loan = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId
        );
        advanceBlockAtTime(new BN(loan.lastRepaidTimestamp).add(new BN(paymentCycleDuration + 20)));
        let bal = await fundingpoolInstance.viewFullRepayAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        // console.log(bal.toNumber());
        let b = await erc20.balanceOf(lender);
        //await erc20.transfer(lender, bal - b + 10, { from: poolOwner })
        await erc20.approve(await fundingpoolInstance.getAddress(), bal);
        await erc20.connect(receiver).approve(await fundingpoolInstance.getAddress(), bal);
  
        expect(fundingpoolInstance.connect(receiver).RepayFullAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        )).to.be.revertedWith("You are not the Pool Owner")
  
        let r = await fundingpoolInstance.RepayFullAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        loan = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId
        );
        // console.log(res)
        expect(loan.state).to.equal(2);
      });
  
      it("should check that full repayment amount is 0", async () => {
        let loan = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId
        );
        advanceBlockAtTime(new BN(loan.lastRepaidTimestamp).add(new BN(paymentCycleDuration + 20)));
        let bal = await fundingpoolInstance.viewFullRepayAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        // console.log(bal.toNumber());
        expect(bal).to.equal(0);
      });
  
      it("should supply funds to pool again", async () => {
        const provider = ethers.provider;
        const currentBlock = await provider.getBlockNumber();
        const blockTimestamp = (await provider.getBlock(currentBlock)).timestamp;
        expiration = blockTimestamp + 3600;
        await erc20.connect(lender).approve(await fundingpoolInstance.getAddress(), erc20Amount);
        const tx = await fundingpoolInstance.connect(lender).supplyToPool(
          poolId,
          await erc20.getAddress(),
          erc20Amount,
          loanDefaultDuration,
          expiration,
          1000
        );
        // console.log(tx);
        bidId = 3;
        expect(bidId).to.equal(3);
      });
  
      it("should not allow withdrawal within the expiration", async () => {
        await expect(fundingpoolInstance.connect(lender).Withdraw(poolId, await erc20.getAddress(), bidId, lender)).to.be.revertedWith("You can't Withdraw")
      })
  
      it("should show the bid has expired", async () => {
        let r = await fundingpoolInstance.isBidExpired(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        let loan = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId
        );
        // console.log("expl", loan.expiration.toString());
        // console.log("exp", expiration.toString());
        expect(r).to.equal(false);
        await time.increase(3601);
        r = await fundingpoolInstance.isBidExpired(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        expect(r).to.equal(true);
      });
  
      it("should not allow expired bid to be accepted", async () => {
        await expect(
          fundingpoolInstance.AcceptBid(
            poolId,
            await erc20.getAddress(),
            bidId,
            lender,
            receiver
          )).to.be.revertedWith("bid expired")
      });
  
      it("Should withdraw the expired bid", async () => {
        let b1 = await erc20.balanceOf(lender);
        await fundingpoolInstance.connect(lender).Withdraw(poolId, await erc20.getAddress(), bidId, lender);
        let b2 = await erc20.balanceOf(lender);
        expect(b2 - b1).to.equal(10000000000);
        let loan = await fundingpoolInstance.lenderPoolFundDetails(
          lender,
          poolId,
          await erc20.getAddress(),
          bidId
        );
        expect(loan.state).to.equal(3);
      });
  
      it("should supply funds to pool again", async () => {
        const provider = ethers.provider;
        const currentBlock = await provider.getBlockNumber();
        const blockTimestamp = (await provider.getBlock(currentBlock)).timestamp;
        expiration = blockTimestamp + 3600;
        await erc20.connect(lender).approve(await fundingpoolInstance.getAddress(), erc20Amount);
        const tx = await fundingpoolInstance.connect(lender).supplyToPool(
          poolId,
          await erc20.getAddress(),
          erc20Amount,
          loanDefaultDuration,
          expiration,
          1000
        );
        bidId = 4;
        expect(bidId, 4);
      });
  
      it("should accept the bid", async () => {
        const tx = await fundingpoolInstance.AcceptBid(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender,
          receiver
        );
      });
  
      it("should show loan defaulted after default time", async () => {
        await time.increase(loanDefaultDuration + loanExpirationDuration - 10);
        let r = await fundingpoolInstance.isLoanDefaulted(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        expect(r).to.equal(false);
        await time.increase(11);
        r = await fundingpoolInstance.isLoanDefaulted(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        expect(r).to.equal(true);
      });
  
      it("should supply funds to pool again, this time 1 usdt", async () => {
        const provider = ethers.provider;
        const currentBlock = await provider.getBlockNumber();
        const blockTimestamp = (await provider.getBlock(currentBlock)).timestamp;
        expiration = blockTimestamp + 3600;
        await erc20.connect(lender).approve(await fundingpoolInstance.getAddress(), erc20Amount);
  
        await expect(fundingpoolInstance.connect(lender).supplyToPool(
          poolId,
          await erc20.getAddress(),
          100000,
          loanDefaultDuration,
          expiration,
          1000
        )).to.be.revertedWith("amount too low")
  
        const tx = await fundingpoolInstance.connect(lender).supplyToPool(
          poolId,
          await erc20.getAddress(),
          1000000,
          loanDefaultDuration,
          expiration,
          1000
        );
        // console.log(tx);
        bidId = 5;
        expect(bidId, 5);
      });
  
      it("should accept the bid", async () => {
        const tx = await fundingpoolInstance.AcceptBid(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender,
          receiver
        );
      });
  
      it("should not allow monthly installments as amount is too low", async () => {
        r = await fundingpoolInstance.viewInstallmentAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        
        await erc20.approve(await fundingpoolInstance.getAddress(), r);
  
        await expect(
          fundingpoolInstance.repayMonthlyInstallment(
            poolId,
            await erc20.getAddress(),
            bidId,
            lender
          )).to.be.revertedWith("low"
        );
      })
  
      it("should repay the full amount", async () => {
        let bal = await fundingpoolInstance.viewFullRepayAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
        expect(bal).to.equal(1000000);
  
        await time.increase(3600);
  
        bal = await fundingpoolInstance.viewFullRepayAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
  
        console.log(bal.toString())
        
        await erc20.approve(await fundingpoolInstance.getAddress(), bal);
  
        let r = await fundingpoolInstance.RepayFullAmount(
          poolId,
          await erc20.getAddress(),
          bidId,
          lender
        );
      })
  
      it("should close the pool", async () => {
        await poolRegis.closePool(poolId1)
        let closed = await poolRegis.ClosedPool(poolId1);
        expect(closed).to.equal(true);
      })
    
      it("should not request loan in a closed pool", async () => {
        await expect(fundingpoolInstance.connect(lender).supplyToPool(
          poolId,
          await erc20.getAddress(),
          1000000,
          loanDefaultDuration,
          expiration,
          1000
        )).to.be.revertedWith("pool closed")
      })
  
      it("should create another Pool", async () => {
        res = await poolRegis.createPool(
          loanExpirationDuration,
          loanExpirationDuration,
          100,
          1000,
          "sk.com",
          true,
          true
        );
        // console.log(res);
        poolId1 = 2;
        // console.log(poolId1, "poolId1");
        poolId = poolId1;
        pool1Address = await poolRegis.getPoolAddress(poolId1);
        // console.log(pool1Address, "poolAdress");
        fundingpooladdress = pool1Address;
        res = await poolRegis.lenderVerification(poolId1, poolOwner);
        expect(
          res.isVerified_).to.equal(
          true
        );
        res = await poolRegis.borrowerVerification(poolId1, poolOwner);
        expect(
          res.isVerified_).to.equal(
          true
        );
      });
  
      it("should supply to pool", async () => {
        const provider = ethers.provider;
        const currentBlock = await provider.getBlockNumber();
        const blockTimestamp = (await provider.getBlock(currentBlock)).timestamp;
        expiration = blockTimestamp + 3600;
        await erc20.approve(await fundingpoolInstance.getAddress(), erc20Amount);
        const tx = await fundingpoolInstance.supplyToPool(
          poolId,
          await erc20.getAddress(),
          erc20Amount,
          loanDefaultDuration,
          expiration,
          1000
        );
      })
  
      it("should close pool", async () => {
        await poolRegis.closePool(poolId1)
        let closed = await poolRegis.ClosedPool(poolId1);
        expect(closed).to.equal(true);
      })
  
      it("should not allow accepting and rejecting bid after pool is closed", async () => {
        await expect(fundingpoolInstance.AcceptBid(
          poolId,
          await erc20.getAddress(),
          0,
          lender,
          receiver
        )).to.be.revertedWith("pool closed")
  
        await expect(fundingpoolInstance.RejectBid(
          poolId,
          await erc20.getAddress(),
          0,
          lender
        )).to.be.revertedWith("pool closed")
      })
    })
  })