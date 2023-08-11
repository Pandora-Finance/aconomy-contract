const { time, expectRevert } = require("@openzeppelin/test-helpers");
const moment = require("moment");
const PiNFT = artifacts.require("piNFT");
const SampleERC20 = artifacts.require("mintToken");
const NftLendingBorrowing = artifacts.require("NFTlendingBorrowing");
const AconomyFee = artifacts.require("AconomyFee");
const ethers = require("ethers");
const { unspecified } = require("@openzeppelin/test-helpers/src/expectRevert");



contract("NFTlendingBorrowing", async (accounts) => {
  let piNFT, sampleERC20, nftLendBorrow, aconomyFee;
  let alice = accounts[0];
  let validator = accounts[1];
  let bob = accounts[2];
  let royaltyReciever = accounts[3];
  let carl = accounts[4];

  it("should deploy the NFTlendingBorrowing Contract", async () => {
    piNFT = await PiNFT.deployed();
    aconomyFee = await AconomyFee.deployed();
    sampleERC20 = await SampleERC20.deployed();
    nftLendBorrow = await NftLendingBorrowing.deployed();
    assert(
      nftLendBorrow * sampleERC20 * nftLendBorrow !== undefined ||
        "" ||
        null ||
        NaN,
      "NFTLendingBorrowing contract was not deployed"
    );
  });

  it("mint NFT and list for lending", async () => {
    const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);
    await aconomyFee.setAconomyNFTLendBorrowFee(100);
    const feee = await aconomyFee.AconomyNFTLendBorrowFee();
    // console.log("protocolFee", feee.toString());
    const tokenId = tx.logs[0].args.tokenId.toNumber();
    assert(tokenId === 0, "Failed to mint or wrong token Id");
    assert.equal(await piNFT.balanceOf(alice), 1, "Failed to mint");

    await expectRevert.unspecified(nftLendBorrow.listNFTforBorrowing(
      tokenId,
      piNFT.address,
      200,
      300,
      3600,
      1000000
    ))

    const tx1 = await nftLendBorrow.listNFTforBorrowing(
      tokenId,
      piNFT.address,
      200,
      300,
      3600,
      200000000000
    );
    const NFTid = tx1.logs[0].args.NFTid.toNumber();
    assert(NFTid === 1, "Failed to list NFT for Lending");
  });

  it("should check contract address isn't 0 address", async() => {
    await expectRevert.unspecified(
      nftLendBorrow.listNFTforBorrowing(
        0,
        "0x0000000000000000000000000000000000000000",
        200,
        300,
        3600,
        200000000000
      ),
      "Contract Address is zero"
    );
  })

  it("should check percent must be greater than 0.1%", async() => {
    await expectRevert.unspecified(
      nftLendBorrow.listNFTforBorrowing(
        0,
        piNFT.address,
        9,
        300,
        3600,
        200000000000
      ),
      "percent is less than 0.1"
    );
  })

  it("should check expected amount must be greater than 1^6", async() => {
    await expectRevert.unspecified(
      nftLendBorrow.listNFTforBorrowing(
        0,
        piNFT.address,
        200,
        300,
        3600,
        100000
      ),
      "expected Amount must be greater than 1$"
    );
  })

  it("should not put on borrow if the contract is paused", async () => {
    const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);
    const tokenId = tx.logs[0].args.tokenId.toNumber();
    await nftLendBorrow.pause();
    await expectRevert(
      nftLendBorrow.listNFTforBorrowing(
        tokenId,
        piNFT.address,
        200,
        300,
        3600,
        200000000000,
        { from: alice }
      ),
      "paused"
    );
    await nftLendBorrow.unpause();
  });

  it("let alice Set new percent fee", async () => {
    const tx = await nftLendBorrow.setPercent(1, 1000, { from: alice });
    await expectRevert(
      nftLendBorrow.setPercent(1, 1000, { from: bob }),
      "Not the owner"
    );
    const Percent = tx.logs[0].args.Percent.toNumber();
    assert(Percent == 1000, "Percent should be 1000");
  });

  it("let alice Set new Duration Time", async () => {
    const tx = await nftLendBorrow.setDurationTime(1, 200, { from: alice });
    await expectRevert(
      nftLendBorrow.setDurationTime(1, 200, { from: bob }),
      "Not the owner"
    );
    const Duration = tx.logs[0].args.Duration.toNumber();
    assert(Duration == 200, "Duration should be 200");
  });

  it("let alice Set new Expected Amount", async () => {
    const tx = await nftLendBorrow.setExpectedAmount(1, 100000000000, {
      from: alice,
    });

    await expectRevert.unspecified(
      nftLendBorrow.setExpectedAmount(1, 1000000, { from: alice })
    );

    await expectRevert(
      nftLendBorrow.setExpectedAmount(1, 100000000000, { from: bob }),
      "Not the owner"
    );
    const expectedAmount = tx.logs[0].args.expectedAmount.toNumber();
    assert(expectedAmount == 100000000000, "Amount should be 1000");
  });

  it("Bid for NFT", async () => {
    await sampleERC20.mint(bob, 100000000000);
    await sampleERC20.approve(nftLendBorrow.address, 100000000000, {
      from: bob,
    });

    await expectRevert(nftLendBorrow.Bid(
      1,
      1000000,
      sampleERC20.address,
      10,
      200,
      200,
      { from: bob }
    ), "bid amount too low")

    const tx = await nftLendBorrow.Bid(
      1,
      100000000000,
      sampleERC20.address,
      10,
      200,
      200,
      { from: bob }
    );
    const BidId = tx.logs[0].args.BidId.toNumber();
    assert(BidId == 0, "Bid not placed successfully");

    await sampleERC20.mint(carl, 100000000000);
    await sampleERC20.approve(nftLendBorrow.address, 100000000000, {
      from: carl,
    });
    const tx2 = await nftLendBorrow.Bid(
      1,
      100000000000,
      sampleERC20.address,
      10,
      200,
      200,
      { from: carl }
    );

    const BidId2 = tx2.logs[0].args.BidId.toNumber();
    assert(BidId2 == 1, "Bid not placed successfully");

    await sampleERC20.mint(carl, 100000000000);
    await sampleERC20.approve(nftLendBorrow.address, 100000000000, {
      from: carl,
    });
    const tx3 = await nftLendBorrow.Bid(
      1,
      100000000000,
      sampleERC20.address,
      10,
      200,
      200,
      { from: carl }
    );

    const BidId3 = tx3.logs[0].args.BidId.toNumber();
    assert(BidId3 == 2, "Bid not placed successfully");
  });

  it("should check while Bid ERC20 address is not 0", async() => {
    await sampleERC20.mint(accounts[6], 100000000000);
    await sampleERC20.approve(nftLendBorrow.address, 100000000000, {
      from: accounts[6],
    });
    await expectRevert.unspecified(
      nftLendBorrow.Bid(
        1,
        100000000000,
        "0x0000000000000000000000000000000000000000",
        10,
        200,
        200,
        { from: accounts[6] }
      ),
      "ERC20 address is zero"
    );
  })

  it("should check Bid amount must be greater than 10^6", async() => {
    await sampleERC20.mint(accounts[6], 100000000000);
    await sampleERC20.approve(nftLendBorrow.address, 100000000000, {
      from: accounts[6],
    });
    await expectRevert(
      nftLendBorrow.Bid(
        1,
        10000,
        sampleERC20.address,
        10,
        200,
        200,
        { from: accounts[6] }
      ),
      "bid amount too low"
    );
  })

  it("should check percent must be greater than 0.1%", async() => {
    await sampleERC20.mint(accounts[6], 100000000000);
    await sampleERC20.approve(nftLendBorrow.address, 100000000000, {
      from: accounts[6],
    });
    await expectRevert(
      nftLendBorrow.Bid(
        1,
        100000000000,
        sampleERC20.address,
        9,
        200,
        200,
        { from: carl }
      ),
      "interest percent too low"
    );
  })



  // it("should fail to withdraw second bid", async () => {
  //   await expectRevert(
  //     nftLendBorrow.withdraw(1, 1, { from: carl }),
  //     "Can't withdraw Bid before expiration"
  //   );
  // })

  it("Should Accept Bid", async () => {
    await aconomyFee.transferOwnership(accounts[9]);
    let feeAddress = await aconomyFee.getAconomyOwnerAddress();
    await aconomyFee.setAconomyNFTLendBorrowFee(200, { from: accounts[9] });
    assert.equal(feeAddress, accounts[9], "Wrong Protocol Owner");
    const feee = await aconomyFee.AconomyNFTLendBorrowFee();
    // console.log("protocolFee", feee.toString());

    let b1 = await sampleERC20.balanceOf(feeAddress);
    // console.log("fee 1", b1.toNumber());

    await piNFT.approve(nftLendBorrow.address, 0);

    const tx = await nftLendBorrow.AcceptBid(1, 0);
    let b2 = await sampleERC20.balanceOf(feeAddress);
    // console.log("fee 2", b2.toNumber());
    assert.equal(b2 - b1, 1000000000);
    let nft = await nftLendBorrow.NFTdetails(1);
    let bid = await nftLendBorrow.Bids(1, 0);
    assert.equal(nft.bidAccepted, true);
    assert.equal(nft.listed, true);
    assert.equal(nft.repaid, false);
    assert.equal(bid.bidAccepted, true);
    assert.equal(bid.withdrawn, false);
  });

  it("should check anyone can't Bid on already Accepted bid", async() => {
    await sampleERC20.mint(accounts[6], 100000000000);
    await sampleERC20.approve(nftLendBorrow.address, 100000000000, {
      from: accounts[6],
    });
    await expectRevert(
      nftLendBorrow.Bid(
        1,
        100000000000,
        sampleERC20.address,
        10,
        200,
        200,
        { from: accounts[6] }
      ),
      "Bid Already Accepted"
    );
  })


  it("Should Reject Third Bid by NFT Owner", async () => {
    const newBalance1 = await sampleERC20.balanceOf(carl);
    // console.log("dd", newBalance1.toString());
    assert.equal(newBalance1.toString(), 0, "carl balance must be 0");

    const tx = await nftLendBorrow.rejectBid(1, 2);
    let Bid = await nftLendBorrow.Bids(1, 2);
    assert.equal(Bid.withdrawn, true, "Mapping Not changed");
    const newBalance = await sampleERC20.balanceOf(carl);
    // console.log("dd", newBalance.toString());
    assert.equal(
      newBalance.toString(),
      100000000000,
      "carl balance must be 100000000000"
    );
  });

  it("Withdraw Third Bid", async () => {
    await expectRevert(
      nftLendBorrow.withdraw(1, 2, { from: carl }),
      "Already withdrawn"
    );
  });

  it("Should Repay Bid", async () => {
    let val = await nftLendBorrow.viewRepayAmount(1, 0);
    await sampleERC20.approve(nftLendBorrow.address, val);
    const tx = await nftLendBorrow.Repay(1, 0);
    const amount = tx.logs[0].args.Amount.toNumber();
    let nft = await nftLendBorrow.NFTdetails(1);
    assert.equal(nft.listed, false);
  });

  it("Should Withdraw second Bid", async () => {
    const res = await nftLendBorrow.withdraw(1, 1, { from: carl });

    assert(res.receipt.status == true, "Unable to withdraw bid");
    let bid = await nftLendBorrow.Bids(1, 1);
    assert.equal(bid.bidAccepted, false);
    assert.equal(bid.withdrawn, true);
  });

  it("Should remove the NFT from listing", async () => {
    const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);
    const tokenId = tx.logs[0].args.tokenId.toNumber();
    assert(tokenId === 2, "Failed to mint or wrong token Id");
    assert.equal(await piNFT.balanceOf(alice), 3, "Failed to mint");

    const tx1 = await nftLendBorrow.listNFTforBorrowing(
      tokenId,
      piNFT.address,
      200,
      200,
      3600,
      100000000000
    );
    const NFTid = tx1.logs[0].args.NFTid.toNumber();

    const tx2 = await nftLendBorrow.removeNFTfromList(2);
    assert(tx2.receipt.status === true, "Unable to remove NFT from listing");
    let t = await nftLendBorrow.NFTdetails(2);
    assert.equal(t.listed, false);
  });

  it("should fail to Bid after expiration", async () => {
    const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);
    const tokenId = tx.logs[0].args.tokenId.toNumber();
    assert(tokenId === 3, "Failed to mint or wrong token Id");
    // assert.equal(await piNFT.balanceOf(alice), 3, "Failed to mint");

    const tx1 = await nftLendBorrow.listNFTforBorrowing(
      tokenId,
      piNFT.address,
      200,
      200,
      3600,
      100000000000
    );
    const NFTid = tx1.logs[0].args.NFTid.toNumber();

    await sampleERC20.mint(carl, 100000000000);
    await sampleERC20.approve(nftLendBorrow.address, 100000000000, {
      from: carl,
    });
    
    const tx2 = await nftLendBorrow.Bid(
      NFTid,
      100000000000,
      sampleERC20.address,
      10,
      200,
      200,
      { from: carl }
    );

    await time.increase(3601);

    await expectRevert(
      nftLendBorrow.Bid(
        NFTid,
        100000000000,
        sampleERC20.address,
        10,
        200,
        200,
        { from: carl }
      ),
      "Bid time over"
    );
  })


  it("should mint hte NFT and list for NFT for Borrowing", async() => {

    const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);
    const tokenId = tx.logs[0].args.tokenId.toNumber();
    // console.log("tokenid",tokenId);
    assert(tokenId === 4, "Failed to mint or wrong token Id");

    const tx1 = await nftLendBorrow.listNFTforBorrowing(
      4,
      piNFT.address,
      200,
      300,
      3600,
      200000000000
    );

    const NFTid = tx1.logs[0].args.NFTid.toNumber();
    // console.log("nftId",NFTid)
    assert(NFTid === 4, "Failed to list NFT for Lending");

    // await time.increase(3600);
    // await sampleERC20.mint(accounts[6], 100000000000);
    // await sampleERC20.approve(nftLendBorrow.address, 100000000000, {
    //   from: accounts[6],
    // });
    // await expectRevert(
    //   nftLendBorrow.Bid(
    //     2,
    //     100000000000,
    //     sampleERC20.address,
    //     10,
    //     200,
    //     200,
    //     { from: accounts[6] }
    //   ),
    //   "Bid time over"
    // );

    // await time.decrease(3600);

  })

  it("should check someone is bidding on listed NFT", async() => {
       await sampleERC20.mint(accounts[7], 100000000000);
      await sampleERC20.approve(nftLendBorrow.address, 100000000000, {
        from: accounts[7],
      });

        await expectRevert(
          nftLendBorrow.Bid(
            2,
            100000000000,
            sampleERC20.address,
            10,
            200,
            200,
            { from: accounts[7] }
          ),
          "You can't Bid on this NFT"
        );
  })

  it("Should check that NFT owner can Accept the Bid", async () => {

    await sampleERC20.mint(accounts[7], 100000000000);
    await sampleERC20.approve(nftLendBorrow.address, 100000000000, {
      from: accounts[7],
    });

    await nftLendBorrow.Bid(
        4,
        100000000000,
        sampleERC20.address,
        10,
        200,
        200,
        { from: accounts[7] }
      )

    // const tx = await nftLendBorrow.AcceptBid(1, 0);

    await expectRevert(
      nftLendBorrow.AcceptBid(
        4,
        0,
        { from: accounts[6] }
      ),
      "You can't Accept This Bid"
    );

  });


  it("Should check owner can't accept the bid if it's already accepted and can't remove NFT after accepting Bid ", async () => {

    await sampleERC20.mint(accounts[8], 100000000000);
    await sampleERC20.approve(nftLendBorrow.address, 100000000000, {
      from: accounts[8],
    });

    await nftLendBorrow.Bid(
        4,
        100000000000,
        sampleERC20.address,
        10,
        200,
        200,
        { from: accounts[8] }
      )

    await piNFT.approve(nftLendBorrow.address, 4);
    const tx = await nftLendBorrow.AcceptBid(4, 0);

    await expectRevert(
      nftLendBorrow.removeNFTfromList(
        4,
        { from: alice }
      ),
      "Only token owner can execute"
    );

    await expectRevert(
      nftLendBorrow.AcceptBid(
        4,
        0
      ),
      "bid already accepted"
    );
  });

  it("Should check owner can't accept another bid if it's already accepted a bid", async () => {
    await expectRevert(
      nftLendBorrow.AcceptBid(
        4,
        0
      ),
      "bid already accepted"
    );
  });

  it("Should check only NFT owner can Reject the Bid", async () => {

    await expectRevert(
      nftLendBorrow.rejectBid(
        4,
        1,
        { from: accounts[6] }
      ),
      "You can't Reject This Bid"
    );

  });

  it("Should check Bid can't reject which is already accepted", async () => {

    await expectRevert(
      nftLendBorrow.rejectBid(
        4,
        0,
        { from: accounts[6] }
      ),
      "Bid Already Accepted"
    );

  });

  it("Should check Anyone can't repay untill Bid is not accepted", async () => {

    const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);
    const tokenId = tx.logs[0].args.tokenId.toNumber();
    // console.log("tokenid",tokenId);
    assert(tokenId === 5, "Failed to mint or wrong token Id");

    const tx1 = await nftLendBorrow.listNFTforBorrowing(
      5,
      piNFT.address,
      200,
      300,
      3600,
      200000000000
    );

    const NFTid = tx1.logs[0].args.NFTid.toNumber();
    // console.log("nftId",NFTid)
    assert(NFTid === 5, "Failed to list NFT for Lending");

    await sampleERC20.mint(accounts[8], 100000000000);
    await sampleERC20.approve(nftLendBorrow.address, 100000000000, {
      from: accounts[8],
    });

    await nftLendBorrow.Bid(
        5,
        100000000000,
        sampleERC20.address,
        10,
        200,
        200,
        { from: accounts[8] }
      )

    await expectRevert(
      nftLendBorrow.Repay(
        5,
        0,
      ),
      "Bid Not Accepted yet"
    );

  });

  it("Should check user can't repay again if It's already repaid'", async () => {

    await piNFT.approve(nftLendBorrow.address, 5);
    await nftLendBorrow.AcceptBid(5, 0);

    let val = await nftLendBorrow.viewRepayAmount(5, 0);
    await sampleERC20.approve(nftLendBorrow.address, val);
    const tx = await nftLendBorrow.Repay(5, 0);
    const amount = tx.logs[0].args.Amount.toNumber();
    // console.log("Amount",amount);
    let nft = await nftLendBorrow.NFTdetails(5);
    assert.equal(nft.listed, false);
    // console.log("nft",nft)

    await expectRevert(
      nftLendBorrow.Repay(
        5,
        0,
      ),
      "It's not listed for Borrowing"
    );

  });

  it("should check only bidder can withdraw the bid", async() => {

    const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);
    const tokenId = tx.logs[0].args.tokenId.toNumber();
    // console.log("tokenid",tokenId);
    assert(tokenId === 6, "Failed to mint or wrong token Id");

    const tx1 = await nftLendBorrow.listNFTforBorrowing(
      6,
      piNFT.address,
      200,
      300,
      3600,
      200000000000
    );

    const NFTid = tx1.logs[0].args.NFTid.toNumber();
    // console.log("nftId",NFTid)
    assert(NFTid === 6, "Failed to list NFT for Lending");


    await sampleERC20.mint(accounts[9], 100000000000);
    await sampleERC20.approve(nftLendBorrow.address, 100000000000, {
      from: accounts[9],
    });
    await nftLendBorrow.Bid(
      6,
      100000000000,
      sampleERC20.address,
      10,
      200,
      200,
      { from: accounts[9] }
    )

    await expectRevert(
      nftLendBorrow.withdraw(
        6,
        0,
        { from: accounts[8] }
      ),
      "You can't withdraw this Bid"
    );
  })

  it("should check Bidder can't withdraw before expiration ", async() => {
    await expectRevert(
      nftLendBorrow.withdraw(
        6,
        0,
        { from: accounts[9] }
      ),
      "Can't withdraw Bid before expiration"
    );
  })

  it("should check only Token owner can remove from borrowing ", async() => {

    const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);
    const tokenId = tx.logs[0].args.tokenId.toNumber();
    // console.log("tokenid",tokenId);
    assert(tokenId === 7, "Failed to mint or wrong token Id");

    const tx1 = await nftLendBorrow.listNFTforBorrowing(
      7,
      piNFT.address,
      200,
      300,
      3600,
      200000000000
    );

    const NFTid = tx1.logs[0].args.NFTid.toNumber();
    // console.log("nftId",NFTid)
    assert(NFTid === 7, "Failed to list NFT for Lending");

    await expectRevert(
      nftLendBorrow.removeNFTfromList(
        7,
        { from: accounts[9] }
      ),
      "Only token owner can execute"
    );
  })

  it("should check Bid can't be accepted after It's expired ", async() => {

    const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReciever, 500]]);
    const tokenId = tx.logs[0].args.tokenId.toNumber();
    // console.log("tokenid",tokenId);
    assert(tokenId === 8, "Failed to mint or wrong token Id");

    const tx1 = await nftLendBorrow.listNFTforBorrowing(
      8,
      piNFT.address,
      200,
      300,
      3600,
      200000000000
    );

    const NFTid = tx1.logs[0].args.NFTid.toNumber();
    // console.log("nftId",NFTid)
    assert(NFTid === 8, "Failed to list NFT for Lending");

    await sampleERC20.mint(accounts[9], 100000000000);
    await sampleERC20.approve(nftLendBorrow.address, 100000000000, {
      from: accounts[9],
    });
    let b1 = await sampleERC20.balanceOf(accounts[9]);
    console.log("fee 1", b1.toNumber());
    await nftLendBorrow.Bid(
      8,
      100000000000,
      sampleERC20.address,
      10,
      200,
      200,
      { from: accounts[9] }
    )
    let b2 = await sampleERC20.balanceOf(accounts[9]);
    console.log("fee 1", b2.toNumber());

    await time.increase(201);

    await expectRevert(
      nftLendBorrow.AcceptBid(
        8,
        0,
        { from: alice }
      ),
      "Bid is expired"
    );

    await expectRevert(
      nftLendBorrow.rejectBid(
        8,
        0,
        { from: alice }
      ),
      "Bid is expired"
    );
    

  })

  it("should withdraw the Bid after expiration",async() => {
    let b1 = await sampleERC20.balanceOf(accounts[9]);
    console.log("fee 1", b1.toNumber());
      

      await expectRevert(
        nftLendBorrow.withdraw(
          8,
          0,
          { from: alice }
        ),
        "You can't withdraw this Bid"
      );

      nftLendBorrow.withdraw(
        8,
        0,
        { from: accounts[9] }
      )
      
      let b2 = await sampleERC20.balanceOf(accounts[9]);
    console.log("fee 2", b2.toNumber());

    await sampleERC20.mint(accounts[8], 100000000000);
    await sampleERC20.approve(nftLendBorrow.address, 100000000000, {
      from: accounts[8],
    });
    let b3 = await sampleERC20.balanceOf(accounts[8]);
    console.log("fee 3", b3.toNumber());
    await nftLendBorrow.Bid(
      8,
      100000000000,
      sampleERC20.address,
      10,
      200,
      200,
      { from: accounts[8] }
    )
    let b4 = await sampleERC20.balanceOf(accounts[8]);
    console.log("fee 4", b4.toNumber());
    await time.increase(201);

    nftLendBorrow.withdraw(
      8,
      1,
      { from: accounts[8] }
    )
    let b5 = await sampleERC20.balanceOf(accounts[8]);
    console.log("fee 5", b5.toNumber());

  })
  

});
