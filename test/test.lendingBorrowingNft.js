const { ether, constants, expectEvent, shouldFail, time, expectRevert } = require('@openzeppelin/test-helpers');
const moment = require('moment');
const PiNFT = artifacts.require("piNFT");
const SampleERC20 = artifacts.require("mintToken");
const NftLendingBorrowing = artifacts.require("NFTlendingBorrowing");
const AconomyFee = artifacts.require("AconomyFee")

const BN = require('bn.js');
// const { assert } = require('ethers');


contract("NFTlendingBorrowing", async (accounts) => {

    let piNFT, sampleERC20, nftLendBorrow, aconomyFee;
    let alice = accounts[0];
    let validator = accounts[1];
    let bob = accounts[2];
    let royaltyReciever = accounts[3];
    let carl = accounts[4]

    it("should deploy the NFTlendingBorrowing Contract", async () => {
        piNFT = await PiNFT.deployed()
        aconomyFee = await AconomyFee.deployed();
        sampleERC20 = await SampleERC20.deployed()
        nftLendBorrow = await NftLendingBorrowing.deployed();
        assert(nftLendBorrow * sampleERC20 * nftLendBorrow !== undefined || "" || null || NaN, "NFTLendingBorrowing contract was not deployed");
    });

    it("mint NFT and list for lending", async () => {

        await aconomyFee.transferOwnership(accounts[9]);
        let feeAddress = await aconomyFee.getAconomyOwnerAddress();
        await aconomyFee.setProtocolFee(200,{ from: accounts[9] });
        assert.equal(feeAddress, accounts[9],"Wrong Protocol Owner");
        let feee1 = await aconomyFee.protocolFee();
        console.log("protocolFee", feee1.toString())

        let b1 = await sampleERC20.balanceOf(feeAddress)
        console.log("fee 1", b1.toNumber())

        const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);
        const feee = await aconomyFee.protocolFee();
        console.log("protocolFee", feee.toString())
        const tokenId = tx.logs[0].args.tokenId.toNumber();
        assert(tokenId === 0, "Failed to mint or wrong token Id");
        assert.equal(await piNFT.balanceOf(alice), 1, "Failed to mint");

        const tx1 = await nftLendBorrow.listNFTforBorrowing(
            tokenId,
            piNFT.address,
            2000,
            300,
            300
        )
        const NFTid = tx1.logs[0].args.NFTid.toNumber()
        assert(NFTid === 1, "Failed to list NFT for Lending")
    })

    it("let alice Set new percent fee", async () => {
        const tx = await nftLendBorrow.setPercent(1, 1000, { from: alice })
        await expectRevert(nftLendBorrow.setPercent(1, 1000, { from: bob }), "Not the owner")
        const Percent = tx.logs[0].args.Percent.toNumber();
        assert(Percent == 1000, "Percent should be 1000")
    })

    it("let alice Set new Duration Time", async () => {
        const tx = await nftLendBorrow.setDurationTime(1, 200, { from: alice })
        await expectRevert(nftLendBorrow.setDurationTime(1, 200, { from: bob }), "Not the owner")
        const Duration = tx.logs[0].args.Duration.toNumber();
        assert(Duration == 200, "Percent should be 1000")
    })


    it("let alice Set new Expected Amount", async () => {
        const tx = await nftLendBorrow.setExpectedAmount(1, 200, { from: alice })
        await expectRevert(nftLendBorrow.setExpectedAmount(1, 200, { from: bob }), "Not the owner")
        const expectedAmount = tx.logs[0].args.expectedAmount.toNumber();
        assert(expectedAmount == 200, "Percent should be 1000")
    })

    it("Bid for NFT", async () => {

        await sampleERC20.mint(bob, 200)
        await sampleERC20.approve(nftLendBorrow.address, 200, { from: bob })
        const tx = await nftLendBorrow.Bid(
            1,
            100,
            sampleERC20.address,
            100,
            200,
            200,
            { from: bob }
        )
        const BidId = tx.logs[0].args.BidId.toNumber()
        assert(BidId == 0, "Bid not placed successfully")

        await sampleERC20.mint(carl, 200)
        await sampleERC20.approve(nftLendBorrow.address, 200, { from: carl })
        const tx2 = await nftLendBorrow.Bid(
            1,
            100,
            sampleERC20.address,
            10,
            200,
            200,
            { from: carl }
        )

        const BidId2 = tx2.logs[0].args.BidId.toNumber()
        assert(BidId2 == 1, "Bid not placed successfully")


        await sampleERC20.mint(carl, 200)
        await sampleERC20.approve(nftLendBorrow.address, 200, { from: carl })
        const tx3 = await nftLendBorrow.Bid(
            1,
            100,
            sampleERC20.address,
            10,
            200,
            200,
            { from: carl }
        )

        const BidId3 = tx3.logs[0].args.BidId.toNumber()
        assert(BidId3 == 2, "Bid not placed successfully")


    })

    it("Should Accept Bid", async () => {

        await piNFT.approve(nftLendBorrow.address, 0)

        const tx = await nftLendBorrow.AcceptBid(
            1,
            0
        )
        // let b2 = await sampleERC20.balanceOf(feeAddress)
        // console.log("fee 2", b2.toNumber())
        // assert.equal(b2 - b1, 1)
        let nft = await nftLendBorrow.NFTdetails(1);
        let bid = await nftLendBorrow.Bids(1,0);
        assert.equal(nft.bidAccepted, true);
        assert.equal(nft.listed, true);
        assert.equal(nft.repaid, false);
        assert.equal(bid.bidAccepted, true);
        assert.equal(bid.withdrawn, false);
    })

    it("Should Reject Third Bid by NFT Owner", async () => {

        const newBalance1 = await sampleERC20.balanceOf(carl);
        console.log("dd",newBalance1.toString())
        assert.equal(newBalance1.toString(), 200, "carl balance must be 300");


        const tx = await nftLendBorrow.rejectBid(
            1,
            2
        )
        let Bid = await nftLendBorrow.Bids(1, 2);
        assert.equal(Bid.withdrawn, true, "Mapping Not changed");
        const newBalance = await sampleERC20.balanceOf(carl);
        console.log("dd",newBalance.toString())
        assert.equal(newBalance.toString(), 300, "carl balance must be 300");
    })

    it("Withdraw Third Bid", async () => {
        await expectRevert(nftLendBorrow.withdraw(1, 2, { from: carl }), "Already withdrawn")

    })

    it("Should Repay Bid", async () => {

        let feeAddress = await aconomyFee.getAconomyOwnerAddress();
        assert.equal(feeAddress, accounts[9],"Wrong Protocol Owner");
        const feee = await aconomyFee.protocolFee();
        console.log("protocolFee", feee.toString())

        let b1 = await sampleERC20.balanceOf(feeAddress)
        console.log("fee 1", b1.toNumber())

        let fee = new BN(100).mul(new BN(2))
        console.log("feeeee",fee.toString());
        
        let aa = new BN(100).add(new BN(fee).div(new BN(100)))
        console.log("ttl",aa.toString())
        await sampleERC20.approve(nftLendBorrow.address, 103)
        const tx = await nftLendBorrow.Repay(
            1,
            0
        )
        const amount = tx.logs[0].args.Amount.toNumber()
        console.log("Amount", amount)
        assert.equal(amount, 103, "false Amount")
        let nft = await nftLendBorrow.NFTdetails(1);
        assert.equal(nft.listed, false)
    })

    it("Withdraw second Bid", async () => {
        await expectRevert(nftLendBorrow.withdraw(1, 1, { from: carl }), "Can't withdraw Bid before expiration")

        await time.increase(time.duration.seconds(201))
        // console.log( (await time.latest()).toNumber())

        const res = await nftLendBorrow.withdraw(1, 1, { from: carl })

        assert(res.receipt.status == true, "Unable to withdraw bid")
        let bid = await nftLendBorrow.Bids(1,1);
        assert.equal(bid.bidAccepted, false);
        assert.equal(bid.withdrawn, true);
    })

    it("Should remove the NFT from listing", async () => {

        const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);
        const tokenId = tx.logs[0].args.tokenId.toNumber();
        assert(tokenId === 1, "Failed to mint or wrong token Id");
        assert.equal(await piNFT.balanceOf(alice), 2, "Failed to mint");

        const tx1 = await nftLendBorrow.listNFTforBorrowing(
            tokenId,
            piNFT.address,
            1000,
            200,
            200
        )
        const NFTid = tx1.logs[0].args.NFTid.toNumber()

        const tx2 = await nftLendBorrow.removeNFTfromList(2)
        assert(tx2.receipt.status === true, "Unable to remove NFT from listing")
        let t = await nftLendBorrow.NFTdetails(2);
        assert.equal(t.listed, false);
    })

});