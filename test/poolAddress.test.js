var BigNumber = require('big-number');
var moment = require('moment');
const { BN, constants, expectEvent, shouldFail, time, expectRevert } = require('@openzeppelin/test-helpers');
const PoolRegistry = artifacts.require("poolRegistry");
const AttestRegistry = artifacts.require("AttestationRegistry")
const AttestServices = artifacts.require("AttestationServices");
const AconomyFee = artifacts.require("AconomyFee")
const PoolAddress = artifacts.require('poolAddress')
const lendingToken = artifacts.require('mintToken')
const poolAddress = artifacts.require("poolAddress")
const truffleAssert = require('truffle-assertions');
contract("PoolAddress", async (accounts) => {
  const paymentCycleDuration = moment.duration(30, 'days').asSeconds()
  const loanDefaultDuration = moment.duration(180, 'days').asSeconds()
  const loanExpirationDuration = moment.duration(2, 'days').asSeconds()
  const expirationTime = BigNumber(moment.now()).add(
    moment.duration(30, 'days').seconds())
  let aconomyFee, poolRegis, attestRegistry, attestServices, res, poolId1, pool1Address, poolId2, loanId1, poolAddressInstance, erc20;

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
    // console.log("attestTegistry: ", attestServices.address)
    poolRegis = await PoolRegistry.deployed()
    aconomyFee = await AconomyFee.deployed();
    res = await poolRegis.createPool(
      paymentCycleDuration,
      loanExpirationDuration,
      100,
      100,
      "sk.com",
      true,
      true
    );
    poolId1 = res.logs[5].args.poolId.toNumber()
    console.log(poolId1, "poolId1")
    pool1Address = res.logs[4].args.poolAddress;
    console.log(pool1Address, "poolAdress")
    res = await poolRegis.lenderVerification(poolId1, accounts[0])
    assert.equal(res.isVerified_, true, "Lender Not added to pool, lenderVarification failed")
    res = await poolRegis.borrowerVerification(poolId1, accounts[0])
    assert.equal(res.isVerified_, true, "Borrower Not added to pool, borrowerVarification failed")
  })

  it("should add Lender to the pool", async () => {
    res = await poolRegis.lenderVerification(poolId1, accounts[9])
    assert.equal(res.isVerified_, false, "AddLender function not called but verified")
    await poolRegis.addLender(poolId1, accounts[9], { from: accounts[0] })
    res = await poolRegis.lenderVerification(poolId1, accounts[9])
    assert.equal(res.isVerified_, true, "Lender Not added to pool, lenderVarification failed")
    await poolRegis.removeLender(poolId1, accounts[9], { from: accounts[0] })
    res = await poolRegis.lenderVerification(poolId1, accounts[9])
    assert.equal(res.isVerified_, false, "Lender Not added to pool, lenderVarification failed")
    await poolRegis.addLender(poolId1, accounts[9], { from: accounts[0] })
    res = await poolRegis.lenderVerification(poolId1, accounts[9])
    assert.equal(res.isVerified_, true, "Lender Not added to pool, lenderVarification failed")
  })

  it("should add Borrower to the pool", async () => {
    await poolRegis.addBorrower(poolId1, accounts[1], { from: accounts[0] })
    res = await poolRegis.borrowerVerification(poolId1, accounts[1])
    assert.equal(res.isVerified_, true, "Borrower Not added to pool, borrowerVerification failed")
    await poolRegis.removeBorrower(poolId1, accounts[1], { from: accounts[0] })
    res = await poolRegis.borrowerVerification(poolId1, accounts[1])
    assert.equal(res.isVerified_, false, "Borrower Not added to pool, borrowerVerification failed")
    await poolRegis.addBorrower(poolId1, accounts[1], { from: accounts[0] })
    res = await poolRegis.borrowerVerification(poolId1, accounts[1])
    assert.equal(res.isVerified_, true, "Borrower Not added to pool, borrowerVerification failed")
  })

  it("testing loan request function", async () => {
    await aconomyFee.setProtocolFee(100);
    erc20 = await lendingToken.deployed()
    await erc20.mint(accounts[0], '10000000000')
    poolAddressInstance = await PoolAddress.deployed();
    res = await poolAddressInstance.loanRequest(
      erc20.address,
      poolId1,
      1000000000,
      loanDefaultDuration,
      loanExpirationDuration,
      100,
      accounts[1],
      { from: accounts[1] }
    )
    loanId1 = res.logs[0].args.loanId.toNumber()
    let paymentCycleAmount = res.logs[0].args.paymentCycleAmount.toNumber()
    console.log(paymentCycleAmount, "pca")
    assert.equal(loanId1, 0, "Unable to create loan: Wrong LoanId")
  })

  it("should Accept loan ", async () => {
    await aconomyFee.transferOwnership(accounts[9]);
    let feeAddress = await aconomyFee.getAconomyOwnerAddress();
    await aconomyFee.setProtocolFee(200,{ from: accounts[9] });
    assert.equal(feeAddress, accounts[9]);
    let b1 = await erc20.balanceOf(feeAddress)
    console.log("fee 1", b1.toNumber())
    await erc20.approve(poolAddressInstance.address, 1000000000)
    let _balance1 = await erc20.balanceOf(accounts[0]);
    console.log(_balance1.toNumber())
    res = await poolAddressInstance.AcceptLoan(loanId1, { from: accounts[0] })
    let b2 = await erc20.balanceOf(feeAddress)
    console.log("fee 2", b2.toNumber())
    assert.equal(b2 - b1, 10000000)
    _balance1 = await erc20.balanceOf(accounts[1]);
    //console.log(_balance1.toNumber())
    //Amount that the borrower will get is 999 after cutting fees and market charges
    assert.equal(_balance1.toNumber(), 980000000, "Not able to accept loan");
  })

  it("should calculate the next due date", async () => {
    loanId1 = res.logs[0].args.loanId.toNumber()
    console.log(loanId1)
    let now = await erc20.getTime();
    // console.log("now before increase", now.toString())
    // await time.increase(paymentCycleDuration)
    let r = await poolAddressInstance.calculateNextDueDate(loanId1)
    console.log("due", r.toString())
    now = await erc20.getTime();
    console.log("now", now.toString())
    console.log("difference", r - now);
    assert.equal(r - now, 2592000)
  })

  it("should not work after the loan expires", async () => {
    loanId1 = res.logs[0].args.loanId.toNumber()
    let r = await poolAddressInstance.isLoanExpired(loanId1)
    assert.equal(r, false, "Unable to check loan: Wrong LoanId")
  })

  it("should check the payment done in time", async () => {
    loanId1 = res.logs[0].args.loanId.toNumber()
    let r = await poolAddressInstance.isPaymentLate(loanId1)
    assert.equal(r, false, "Unable to check loan: Wrong LoanId")
  })

  it("should view and pay 1st intallment amount", async () => {
    loanId1 = res.logs[0].args.loanId.toNumber()
    let loan = await poolAddressInstance.loans(loanId1);
    console.log(loan);
    let r = await poolAddressInstance.viewInstallmentAmount(loanId1);
    console.log('installment before 1 cycle', r.toString());
    // advanceBlockAtTime(loan.loanDetails.lastRepaidTimestamp + paymentCycleDuration + 20)
    await time.increase(paymentCycleDuration)
    r = await poolAddressInstance.viewInstallmentAmount(loanId1);
    console.log('installment after 1 cycle', r.toString());
    //1
    await erc20.approve(poolAddressInstance.address, r, { from: accounts[1] })
    let result = await poolAddressInstance.repayMonthlyInstallment(loanId1, { from: accounts[1] });

    loan = await poolAddressInstance.loans(loanId1);
    assert.equal(loan.loanDetails.lastRepaidTimestamp, 
      BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(1))
      ));
    console.log(result.logs[0].args.Amount.toString())
    assert.equal(result.logs[0].args.Amount.toString(), loan.terms.paymentCycleAmount);
    await time.increase(100)
    r = await poolAddressInstance.viewInstallmentAmount(loanId1);
    console.log('installment after paying 1st cycle', r.toString());
  })

  it("should continue paying installments after skipping a cycle", async () => {
    loanId1 = res.logs[0].args.loanId.toNumber()
    let loan = await poolAddressInstance.loans(loanId1);
    assert.equal(await poolAddressInstance.isPaymentLate(loanId1), false);
    let now = await erc20.getTime();
    console.log(now.toString());
    await time.increase(paymentCycleDuration + paymentCycleDuration + 604800);
    now = await erc20.getTime();
    console.log(now.toString());
    assert.equal(await poolAddressInstance.isPaymentLate(loanId1), true);
    //2
    let r = await poolAddressInstance.viewInstallmentAmount(loanId1);
    await erc20.approve(poolAddressInstance.address, r, { from: accounts[1] })
    await poolAddressInstance.repayMonthlyInstallment(loanId1, { from: accounts[1] });

    loan = await poolAddressInstance.loans(loanId1);
    assert.equal(loan.loanDetails.lastRepaidTimestamp, 
      BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(2))
      ));
    assert.equal(loan.terms.installmentsPaid, 2);
    assert.equal(await poolAddressInstance.isPaymentLate(loanId1), true);
    //3
    r = await poolAddressInstance.viewInstallmentAmount(loanId1);
    await erc20.approve(poolAddressInstance.address, r, { from: accounts[1] })
    await poolAddressInstance.repayMonthlyInstallment(loanId1, { from: accounts[1] });

    loan = await poolAddressInstance.loans(loanId1);
    assert.equal(loan.loanDetails.lastRepaidTimestamp, 
      BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(3))
      ));
    assert.equal(loan.terms.installmentsPaid, 3);
    assert.equal(await poolAddressInstance.isPaymentLate(loanId1), false);
    //4
    await time.increase(paymentCycleDuration);
    r = await poolAddressInstance.viewInstallmentAmount(loanId1);
    await erc20.approve(poolAddressInstance.address, r, { from: accounts[1] })
    await poolAddressInstance.repayMonthlyInstallment(loanId1, { from: accounts[1] });

    loan = await poolAddressInstance.loans(loanId1);
    assert.equal(loan.loanDetails.lastRepaidTimestamp, 
      BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(4))
      ));
    assert.equal(loan.terms.installmentsPaid, 4);
    assert.equal(await poolAddressInstance.isPaymentLate(loanId1), false);
    //5
    await time.increase(paymentCycleDuration);
    r = await poolAddressInstance.viewInstallmentAmount(loanId1);
    await erc20.approve(poolAddressInstance.address, r, { from: accounts[1] })
    await poolAddressInstance.repayMonthlyInstallment(loanId1, { from: accounts[1] });

    loan = await poolAddressInstance.loans(loanId1);
    assert.equal(loan.loanDetails.lastRepaidTimestamp, 
      BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(5))
      ));
    assert.equal(loan.terms.installmentsPaid, 5);
    assert.equal(await poolAddressInstance.isPaymentLate(loanId1), false);
    //6
    await time.increase(paymentCycleDuration);
    await erc20.mint(accounts[1], '100000000');
    r = await poolAddressInstance.viewInstallmentAmount(loanId1);
    let full = await poolAddressInstance.viewFullRepayAmount(loanId1);
    await erc20.approve(poolAddressInstance.address, full + 100, { from: accounts[1] })
    console.log("full", full.toString())
    await poolAddressInstance.repayMonthlyInstallment(loanId1, { from: accounts[1] });

    loan = await poolAddressInstance.loans(loanId1);
    // assert.equal(loan.loanDetails.lastRepaidTimestamp, 
    //   BigNumber(loan.loanDetails.acceptedTimestamp).plus((BigNumber(loan.terms.paymentCycle).multiply(6))
    //   ));
    assert.equal(loan.terms.installmentsPaid, 5);
    assert.equal(loan.state, 3);
  })

  it("should check that full repayment amount is 0", async () => {
    let loan = await poolAddressInstance.loans(loanId1);
    advanceBlockAtTime(loan.loanDetails.lastRepaidTimestamp + paymentCycleDuration + 20)
    let bal = await poolAddressInstance.viewFullRepayAmount(loanId1)
    console.log(bal.toNumber())
    assert.equal(bal, 0)
  })

  it("should request another loan", async () => {
    erc20 = await lendingToken.deployed()
    //await erc20.mint(accounts[0], '10000000000')
    poolAddressInstance = await PoolAddress.deployed();
    res = await poolAddressInstance.loanRequest(
      erc20.address,
      poolId1,
      1000000000,
      loanDefaultDuration,
      loanExpirationDuration,
      100,
      accounts[1],
      { from: accounts[1] }
    )
    loanId1 = res.logs[0].args.loanId.toNumber()
    let paymentCycleAmount = res.logs[0].args.paymentCycleAmount.toNumber()
    console.log(paymentCycleAmount, "pca")
    assert.equal(loanId1, 1, "Unable to create loan: Wrong LoanId")
  })

  it("should Accept loan ", async () => {
    await erc20.approve(poolAddressInstance.address, 1000000000)
    let _balance1 = await erc20.balanceOf(accounts[0]);
    console.log(_balance1.toNumber())
    res = await poolAddressInstance.AcceptLoan(loanId1, { from: accounts[0] })
    _balance1 = await erc20.balanceOf(accounts[1]);
  })

  it("should repay full amount", async () => {
    let loan = await poolAddressInstance.loans(loanId1);
    advanceBlockAtTime(loan.loanDetails.lastRepaidTimestamp + paymentCycleDuration + 20)
    let bal = await poolAddressInstance.viewFullRepayAmount(loanId1)
    console.log(bal.toNumber());
    let b = await erc20.balanceOf(accounts[1]);
    //await erc20.transfer(accounts[1], bal - b + 10, { from: accounts[0] })
    await erc20.approve(poolAddressInstance.address, bal + 10, { from: accounts[1] })
    let r = await poolAddressInstance.repayFullLoan(loanId1, { from: accounts[1] })
    // console.log(res)
    assert.equal(r.receipt.status, true, "Not able to repay loan")
  })

  it("should check that full repayment amount is 0", async () => {
    let loan = await poolAddressInstance.loans(loanId1);
    advanceBlockAtTime(loan.loanDetails.lastRepaidTimestamp + paymentCycleDuration + 20)
    let bal = await poolAddressInstance.viewFullRepayAmount(loanId1)
    console.log(bal.toNumber())
    assert.equal(bal, 0)
  })

  it("should request another loan", async () => {
    erc20 = await lendingToken.deployed()
    //await erc20.mint(accounts[0], '10000000000')
    poolAddressInstance = await PoolAddress.deployed();
    res = await poolAddressInstance.loanRequest(
      erc20.address,
      poolId1,
      1000000000,
      loanDefaultDuration,
      loanExpirationDuration,
      100,
      accounts[1],
      { from: accounts[1] }
    )
    loanId1 = res.logs[0].args.loanId.toNumber()
    let paymentCycleAmount = res.logs[0].args.paymentCycleAmount.toNumber()
    console.log(paymentCycleAmount, "pca")
    assert.equal(loanId1, 2, "Unable to create loan: Wrong LoanId")
  })

  it("should expire after the expiry deadline", async () => {
    await time.increase(loanExpirationDuration + 1);
    let r = await poolAddressInstance.isLoanExpired(loanId1);
    assert.equal(r, true);
  })

  it("should not allow an expired loan to be accepted", async () => {
    await truffleAssert.reverts(poolAddressInstance.AcceptLoan(loanId1, { from: accounts[0] }), "Loan has expired")
  })

  it("should request another loan", async () => {
    erc20 = await lendingToken.deployed()
    //await erc20.mint(accounts[0], '10000000000')
    poolAddressInstance = await PoolAddress.deployed();
    res = await poolAddressInstance.loanRequest(
      erc20.address,
      poolId1,
      1000000000,
      loanDefaultDuration,
      loanExpirationDuration,
      100,
      accounts[1],
      { from: accounts[1] }
    )
    loanId1 = res.logs[0].args.loanId.toNumber()
    let paymentCycleAmount = res.logs[0].args.paymentCycleAmount.toNumber()
    console.log(paymentCycleAmount, "pca")
    assert.equal(loanId1, 3, "Unable to create loan: Wrong LoanId")
  })

  it("should Accept loan ", async () => {
    await erc20.approve(poolAddressInstance.address, 1000000000)
    let _balance1 = await erc20.balanceOf(accounts[0]);
    console.log(_balance1.toNumber())
    res = await poolAddressInstance.AcceptLoan(loanId1, { from: accounts[0] })
    _balance1 = await erc20.balanceOf(accounts[1]);
  })

  it("should show loan defaulted", async () => {
    let r = await poolAddressInstance.isLoanDefaulted(loanId1);
    assert.equal(r, false);
    await time.increase(loanDefaultDuration + paymentCycleDuration + 1);
    r = await poolAddressInstance.isLoanDefaulted(loanId1);
    assert.equal(r, true);
  })
})