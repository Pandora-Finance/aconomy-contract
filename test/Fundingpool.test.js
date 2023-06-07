const ethers = require("ethers");
const FundingPool = artifacts.require("FundingPool");
const PoolRegistry = artifacts.require("poolRegistry");
const IERC20 = artifacts.require("IERC20");
var BigNumber = require('big-number');
var moment = require('moment');
const truffleAssert = require('truffle-assertions');
const { time } = require("@openzeppelin/test-helpers");
const AttestRegistry = artifacts.require("AttestationRegistry")
const AttestServices = artifacts.require("AttestationServices");
const AconomyFee = artifacts.require("AconomyFee")
const PoolAddress = artifacts.require('poolAddress')
const lendingToken = artifacts.require('mintToken')
const poolAddress = artifacts.require("poolAddress")


contract("FundingPool", (accounts) => {
  let fundingPool;
  let poolRegistry;
  let erc20Token;
  const poolOwner = accounts[0];
  const lender = accounts[1];
  const nonLender = accounts[2];
  const receiver = accounts[3];
  const paymentDefaultDuration = 7;
  const feePercent = 1;
  let poolId;
  const erc20Amount = 10000;
  const maxLoanDuration = 90;
  const interestRate = 10;
  let expiration;


  const paymentCycleDuration = moment.duration(30, 'days').asSeconds()
  const loanDefaultDuration = moment.duration(180, 'days').asSeconds()
  const loanExpirationDuration = moment.duration(1, 'days').asSeconds()
  const expirationTime = BigNumber(moment.now()).add(moment.duration(30, 'days').seconds())

  let aconomyFee, poolRegis, attestRegistry, attestServices, res, poolId1, pool1Address, poolId2, loanId1, fundingpoolInstance, erc20;

  describe("supplyToPool()", () => {

    let fundingpooladdress = 0;
    let bidId, bidId1;

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
          },
        );
      });
    };


    it("should create Pool", async () => {
      //console.log("attestTegistry: ", attestServices.address)
      poolRegis = await PoolRegistry.deployed()
      aconomyFee = await AconomyFee.deployed();
      await aconomyFee.setProtocolFee(100);
      const feee = await aconomyFee.protocolFee();
      console.log("protocolFee", feee.toString())
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
      poolId1 = res.logs[5].args.poolId.toNumber()
      console.log(poolId1, "poolId1")
      poolId = poolId1;
      pool1Address = await poolRegis.getPoolAddress(poolId1);
      console.log(pool1Address, "poolAdress")
      fundingpooladdress = pool1Address;
      res = await poolRegis.lenderVerification(poolId1, accounts[0])
      assert.equal(res.isVerified_, true, "Lender Not added to pool, lenderVarification failed")
      res = await poolRegis.borrowerVerification(poolId1, accounts[0])
      assert.equal(res.isVerified_, true, "Borrower Not added to pool, borrowerVarification failed")
    })

    it("should add Lender to the pool", async () => {
      res = await poolRegis.lenderVerification(poolId1, accounts[1])
      assert.equal(res.isVerified_, false, "AddLender function not called but verified")
      await poolRegis.addLender(poolId1, accounts[1], { from: accounts[0] })
      res = await poolRegis.lenderVerification(poolId1, accounts[1])
      assert.equal(res.isVerified_, true, "Lender Not added to pool, lenderVarification failed")
    })

    it("should add Borrower to the pool", async () => {
      await poolRegis.addBorrower(poolId1, accounts[2], { from: accounts[0] })
      res = await poolRegis.borrowerVerification(poolId1, accounts[2])
      assert.equal(res.isVerified_, true, "Borrower Not added to pool, borrowerVarification failed")
    })

    it("should allow lender to supply funds to the pool", async () => {
      const provider = new ethers.JsonRpcProvider("http://127.0.0.1:9545/");
      const currentBlock = await provider.getBlockNumber();
      const blockTimestamp = (await provider.getBlock(currentBlock)).timestamp;
      expiration = blockTimestamp + 3600
      erc20 = await lendingToken.deployed()
      fundingpoolInstance = await FundingPool.at(fundingpooladdress);

      await erc20.transfer(lender, erc20Amount, { from: accounts[0] })

      await erc20.approve(fundingpoolInstance.address, erc20Amount, {
        from: lender,
      });
      const tx = await fundingpoolInstance.supplyToPool(
        poolId,
        erc20.address,
        erc20Amount,
        loanDefaultDuration,
        expiration,
        1000,
        { from: lender }
      );
      bidId = tx.logs[0].args.BidId.toNumber();
      assert.equal(bidId, 0)
      //console.log(bidId, "bidid111");

      await erc20.transfer(lender, 10000, { from: accounts[0] })
      await erc20.approve(fundingpoolInstance.address, 10000, {
        from: lender,
      });

      const tx1 = await fundingpoolInstance.supplyToPool(
        poolId,
        erc20.address,
        10000,
        loanDefaultDuration,
        expiration,
        1000,
        { from: lender }
      );
      bidId1 = tx1.logs[0].args.BidId.toNumber();
      assert.equal(bidId1, 1)
      const balance = await erc20.balanceOf(lender);
      assert.equal(balance.toString(), 0, "Error")

      // console.log(bidId1, "bidid");
      // console.log(tx.logs[0].args);
      const fundDetail = await fundingpoolInstance.lenderPoolFundDetails(
        lender,
        poolId,
        erc20.address,
        bidId
      );
      console.log(fundDetail)
      assert.equal(fundDetail.amount, erc20Amount);
      assert.equal(fundDetail.maxDuration, loanDefaultDuration);
      assert.equal(fundDetail.interestRate, 1000);
      console.log(expiration.toString())
      assert.equal(fundDetail.expiration, expiration.toString());
      assert.equal(fundDetail.state, 0); // BidState.PENDING
    });

    it("should not allow non-lender to supply funds to the pool", async () => {
      await erc20.approve(fundingpoolInstance.address, erc20Amount, {
        from: lender,
      });
      await truffleAssert.reverts(
        fundingpoolInstance.supplyToPool(
          poolId,
          erc20.address,
          erc20Amount,
          maxLoanDuration,
          loanExpirationDuration,
          1000,
          { from: nonLender }
        ),
        "Not verified lender"
      );
    });

    it("should not allow non-lender to cancel a bid", async () => {
      await truffleAssert.reverts(
        fundingpoolInstance.Withdraw(poolId, erc20.address, bidId, lender, { from: accounts[2] }),
        "You are not a Lender"
      );
    });

    it('should accept the bid and emit AcceptedBid event', async () => {
      await aconomyFee.transferOwnership(accounts[9]);
      let feeAddress = await aconomyFee.getAconomyOwnerAddress();
      await aconomyFee.setProtocolFee(200,{ from: accounts[9] });
      assert.equal(feeAddress, accounts[9],"Wrong Protocol Owner");
      const feee = await aconomyFee.protocolFee();
      console.log("protocolFee", feee.toString())
      let b1 = await erc20.balanceOf(feeAddress)
      console.log("owner1", b1.toString())
      const tx = await fundingpoolInstance.AcceptBid(
        poolId,
        erc20.address,
        bidId,
        lender,
        receiver
      );
      let b2 = await erc20.balanceOf(feeAddress)
      console.log("owner2", b2.toString())
      console.log(poolId)
      assert.equal(b2 - b1, 100)
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
        erc20.address,
        bidId
      );
      expect(fundDetail.state.toNumber()).to.equal(1); // BidState.ACCEPTED
      // expect(fundDetail.paymentCycleAmount).to.equal(
      //   expectedPaymentCycleAmount
      // );
      expect(fundDetail.acceptBidTimestamp).to.not.equal(moment.now());
      // assert.equal(bidid)
    }); it('should revert if bid is not pending', async function () {
      // await fundingpoolInstance.AcceptBid(
      //   poolId,
      //   erc20.address,
      //   bidId,
      //   lender,
      //   receiver
      // );
      await truffleAssert.reverts(
        fundingpoolInstance.AcceptBid(
          poolId,
          erc20.address,
          bidId,
          lender,
          receiver
        ),
        'Bid must be pending'
      )
    });

    it('should reject the bid and emit RejectBid event', async () => {
      const balance = await erc20.balanceOf(lender);
      console.log("bbb", balance.toString());
      const tx = await fundingpoolInstance.RejectBid(
        poolId,
        erc20.address,
        bidId1,
        lender
      );
      // console.log(poolId)
      const balance1 = await erc20.balanceOf(lender);
      console.log("bbb", balance1.toString());
      assert.equal(balance1.toString(), 10000, "Bid not rejected Yet")

      await truffleAssert.reverts(
        fundingpoolInstance.RejectBid(
          poolId,
          erc20.address,
          bidId1,
          lender,
          { from: lender }
        ),
        'You are not the Pool Owner'
      )
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
      await truffleAssert.reverts(
        fundingpoolInstance.Withdraw(poolId, erc20.address, bidId, lender, { from: lender }),
        "Bid must be pending"
      );
    });

    it("should view and pay 1st intallment amount", async () => {
      loanId1 = bidId
      let loan = await fundingpoolInstance.lenderPoolFundDetails(
        lender,
        poolId,
        erc20.address,
        bidId
      );
      console.log(loan);
      let r = await fundingpoolInstance.viewInstallmentAmount(poolId, erc20.address, bidId, lender);
      console.log('installment before 1 cycle', r.toString());
      // advanceBlockAtTime(loan.loanDetails.lastRepaidTimestamp + paymentCycleDuration + 20)
      await time.increase(paymentCycleDuration)
      r = await fundingpoolInstance.viewInstallmentAmount(poolId, erc20.address, bidId, lender);
      console.log('installment after 1 cycle', r.toString());
      //1
      await erc20.approve(fundingpoolInstance.address, r)
      let result = await fundingpoolInstance.repayMonthlyInstallment(poolId, erc20.address, bidId, lender);
  
      loan = await fundingpoolInstance.lenderPoolFundDetails(
        lender,
        poolId,
        erc20.address,
        bidId
      );
      console.log(result.logs[0].args.PaidAmount)
      assert.equal(result.logs[0].args.PaidAmount.toString(), loan.paymentCycleAmount);
      await time.increase(100)
      r = await fundingpoolInstance.viewInstallmentAmount(poolId, erc20.address, bidId, lender);
      console.log('installment after paying 1st cycle', r.toString());
    })

    it("should continue paying installments after skipping a cycle", async () => {
      loanId1 = bidId
      let loan = await fundingpoolInstance.lenderPoolFundDetails(
        lender,
        poolId,
        erc20.address,
        bidId
      );
      assert.equal(await fundingpoolInstance.isPaymentLate(poolId, erc20.address, bidId, lender), false);
      let now = await erc20.getTime();
      console.log(now.toString());
      await time.increase(paymentCycleDuration + paymentCycleDuration + 604800);
      now = await erc20.getTime();
      console.log(now.toString());
      assert.equal(await fundingpoolInstance.isPaymentLate(poolId, erc20.address, bidId, lender), true);
      //2
      let r = await fundingpoolInstance.viewInstallmentAmount(poolId, erc20.address, bidId, lender);
      assert.equal(loan.paymentCycleAmount.toString(), r.toString())
      await erc20.approve(fundingpoolInstance.address, r)
      await fundingpoolInstance.repayMonthlyInstallment(poolId, erc20.address, bidId, lender);
  
      loan = await fundingpoolInstance.lenderPoolFundDetails(
        lender,
        poolId,
        erc20.address,
        bidId
      );
      // assert.equal(loan.loanDetails.lastRepaidTimestamp, 
      //   BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(2))
      //   ));
      assert.equal(loan.installment.installmentsPaid, 2);
      assert.equal(await fundingpoolInstance.isPaymentLate(poolId, erc20.address, bidId, lender), true);
      //3
      r = await fundingpoolInstance.viewInstallmentAmount(poolId, erc20.address, bidId, lender);
      await erc20.approve(fundingpoolInstance.address, r)
      await fundingpoolInstance.repayMonthlyInstallment(poolId, erc20.address, bidId, lender);
  
      loan = await fundingpoolInstance.lenderPoolFundDetails(
        lender,
        poolId,
        erc20.address,
        bidId
      );
      // assert.equal(loan.lastRepaidTimestamp, 
      //   BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(3))
      //   ));
      assert.equal(loan.installment.installmentsPaid, 3);
      assert.equal(await fundingpoolInstance.isPaymentLate(poolId, erc20.address, bidId, lender), false);
      //4
      await time.increase(paymentCycleDuration);
      r = await fundingpoolInstance.viewInstallmentAmount(poolId, erc20.address, bidId, lender);
      await erc20.approve(fundingpoolInstance.address, r)
      await fundingpoolInstance.repayMonthlyInstallment(poolId, erc20.address, bidId, lender);
  
      loan = await fundingpoolInstance.lenderPoolFundDetails(
        lender,
        poolId,
        erc20.address,
        bidId
      );
      // assert.equal(loan.loanDetails.lastRepaidTimestamp, 
      //   BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(4))
      //   ));
      assert.equal(loan.installment.installmentsPaid, 4);
      assert.equal(await fundingpoolInstance.isPaymentLate(poolId, erc20.address, bidId, lender), false);
      //5
      await time.increase(paymentCycleDuration);
      r = await fundingpoolInstance.viewInstallmentAmount(poolId, erc20.address, bidId, lender);
      await erc20.approve(fundingpoolInstance.address, r)
      await fundingpoolInstance.repayMonthlyInstallment(poolId, erc20.address, bidId, lender);
  
      loan = await fundingpoolInstance.lenderPoolFundDetails(
        lender,
        poolId,
        erc20.address,
        bidId
      );
      // assert.equal(loan.loanDetails.lastRepaidTimestamp, 
      //   BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(5))
      //   ));
      assert.equal(loan.installment.installmentsPaid, 5);
      assert.equal(await fundingpoolInstance.isPaymentLate(poolId, erc20.address, bidId, lender), false);
      //6
      await time.increase(paymentCycleDuration);
      //await erc20.mint(accounts[1], '100000000');
      r = await fundingpoolInstance.viewInstallmentAmount(poolId, erc20.address, bidId, lender);
      let full = await fundingpoolInstance.viewFullRepayAmount(poolId, erc20.address, bidId, lender);
      await erc20.approve(fundingpoolInstance.address, full + 100)
      console.log("full", full.toString())
      await fundingpoolInstance.repayMonthlyInstallment(poolId, erc20.address, bidId, lender);
  
      loan = await fundingpoolInstance.lenderPoolFundDetails(
        lender,
        poolId,
        erc20.address,
        bidId
      );
      // assert.equal(loan.loanDetails.lastRepaidTimestamp, 
      //   BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(6))
      //   ));
      assert.equal(loan.installment.installmentsPaid, 5);
      assert.equal(loan.state, 2);
    })
  
    it("should check that full repayment amount is 0", async () => {
      let loan = await fundingpoolInstance.lenderPoolFundDetails(
        lender,
        poolId,
        erc20.address,
        bidId
      );
      advanceBlockAtTime(loan.lastRepaidTimestamp + paymentCycleDuration + 20)
      let bal = await fundingpoolInstance.viewFullRepayAmount(poolId, erc20.address, bidId, lender)
      console.log(bal.toNumber())
      assert.equal(bal, 0)
    })

    it("should supply funds to pool again", async () => {
      const provider = new ethers.JsonRpcProvider("http://127.0.0.1:9545/");
      const currentBlock = await provider.getBlockNumber();
      const blockTimestamp = (await provider.getBlock(currentBlock)).timestamp;
      expiration = blockTimestamp + 3600
      await erc20.approve(fundingpoolInstance.address, erc20Amount, {
        from: lender,
      });
      const tx = await fundingpoolInstance.supplyToPool(
        poolId,
        erc20.address,
        erc20Amount,
        loanDefaultDuration,
        expiration,
        1000,
        { from: lender }
      );
      bidId = tx.logs[0].args.BidId.toNumber();
      assert.equal(bidId, 2)
    })

    it('should accept the bid', async () => {
      const tx = await fundingpoolInstance.AcceptBid(
        poolId,
        erc20.address,
        bidId,
        lender,
        receiver
      );
    });

    it("should repay full amount", async () => {
      let loan = await fundingpoolInstance.lenderPoolFundDetails(
        lender,
        poolId,
        erc20.address,
        bidId
      );
      advanceBlockAtTime(loan.lastRepaidTimestamp + paymentCycleDuration + 20)
      let bal = await fundingpoolInstance.viewFullRepayAmount(poolId, erc20.address, bidId, lender)
      console.log(bal.toNumber());
      let b = await erc20.balanceOf(accounts[1]);
      //await erc20.transfer(accounts[1], bal - b + 10, { from: accounts[0] })
      await erc20.approve(fundingpoolInstance.address, bal + 10)
      let r = await fundingpoolInstance.RepayFullAmount(poolId, erc20.address, bidId, lender)
      loan = await fundingpoolInstance.lenderPoolFundDetails(
        lender,
        poolId,
        erc20.address,
        bidId
      );
      // console.log(res)
      assert.equal(loan.state, 2, "Not able to repay loan")
    })
  
    it("should check that full repayment amount is 0", async () => {
      let loan = await fundingpoolInstance.lenderPoolFundDetails(
        lender,
        poolId,
        erc20.address,
        bidId
      );
      advanceBlockAtTime(loan.lastRepaidTimestamp + paymentCycleDuration + 20)
      let bal = await fundingpoolInstance.viewFullRepayAmount(poolId, erc20.address, bidId, lender)
      console.log(bal.toNumber())
      assert.equal(bal, 0)
    })

    it("should supply funds to pool again", async () => {
      const provider = new ethers.JsonRpcProvider("http://127.0.0.1:9545/");
      const currentBlock = await provider.getBlockNumber();
      const blockTimestamp = (await provider.getBlock(currentBlock)).timestamp;
      expiration = blockTimestamp + 3600
      await erc20.approve(fundingpoolInstance.address, erc20Amount, {
        from: lender,
      });
      const tx = await fundingpoolInstance.supplyToPool(
        poolId,
        erc20.address,
        erc20Amount,
        loanDefaultDuration,
        expiration,
        1000,
        { from: lender }
      );
      console.log(tx)
      bidId = tx.logs[0].args.BidId.toNumber();
      assert.equal(bidId, 3)

    })

    it('should show the bid has expired', async () => {
      let r = await fundingpoolInstance.isBidExpired(poolId, erc20.address, bidId, lender);
      let loan = await fundingpoolInstance.lenderPoolFundDetails(
        lender,
        poolId,
        erc20.address,
        bidId
      );
      console.log("expl", loan.expiration.toString())
      console.log("exp", expiration.toString())
      assert.equal(r, false);
      advanceBlockAtTime(expiration + 10);
      r = await fundingpoolInstance.isBidExpired(poolId, erc20.address, bidId, lender);
      assert.equal(r, true);
    });

    it("should not allow expired bid to be accepted", async () => {
      await truffleAssert.reverts(fundingpoolInstance.AcceptBid(
        poolId,
        erc20.address,
        bidId,
        lender,
        receiver
      ), "bid expired")
    })

    it("Should withdraw the expired bid", async () => {
      let b1 = await erc20.balanceOf(lender);
      await fundingpoolInstance.Withdraw(poolId, erc20.address, bidId, lender, { from: lender });
      let b2 = await erc20.balanceOf(lender);
      assert.equal(b2 - b1, 10000);
      let loan = await fundingpoolInstance.lenderPoolFundDetails(
        lender,
        poolId,
        erc20.address,
        bidId
      );
      assert.equal(loan.state, 3);
    })

    it("should supply funds to pool again", async () => {
      const provider = new ethers.JsonRpcProvider("http://127.0.0.1:9545/");
      const currentBlock = await provider.getBlockNumber();
      const blockTimestamp = (await provider.getBlock(currentBlock)).timestamp;
      expiration = blockTimestamp + 3600
      await erc20.approve(fundingpoolInstance.address, erc20Amount, {
        from: lender,
      });
      const tx = await fundingpoolInstance.supplyToPool(
        poolId,
        erc20.address,
        erc20Amount,
        loanDefaultDuration,
        expiration,
        1000,
        { from: lender }
      );
      bidId = tx.logs[0].args.BidId.toNumber();
      assert.equal(bidId, 4)
    })

    it('should accept the bid', async () => {
      const tx = await fundingpoolInstance.AcceptBid(
        poolId,
        erc20.address,
        bidId,
        lender,
        receiver
      );
    });

    it("should show loan defaulted after default time", async () => {
      let r = await fundingpoolInstance.isLoanDefaulted(poolId, erc20.address, bidId, lender);
      assert.equal(r, false);
      await time.increase(loanDefaultDuration + loanExpirationDuration + 1)
      r = await fundingpoolInstance.isLoanDefaulted(poolId, erc20.address, bidId, lender);
      assert.equal(r, true);
    })

  });
})