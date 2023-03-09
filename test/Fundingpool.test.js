const FundingPool = artifacts.require("FundingPool");
const PoolRegistry = artifacts.require("poolRegistry");
const IERC20 = artifacts.require("IERC20");
var BigNumber = require('big-number');
var moment = require('moment');
const truffleAssert = require('truffle-assertions');
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
    const erc20Amount = 1000;
    const maxLoanDuration = 90;
    const interestRate = 10;
    const expiration = Math.floor(Date.now() / 1000) + 3600; // expires in an hour


    const paymentCycleDuration = moment.duration(30, 'days').asSeconds()
    const loanDefaultDuration = moment.duration(180, 'days').asSeconds()
    const loanExpirationDuration = moment.duration(1, 'days').asSeconds()
    const expirationTime = BigNumber(moment.now()).add(
    moment.duration(30, 'days').seconds())
    
    let aconomyFee, poolRegis, attestRegistry, attestServices, res, poolId1, pool1Address,poolId2,  loanId1, poolAddressInstance, erc20;

    describe("supplyToPool()", () => {

    let fundingpooladdress = 0; 
    let bidId;


    it("should create Pool", async() => {
      // console.log("attestTegistry: ", attestServices.address)
      poolRegis = await PoolRegistry.deployed()
     res =  await poolRegis.createPool(
          paymentCycleDuration,
          loanDefaultDuration,
          loanExpirationDuration,
          100,
          1000,
          "sk.com",
          true,
          true
      );
      console.log(res);
      poolId1 = res.logs[6].args.poolId.toNumber()
      console.log(poolId1, "poolId1")
      poolId = poolId1;
      pool1Address =await poolRegis.getPoolAddress(poolId1);
      console.log(pool1Address, "poolAdress")
      fundingpooladdress = pool1Address;
    })

    it("should add Lender to the pool", async() => {
      res = await poolRegis.lenderVarification(poolId1, accounts[1])
      assert.equal(res.isVerified_, false, "AddLender function not called but verified")
      await poolRegis.addLender(poolId1, accounts[1], expirationTime, {from: accounts[0]} )
      res = await poolRegis.lenderVarification(poolId1, accounts[1])
      assert.equal(res.isVerified_, true, "Lender Not added to pool, lenderVarification failed")
    })

    it("should add Borrower to the pool", async() => {
      await poolRegis.addBorrower(poolId1, accounts[2], expirationTime, {from: accounts[0]} )
      res = await poolRegis.borrowerVarification(poolId1, accounts[2])
      assert.equal(res.isVerified_, true, "Borrower Not added to pool, borrowerVarification failed")
    })

    it("should allow lender to supply funds to the pool", async () => {
      

      erc20 = await lendingToken.deployed()
      fundingpoolInstance = await FundingPool.at(fundingpooladdress);

      await erc20.transfer(lender, erc20Amount, {from : accounts[0]})

      await erc20.approve(fundingpoolInstance.address, erc20Amount, {
        from: lender,
      });

      const tx = await fundingpoolInstance.supplyToPool(
        poolId,
        erc20.address,
        erc20Amount,
        loanDefaultDuration,
        200,
        expiration,
        { from: lender }
      );

      bidId = tx.logs[0].args.BidId.toNumber();
      // console.log(bidId, "bidid");
      // console.log(tx.logs[0].args);
      const fundDetail = await fundingpoolInstance.lenderPoolFundDetails(
        lender,
        poolId,
        erc20.address,
        bidId
      );
      // console.log(fundDetail)
      assert.equal(fundDetail.amount, erc20Amount);
      assert.equal(fundDetail.maxDuration, loanDefaultDuration);
      assert.equal(fundDetail.interestRate, 200);
      assert.equal(fundDetail.expiration, expiration);
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
          interestRate,
          loanExpirationDuration,
          { from: nonLender }
        ),
        "Not verified lender"
      );
    });

    it('should accept the bid and emit AcceptedBid event', async function () {
      const tx = await fundingpoolInstance.AcceptBid(
        poolId,
        erc20.address,
        bidId,
        lender,
        receiver
      );
      console.log(poolId)
      // const expectedPaymentCycleAmount = ethers.utils.parseEther('0.421875'); // calculated using LibCalculations

      // expect(tx)
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
      expect(fundDetail.state.toNumber()).to.equal(2); // BidState.ACCEPTED
      // expect(fundDetail.paymentCycleAmount).to.equal(
      //   expectedPaymentCycleAmount
      // );
      expect(fundDetail.acceptBidTimestamp).to.not.equal(moment.now());
      // assert.equal(bidid)
    });

    it('should revert if bid is not pending', async function () {
      // await fundingpoolInstance.AcceptBid(
      //   poolId,
      //   erc20.address,
      //   bidId,
      //   lender,
      //   receiver
      // );
      await expect(
        fundingpoolInstance.AcceptBid(
          poolId,
          erc20.address,
          bidId,
          lender.address,
          receiver.address
        )
      ).to.be.revertedWith('Bid must be pending');
    });

    it('should allow the lender to withdraw funds after the bid has expired and not been accepted', async () => {
      const fundDetail = await fundingpoolInstance.lenderPoolFundDetails( lender,
        poolId,
        erc20.address,
        bidId);
      const { amount } = fundDetail;
  
      // Wait for the bid to expire
      await ethers.provider.send('evm_increaseTime', [31 * 24 * 60 * 60]); // 31 days
      await ethers.provider.send('evm_mine');
  
      // Check that the lender can withdraw their funds
      const balanceBefore = await token.balanceOf(lender.address);
      await fundingpoolInstance.connect(lender).withdraw(poolId, token.address, bidId);
      const balanceAfter = await token.balanceOf(lender.address);
      expect(balanceAfter.sub(balanceBefore)).to.equal(amount);
    });

    it('should decrease the account balance by the specified amount', () => {
      // Create a new account with a balance of $100
      const account = new Account(100);

      // Withdraw $50 from the account
      account.withdraw(50);

      // The new balance should be $50
      assert.equal(account.getBalance(), 50);
    });

    it('should throw an InsufficientFundsError if the amount is greater than the account balance', () => {
      // Create a new account with a balance of $100
      const account = new Account(100);

      // Attempt to withdraw $150 from the account
      assert.throws(() => {
        account.withdraw(150);
      }, InsufficientFundsError);
    });

    it("should allow lender to cancel a pending bid", async () => {
      const tx = await fundingpoolInstance.cancelBid(poolId, erc20.address, bidId, { from: lender });
      const fundDetail = await fundingpoolInstance.lenderPoolFundDetails( lender,
        poolId,
        erc20.address,
        bidId);
  
      assert.equal(fundDetail.state, 2, "Bid state should be cancelled");
      assert.equal(fundDetail.amount, 0, "Bid amount should be zero");
      assert.equal(tx.logs.length, 1, "Should emit one event");
      assert.equal(tx.logs[0].event, "BidCancelled", "Event name should be BidCancelled");
      assert.equal(tx.logs[0].args.bidId, bidId, "Bid ID should match");
    });
  
    it("should not allow non-lender to cancel a bid", async () => {
      await expectRevert(
        fundingpoolInstance.cancelBid(poolId, erc20.address, bidId, { from: accounts[2] }),
        "Bid must be pending"
      );
    });
  
    it("should not allow cancelling a bid that is not pending", async () => {
      await fundingpoolInstance.AcceptBid(poolId, erc20.address, bidId, lender, poolOwner);
      await expectRevert(
        fundingpoolInstance.cancelBid(poolId, erc20.address, bidId, { from: lender }),
        "Bid must be pending"
      );
    });
  });
});