var BigNumber = require('big-number');
var moment = require('moment');
const PoolRegistry = artifacts.require("poolRegistry");
const AttestRegistry = artifacts.require("AttestationRegistry")
const AttestServices = artifacts.require("AttestationServices");
const AconomyFee = artifacts.require("AconomyFee")
const PoolAddress = artifacts.require('poolAddress')
const lendingToken = artifacts.require('mintToken')
const poolAddress = artifacts.require("poolAddress")
contract("PoolAddress", async (accounts) =>{
    const paymentCycleDuration = moment.duration(30, 'days').asSeconds()
    const loanDefaultDuration = moment.duration(180, 'days').asSeconds()
    const loanExpirationDuration = moment.duration(1, 'days').asSeconds()
    const expirationTime = BigNumber(moment.now()).add(
    moment.duration(30, 'days').seconds())
    let aconomyFee, poolRegis, attestRegistry, attestServices, res, poolId1, pool1Address,poolId2,  loanId1, poolAddressInstance, erc20;

    it("should create Pool", async() => {
        // console.log("attestTegistry: ", attestServices.address)
        poolRegis = await PoolRegistry.deployed()
       res =  await poolRegis.createPool(
            paymentCycleDuration,
            loanDefaultDuration,
            loanExpirationDuration,
            10,
            10,
            "sk.com",
            true,
            true
        );
        poolId1 = res.logs[6].args.poolId.toNumber()
        console.log(poolId1, "poolId1")
        pool1Address = res.logs[4].args.poolAddress;
        console.log(pool1Address, "poolAdress")
    })

    it("should add Lender to the pool", async() => {
        res = await poolRegis.lenderVerification(poolId1, accounts[0])
        assert.equal(res.isVerified_, false, "AddLender function not called but verified")
       await poolRegis.addLender(poolId1, accounts[0], expirationTime, {from: accounts[0]} )
        res = await poolRegis.lenderVerification(poolId1, accounts[0])
        assert.equal(res.isVerified_, true, "Lender Not added to pool, lenderVarification failed")
    })  

    it("should add Borrower to the pool", async() => {
        await poolRegis.addBorrower(poolId1, accounts[1], expirationTime, {from: accounts[0]} )
        res = await poolRegis.borrowerVerification(poolId1, accounts[1])
        assert.equal(res.isVerified_, true, "Borrower Not added to pool, borrowerVerification failed")
    }) 

    it("testing loan request function", async ()=> {
        erc20 = await lendingToken.deployed()
        poolAddressInstance = await PoolAddress.deployed();
        res = await poolAddressInstance.loanRequest(
        erc20.address,
        poolId1,
        1000,
        loanDefaultDuration,
        1,
        accounts[1],
        {from: accounts[1]}
        )
        loanId1 = res.logs[0].args.loanId.toNumber()
        let paymentCycleAmount = res.logs[0].args.paymentCycleAmount.toNumber()
        console.log(paymentCycleAmount, "pca")
        assert.equal(loanId1, 0, "Unable to create loan: Wrong LoanId")
    })    

    it("should Accept loan ", async() => {
        await erc20.approve(poolAddressInstance.address, 100000)
        let _balance1 = await erc20.balanceOf(accounts[0]);
        // console.log(_balance1.toNumber())
        res = await poolAddressInstance.AcceptLoan(loanId1, {from:accounts[0]})
        _balance1 = await erc20.balanceOf(accounts[1]);
        //console.log(_balance1.toNumber())
        //Amount that the borrower will get is 999 after cutting fees and market charges
        assert.equal(_balance1.toNumber(), 999, "Not able to accept loan");
    })

    it("should calculate the next due date", async() => {
        loanId1 = res.logs[0].args.loanId.toNumber()
        console.log(loanId1)
        let r = await poolAddressInstance.calculateNextDueDate(loanId1)
        console.log("due", r.toString())
    })

    it("should not work after the loan expires", async() => {
        loanId1 = res.logs[0].args.loanId.toNumber()
        let r = await poolAddressInstance.isLoanExpired(loanId1)
        assert.equal(r, false, "Unable to create loan: Wrong LoanId")
    })

    it("should check the payment done in time", async() => {
        loanId1 = res.logs[0].args.loanId.toNumber()
        let r = await poolAddressInstance.isPaymentLate(loanId1)
        assert.equal(r, false, "Unable to create loan: Wrong LoanId")
    })

    it("should view intallment amount", async() => {
        loanId1 = res.logs[0].args.loanId.toNumber()
        let r = await poolAddressInstance.viewInstallmentAmount(loanId1)
        console.log('installment', r.toString());
    })

    it("should repay full amount", async() => {
         await erc20.transfer(accounts[1], 1, {from: accounts[0]})
         let bal = await poolAddressInstance.viewFullRepayAmount(loanId1)
         console.log(bal);
         await erc20.approve(poolAddressInstance.address, bal, {from:accounts[1]})
         let r = await poolAddressInstance.repayFullLoan(loanId1, {from: accounts[1]})
         // console.log(res)
         assert.equal(r.receipt.status, true, "Not able to repay loan")
    })
})