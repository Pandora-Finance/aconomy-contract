var BigNumber = require('big-number');
var moment = require('moment');
const { BN, constants, expectEvent, shouldFail, time, expectRevert } = require('@openzeppelin/test-helpers');
const PoolRegistry = artifacts.require("poolRegistry");
const CollateralController = artifacts.require("CollateralController")
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
  let aconomyFee, poolRegis, collateral, attestRegistry, attestServices, res, poolId1, pool1Address, poolId2, loanId1, poolAddressInstance, erc20;

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
    poolAddressInstance = await PoolAddress.deployed();
    collateralAddress = await poolAddressInstance.collateralController();
    collateral = await CollateralController.at(collateralAddress);
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
  })

  it("should add Lender to the pool", async () => {
    res = await poolRegis.lenderVerification(poolId1, accounts[0])
    assert.equal(res.isVerified_, false, "AddLender function not called but verified")
    await poolRegis.addLender(poolId1, accounts[0], expirationTime, { from: accounts[0] })
    res = await poolRegis.lenderVerification(poolId1, accounts[0])
    assert.equal(res.isVerified_, true, "Lender Not added to pool, lenderVarification failed")
  })

  it("should add Borrower to the pool", async () => {
    await poolRegis.addBorrower(poolId1, accounts[1], expirationTime, { from: accounts[0] })
    res = await poolRegis.borrowerVerification(poolId1, accounts[1])
    assert.equal(res.isVerified_, true, "Borrower Not added to pool, borrowerVerification failed")
  })

  it("testing loan request function", async () => {
    erc20 = await lendingToken.deployed()
    await erc20.mint(accounts[0], '10000000000')
    res = await poolAddressInstance.loanRequest(
      erc20.address,
      poolId1,
      1000000000,
      loanDefaultDuration,
      100,
      accounts[1],
      { from: accounts[1] }
    )
    loanId1 = res.logs[0].args.loanId.toNumber()
    let paymentCycleAmount = res.logs[0].args.paymentCycleAmount.toNumber()
    console.log(paymentCycleAmount, "pca")
    assert.equal(loanId1, 0, "Unable to create loan: Wrong LoanId")
  })

  it("should allow borrower to add collateral", async () => {
    await erc20.mint(accounts[1], '10000')
    await erc20.approve(collateral.address, 10000, {from: accounts[1]})
    assert.equal(await erc20.balanceOf(accounts[1]), 10000);
    await collateral.depositCollateral(loanId1, erc20.address, '10000', { from: accounts[1] });
    assert.equal(await erc20.balanceOf(accounts[1]), 0);
    assert.equal(await erc20.balanceOf(collateral.address), 10000);
  })

  it("should allow borrower to remove collateral", async () => {
    assert.equal(await erc20.balanceOf(accounts[1]), 0);
    await collateral.withdrawCollateral(loanId1, { from: accounts[1] });
    assert.equal(await erc20.balanceOf(accounts[1]), 10000);
    assert.equal(await erc20.balanceOf(collateral.address), 0);
  })

  it("should allow borrower to re add collateral", async () => {
    await erc20.approve(collateral.address, 10000, {from: accounts[1]})
    await collateral.depositCollateral(loanId1, erc20.address, '10000', { from: accounts[1] });
    assert.equal(await erc20.balanceOf(accounts[1]), 0);
    assert.equal(await erc20.balanceOf(collateral.address), 10000);
  })

  it("should Accept loan ", async () => {
    await erc20.approve(poolAddressInstance.address, 1000000000)
    let _balance1 = await erc20.balanceOf(accounts[0]);
    console.log(_balance1.toNumber())
    res = await poolAddressInstance.AcceptLoan(loanId1, { from: accounts[0] })
    _balance1 = await erc20.balanceOf(accounts[1]);
    //console.log(_balance1.toNumber())
    //Amount that the borrower will get is 999 after cutting fees and market charges
    assert.equal(_balance1.toNumber(), 990000000, "Not able to accept loan");
  })

  it("should not allow borrower to remove collateral after bid is accepted", async () => {
    await truffleAssert.fails(collateral.withdrawCollateral(loanId1, { from: accounts[1] }))
  })

  it("should repay full amount", async () => {
    let loan = await poolAddressInstance.loans(loanId1);
    advanceBlockAtTime(loan.loanDetails.lastRepaidTimestamp + paymentCycleDuration + 20)
    let bal = await poolAddressInstance.viewFullRepayAmount(loanId1)
    console.log(bal.toNumber());
    let b = await erc20.balanceOf(accounts[1]);
    await erc20.transfer(accounts[1], bal - b + 100, { from: accounts[0] })
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

  it("should allow borrower to remove collateral", async () => {
    assert.equal(await erc20.balanceOf(collateral.address), 10000);
    await collateral.withdrawCollateral(loanId1, { from: accounts[1] });
    assert.equal(await erc20.balanceOf(collateral.address), 0);
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
      100,
      accounts[1],
      { from: accounts[1] }
    )
    loanId1 = res.logs[0].args.loanId.toNumber()
    let paymentCycleAmount = res.logs[0].args.paymentCycleAmount.toNumber()
    console.log(paymentCycleAmount, "pca")
    assert.equal(loanId1, 1, "Unable to create loan: Wrong LoanId")
  })

  it("should allow borrower to re add collateral", async () => {
    await erc20.approve(collateral.address, 10000, {from: accounts[1]})
    await collateral.depositCollateral(loanId1, erc20.address, '10000', { from: accounts[1] });
    assert.equal(await erc20.balanceOf(collateral.address), 10000);
  })

  it("should not allow borrower to add collateral without withdrawing", async () => {
    await truffleAssert.fails(collateral.depositCollateral(loanId1, erc20.address, '10000', { from: accounts[1] }), "withdraw before re deposit")
  })

  it("should Accept loan ", async () => {
    await erc20.approve(poolAddressInstance.address, 1000000000)
    let _balance1 = await erc20.balanceOf(accounts[0]);
    console.log(_balance1.toNumber())
    res = await poolAddressInstance.AcceptLoan(loanId1, { from: accounts[0] })
  })

  it("should not allow liquidation before being defaulted", async () => {
    await erc20.mint(accounts[3], '11000000000')
    let bal = await poolAddressInstance.viewFullRepayAmount(loanId1)
    await erc20.approve(poolAddressInstance.address, bal + 10, { from: accounts[3] })
    await truffleAssert.reverts(poolAddressInstance.liquidateLoan(loanId1, { from: accounts[3] }), "not defaulted")
  })

  it("should allow liquidator to liquidate loan", async () => {
    await time.increase((paymentCycleDuration * 7) + 10);
    assert.equal(await poolAddressInstance.isLoanDefaulted(loanId1), true);
    assert.equal(await erc20.balanceOf(accounts[3]), 11000000000);
    let bal = await poolAddressInstance.viewFullRepayAmount(loanId1)
    await erc20.approve(poolAddressInstance.address, bal + 10, { from: accounts[3] })
    let _balance1 = await erc20.balanceOf(accounts[3]);
    let tx = await poolAddressInstance.liquidateLoan(loanId1, { from: accounts[3] })
    let balance1 = await erc20.balanceOf(accounts[3]);
    let paid = tx.logs[0].args.Amount
    assert.equal(await (await new BN(balance1).add(await new BN(paid)).sub(await new BN(_balance1))), 10000)
    loan = await poolAddressInstance.loans(loanId1);
    assert.equal(loan.state, 1);
  })

  it("should not allow borrower to remove collateral after loan is liquidated", async () => {
    await truffleAssert.fails(collateral.withdrawCollateral(loanId1, { from: accounts[1] }))
  })
})