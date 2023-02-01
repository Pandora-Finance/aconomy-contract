var BigNumber = require('big-number');
var moment = require('moment');
const PoolRegistry = artifacts.require("poolRegistry");
const AttestRegistry = artifacts.require("attestationRegistry")
const AttestServices = artifacts.require("attestationServices");
const AconomyFee = artifacts.require("AconomyFee")
const PoolAddress = artifacts.require('poolAddress')
const lendingToken = artifacts.require('LendingToken')


contract("poolRegistry", async (accounts) => {

    const paymentCycleDuration = moment.duration(30, 'days').asSeconds()
const loanDefaultDuration = moment.duration(180, 'days').asSeconds()
const loanExpirationDuration = moment.duration(1, 'days').asSeconds()

const expirationTime = BigNumber(moment.now()).add(
    moment.duration(30, 'days').seconds())
  

let aconomyFee, poolRegis, attestRegistry, attestServices, res, poolId1, pool1Address, loanId1, poolAddressInstance, erc20;

    it("should set Aconomyfee", async () => {
        aconomyFee = await AconomyFee.deployed();
       await aconomyFee.setProtocolFee(200);
        let protocolFee = await aconomyFee.protocolFee()
        assert.equal(protocolFee.toNumber(), 200, "Wrong set Protocol Fee")
    })

    it("should create attestRegistry, attestationService", async () => {
        // attestRegistry = await AttestRegistry.deployed();
        // assert.notEqual(attestRegistry.address, null, "address is zero");
        attestServices = await AttestServices.deployed();
        assert.notEqual(attestServices.address, null||undefined, "Attestation Services unable to deployed")
    });


    it("should create Pool", async() => {
        // console.log("attestTegistry: ", attestServices.address)
        poolRegis = await PoolRegistry.deployed()
       res =  await poolRegis.createPool(
            accounts[0],
            paymentCycleDuration,
            loanDefaultDuration,
            loanExpirationDuration,
            10,
            true,
            true,
            "sk.com"
        );
        poolId1 = res.logs[0].args.poolId.toNumber()
        pool1Address = res.logs[5].args.poolAddress;


    })


    it("should add Lender to the pool", async() => {
        res = await poolRegis.lenderVarification(poolId1, accounts[0])
        assert.equal(res.isVerified_, false, "AddLender function not called but verified")
       await poolRegis.addLender(poolId1, accounts[0], expirationTime, {from: accounts[0]} )
        res = await poolRegis.lenderVarification(poolId1, accounts[0])
        assert.equal(res.isVerified_, true, "Lender Not added to pool, lenderVarification failed")
    })

    it("should add Borrower to the pool", async() => {
        
         await poolRegis.addBorrower(poolId1, accounts[1], expirationTime, {from: accounts[0]} )
         res = await poolRegis.borrowerVarification(poolId1, accounts[1])
        assert.equal(res.isVerified_, true, "Borrower Not added to pool, borrowerVarification failed")
    })

    it("should allow Attested Borrower to Request Loan in a Pool", async() => {

         erc20 = await lendingToken.deployed()
        
        poolAddressInstance = await PoolAddress.at(pool1Address)

       res = await poolAddressInstance.loanRequest(
        erc20.address,
        poolId1,
        1000,
        loanDefaultDuration,
        BigNumber(1, 2),
        accounts[1],
        {from: accounts[1]}
       )

       loanId1 = res.logs[0].args.loanId.toNumber()
     let paymentCycleAmount = res.logs[0].args.paymentCycleAmount.toNumber()
     console.log(paymentCycleAmount, "pca")
     assert.equal(loanId1, 0, "Unable to create loan: Wrong LoanId")
    })

    it("should Accept loan ", async() => {
        await erc20.approve(pool1Address, 100)
        let _balance1 = await erc20.balanceOf(accounts[1]);
        console.log(_balance1.toNumber())
        res = await poolAddressInstance.AcceptLoan(loanId1, {from:accounts[0]})
        _balance1 = await erc20.balanceOf(accounts[1]);

        //Amount that the borrower will get is 98 after cutting fees and market charges
        assert.equal(_balance1.toNumber(), 98, "Not able to accept loan");
    })

    it("should repay Loan ", async() => {
        await erc20.transfer(accounts[1], 200, {from: accounts[0]})
        await erc20.approve(pool1Address, 250, {from:accounts[1]})
        res = await poolAddressInstance.repayFullLoan(loanId1, {from: accounts[1]})
        // console.log(res)
    })


})
