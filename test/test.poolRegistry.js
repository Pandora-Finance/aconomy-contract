var BigNumber = require("big-number");
var moment = require("moment");
const {
  BN,
  constants,
  expectEvent,
  shouldFail,
  time,
  expectRevert,
} = require("@openzeppelin/test-helpers");
const PoolRegistry = artifacts.require("poolRegistry");
const AttestRegistry = artifacts.require("AttestationRegistry");
const AttestServices = artifacts.require("AttestationServices");
const AconomyFee = artifacts.require("AconomyFee");
const PoolAddress = artifacts.require("poolAddress");
const lendingToken = artifacts.require("mintToken");
const poolAddress = artifacts.require("poolAddress");

contract("poolRegistry", async (accounts) => {
  const paymentCycleDuration = moment.duration(30, "days").asSeconds();
  const expiration = moment.duration(2, "days").asSeconds();
  const loanDuration = moment.duration(150, "days").asSeconds();
  const loanDefaultDuration = moment.duration(90, "days").asSeconds();
  const loanExpirationDuration = moment.duration(180, "days").asSeconds();

  const expirationTime = BigNumber(moment.now()).add(
    moment.duration(30, "days").seconds()
  );

  let aconomyFee,
    poolRegis,
    attestRegistry,
    attestServices,
    res,
    poolId1,
    pool1Address,
    poolId2,
    loanId1,
    poolAddressInstance,
    newpool1Address,
    newpoolId,
    erc20;

  it("should set Aconomyfee", async () => {
    aconomyFee = await AconomyFee.deployed();
    await aconomyFee.setAconomyPoolFee(200);
    let protocolFee = await aconomyFee.AconomyPoolFee();
    let aconomyFeeOwner = await aconomyFee.getAconomyOwnerAddress();
    assert.equal(aconomyFeeOwner, accounts[0], "wrong Aconomy fee owner");
    assert.equal(protocolFee.toNumber(), 200, "Wrong set Protocol Fee");
  });

  it("should create attestRegistry, attestationService", async () => {
    // attestRegistry = await AttestRegistry.deployed();
    // assert.notEqual(attestRegistry.address, null, "address is zero");
    attestServices = await AttestServices.deployed();
    assert.notEqual(
      attestServices.address,
      null || undefined,
      "Attestation Services unable to deployed"
    );
  });

  it("should create Pool", async () => {
    // console.log("attestTegistry: ", attestServices.address)
    poolRegis = await PoolRegistry.deployed();
    res = await poolRegis.createPool(
      loanDefaultDuration,
      loanExpirationDuration,
      100,
      1000,
      "sk.com",
      true,
      true
    );
    poolId1 = res.logs[5].args.poolId.toNumber();
    // console.log(poolId1, "poolId1");
    pool1Address = res.logs[4].args.poolAddress;
    // console.log(pool1Address, "poolAdress");
    res = await poolRegis.lenderVerification(poolId1, accounts[0]);
    assert.equal(
      res.isVerified_,
      true,
      "Lender Not added to pool, lenderVarification failed"
    );
    res = await poolRegis.borrowerVerification(poolId1, accounts[0]);
    assert.equal(
      res.isVerified_,
      true,
      "Borrower Not added to pool, borrowerVarification failed"
    );

    // res =  await poolRegis.createPool(
    //     accounts[0],
    //     paymentCycleDuration,
    //     loanDefaultDuration,
    //     loanExpirationDuration,
    //     10,
    //     true,
    //     true,
    //     "skk.com"
    // );

    // poolId2 = res.logs[0].args.poolId.toNumber()
  });

  it("should create a new Pool", async () => {
    // console.log("attestTegistry: ", attestServices.address)
    poolRegis = await PoolRegistry.deployed();
    res = await poolRegis.createPool(
      211111111,
      2111111222,
      100,
      1000,
      "sk.com",
      false,
      false
    );

    poolId2 = res.logs[5].args.poolId.toNumber();
    // console.log(poolId2, "poolId2");
    pool1Address = res.logs[4].args.poolAddress;
    // console.log(pool1Address, "poolAdress");
    res = await poolRegis.lenderVerification(poolId2, accounts[0]);
    assert.equal(
      res.isVerified_,
      true,
      "Lender Not added to pool, lenderVarification failed"
    );
    res = await poolRegis.borrowerVerification(poolId2, accounts[0]);
    assert.equal(
      res.isVerified_,
      true,
      "Borrower Not added to pool, borrowerVarification failed"
    );
  });

  it("should create an other new Pool", async () => {
    // console.log("attestTegistry: ", attestServices.address)
    poolRegis = await PoolRegistry.deployed();
    res = await poolRegis.createPool(
      211111111,
      2111111222,
      100,
      1000,
      "sk.com",
      true,
      true
    );

    newpoolId = res.logs[5].args.poolId.toNumber();
    // console.log(newpoolId, "poolId");
    newpool1Address = res.logs[4].args.poolAddress;
    // console.log(pool1Address, "poolAdress");
    // res = await poolRegis.lenderVerification(poolId2, accounts[0]);
    // assert.equal(
    //   res.isVerified_,
    //   false,
    //   "Lender Not added to pool, lenderVarification failed"
    // );
    // res = await poolRegis.borrowerVerification(poolId2, accounts[0]);
    // assert.equal(
    //   res.isVerified_,
    //   false,
    //   "Borrower Not added to pool, borrowerVarification failed"
    // );
  });

  it("should change the uri", async () => {
    let apr = await poolRegis.getPoolApr(3);
    assert.equal(apr, 1000, "apr is not correct");
    await poolRegis.setApr(3,200)
    let newAPR = await poolRegis.getPoolApr(3);
    assert.equal(newAPR, 200, "apr is not updated");
  });

  it("should change the payment default duration", async () => {
    let DefaultDuration = await poolRegis.getPaymentDefaultDuration(3);
    assert.equal(DefaultDuration, 211111111, "DefaultDuration is not correct");
    await poolRegis.setPaymentDefaultDuration(3,211111112)
    let newDefaultDuration = await poolRegis.getPaymentDefaultDuration(3);
    assert.equal(newDefaultDuration, 211111112, "DefaultDuration is not updated");
  });

  it("should change the Pool Fee percent", async () => {
    let PoolFeePercent = await poolRegis.getPoolFeePercent(3);
    assert.equal(PoolFeePercent, 100, "PoolFeePercent is not correct");
    await poolRegis.setPoolFeePercent(3,200)
    let newPoolFeePercent = await poolRegis.getPoolFeePercent(3);
    assert.equal(newPoolFeePercent, 200, "PoolFeePercent is not updated");
  });

  it("should change the loan Expiration Time", async () => {
    let loanExpirationTime = await poolRegis.getloanExpirationTime(3);
    assert.equal(loanExpirationTime, 2111111222, "loanExpirationTime is not correct");
    await poolRegis.setloanExpirationTime(3,2111111223)
    let newloanExpirationTime = await poolRegis.getloanExpirationTime(3);
    assert.equal(newloanExpirationTime, 2111111223, "loanExpirationTime is not updated");
  });

  it("should check only owner can add lender and borrower", async() => {

    await expectRevert(
      poolRegis.addBorrower(newpoolId, accounts[1], { from: accounts[2] }),
      "Not the owner"
    );

    res = await poolRegis.lenderVerification(poolId1, accounts[9]);
    assert.equal(
      res.isVerified_,
      false,
      "AddLender function not called but verified"
    );

    await expectRevert(
      poolRegis.addLender(newpoolId, accounts[9], { from: accounts[2] }),
      "Not the owner"
    );

  })

  it("should check lender and borrower are romoved or not", async() => {
    res = await poolRegis.lenderVerification(newpoolId, accounts[9]);
    assert.equal(
      res.isVerified_,
      false,
      "AddLender function not called but verified"
    );
    await poolRegis.addLender(newpoolId, accounts[9], { from: accounts[0] });
    res = await poolRegis.lenderVerification(newpoolId, accounts[9]);
    assert.equal(
      res.isVerified_,
      true,
      "Lender Not added to pool, lenderVerification failed"
    );

    await poolRegis.removeLender(newpoolId, accounts[9], { from: accounts[0] });
    res = await poolRegis.lenderVerification(newpoolId, accounts[9]);
    assert.equal(
      res.isVerified_,
      false,
      "AddLender function not called but verified"
    );

    await poolRegis.addBorrower(newpoolId, accounts[1], { from: accounts[0] });
    res = await poolRegis.borrowerVerification(newpoolId, accounts[1]);
    assert.equal(
      res.isVerified_,
      true,
      "Borrower Not added to pool, borrowerVerification failed"
    );

    await poolRegis.removeBorrower(newpoolId, accounts[1], { from: accounts[0] });
    res = await poolRegis.borrowerVerification(newpoolId, accounts[1]);
    assert.equal(
      res.isVerified_,
      false,
      "Borrower Not added to pool, borrowerVerification failed"
    );


  })

  it("should verify the details of pool2", async () => {
    let DefaultDuration = await poolRegis.getPaymentDefaultDuration(poolId2);
    // console.log("aaa",DefaultDuration.toString())

    assert.equal(DefaultDuration, 211111111, "Default Duration is not changed");

    let ExpirationTime = await poolRegis.getloanExpirationTime(poolId2);
    // console.log("aaa111",ExpirationTime.toString())
    assert.equal(ExpirationTime, 2111111222, "Expiration Time is not changed");

    res = await poolRegis.lenderVerification(poolId2, accounts[2]);
    assert.equal(
      res.isVerified_,
      true,
      "Lender is added to pool, lenderVarification failed"
    );
    res = await poolRegis.borrowerVerification(poolId2, accounts[2]);
    assert.equal(
      res.isVerified_,
      true,
      "Borrower is added to pool, borrowerVarification failed"
    );
  });

  it("should change the setting of new pool", async () => {
    res = await poolRegis.changePoolSetting(
      poolId2,
      11111111,
      111111222,
      200,
      2000,
      "srs.com"
    );

    let apr = await poolRegis.getPoolApr(poolId2);
    assert.equal(
      apr,
      2000,
      "Lender is added to pool, lenderVarification failed"
    );

    let DefaultDuration = await poolRegis.getPaymentDefaultDuration(poolId2);
    // console.log("aaa",DefaultDuration.toString())

    assert.equal(DefaultDuration, 11111111, "Default Duration is not changed");

    let ExpirationTime = await poolRegis.getloanExpirationTime(poolId2);
    // console.log("aaa111",ExpirationTime.toString())
    assert.equal(ExpirationTime, 111111222, "Expiration Time is not changed");

    res = await poolRegis.lenderVerification(poolId2, accounts[2]);
    assert.equal(
      res.isVerified_,
      true,
      "Lender is added to pool, lenderVarification failed"
    );
    res = await poolRegis.borrowerVerification(poolId2, accounts[2]);
    assert.equal(
      res.isVerified_,
      true,
      "Borrower is added to pool, borrowerVarification failed"
    );
  });

  it("should not create if the contract is paused", async () => {
    await poolRegis.pause();
    await expectRevert.unspecified(
      poolRegis.createPool(
        loanDefaultDuration,
        loanExpirationDuration,
        100,
        1000,
        "sk.com",
        true,
        true
      )
    );
    await poolRegis.unpause();
  });

  it("should add Lender to the pool", async () => {
    res = await poolRegis.lenderVerification(poolId1, accounts[9]);
    assert.equal(
      res.isVerified_,
      false,
      "AddLender function not called but verified"
    );
    await poolRegis.addLender(poolId1, accounts[9], { from: accounts[0] });
    res = await poolRegis.lenderVerification(poolId1, accounts[9]);
    assert.equal(
      res.isVerified_,
      true,
      "Lender Not added to pool, lenderVerification failed"
    );
  });

  it("should add Borrower to the pool", async () => {
    await poolRegis.addBorrower(poolId1, accounts[1], { from: accounts[0] });
    res = await poolRegis.borrowerVerification(poolId1, accounts[1]);
    assert.equal(
      res.isVerified_,
      true,
      "Borrower Not added to pool, borrowerVerification failed"
    );
  });

  it("should allow Attested Borrower to Request Loan in a Pool", async () => {
    erc20 = await lendingToken.deployed();
    await erc20.mint(accounts[0], 10000000000);
    // poolAddressInstance = await PoolAddress.at(pool1Address)
    poolAddressInstance = await poolAddress.deployed();
    // console.log(poolAddressInstance)

    res = await poolAddressInstance.loanRequest(
      erc20.address,
      poolId1,
      10000000000,
      loanDuration,
      expiration,
      1000,
      accounts[1],
      { from: accounts[1] }
    );
    // console.log(res.logs[0].args)
    loanId1 = res.logs[0].args.loanId.toNumber();
    let paymentCycleAmount = res.logs[0].args.paymentCycleAmount.toNumber();

    //  let res2 = await poolAddressInstance.calculateNextDueDate(loanId1)
    //  console.log(res2.toNumber())
    // console.log(paymentCycleAmount, "pca");
    assert.equal(loanId1, 0, "Unable to create loan: Wrong LoanId");

    //pool2
    //  res= await poolAddressInstance.loanRequest(
    //     erc20.address,
    //     poolId1,
    //     1000,
    //     loanDefaultDuration,
    //     BigNumber(1, 2),
    //     accounts[1],
    //     {from: accounts[1]}
    //    )
    //    console.log(loanId1, "loanid1")
    //    console.log(res.logs[0].args.loanId.toNumber(), "loanid2")
  });

  it("should Accept loan ", async () => {
    await erc20.approve(poolAddressInstance.address, 10000000000);
    let _balance1 = await erc20.balanceOf(accounts[0]);
    // console.log(_balance1.toNumber())
    res = await poolAddressInstance.AcceptLoan(loanId1, { from: accounts[0] });
    _balance1 = await erc20.balanceOf(accounts[1]);
    // console.log(_balance1.toNumber())
    //Amount that the borrower will get is 979 after cutting fees and market charges
    // assert.equal(_balance1.toNumber(), 979, "Not able to accept loan");
  });

  it("anyone can repay Loan ", async () => {
    // await erc20.transfer(accounts[1], 12000, {from: accounts[0]})
    // console.log((await time.latest()).toNumber())
    // console.log((await poolAddressInstance.calculateNextDueDate(loanId1)).toNumber())

    //First Installment
    await time.increase(paymentCycleDuration + 1);
    let rr = await poolAddressInstance.viewInstallmentAmount(loanId1)
    // console.log(
    //   rr.toNumber()
    // );
    await erc20.approve(poolAddressInstance.address, rr, {
      from: accounts[0],
    });
    res = await poolAddressInstance.repayMonthlyInstallment(loanId1, {
      from: accounts[0],
    });
    // console.log(res.logs[1]);
    // console.log(res.logs[0].args.Amount.toNumber());

    //Second installment
    await time.increase(1000);
    await expectRevert.unspecified(
      poolAddressInstance.repayMonthlyInstallment(loanId1, {
        from: accounts[1],
      })
    );
    //res = await poolAddressInstance.repayMonthlyInstallment(loanId1, { from: accounts[1] })
    //console.log(res.logs[0].args.Amount.toNumber())

    //Full loan Repay
    let b = await poolAddressInstance.viewFullRepayAmount(loanId1)
    await erc20.approve(poolAddressInstance.address, b, {
      from: accounts[0],
    });
    res = await poolAddressInstance.repayFullLoan(loanId1, {
      from: accounts[0],
    });
    // console.log(res.logs[0].args.Amount.toNumber());

    //Full loan repaid, should revert.
    await time.increase(paymentCycleDuration + 1);

    assert(
      (await poolAddressInstance.viewFullRepayAmount(loanId1)).toNumber() == 0,
      "Loan not fully repaid, viewFullRepayment"
    );
    await erc20.approve(poolAddressInstance.address, 205000000, {
      from: accounts[0],
    });
    await expectRevert.unspecified(
      poolAddressInstance.repayFullLoan(loanId1, { from: accounts[0] })
    );
  });

});
