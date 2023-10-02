const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
  const { ethers } = require("hardhat");
  const moment = require("moment");
  const { BN } = require("@openzeppelin/test-helpers");
  
  describe("NFT Lending and Borrowing", function (){
    let res, poolId1, pool1Address, expiration, poolId, bidId, bidId1, loanId1;

    async function deployContractFactory() {
      [alice, validator, bob, royaltyReceiver, carl, random, newFeeAddress] = await ethers.getSigners();

      aconomyFee = await hre.ethers.deployContract("AconomyFee", []);
      await aconomyFee.waitForDeployment();

      await aconomyFee.setAconomyPoolFee(50)
      await aconomyFee.setAconomyPiMarketFee(50)
      await aconomyFee.setAconomyNFTLendBorrowFee(50)

      const LibShare = await hre.ethers.deployContract("LibShare", []);
      await LibShare.waitForDeployment();

      const piNFTMethods = await hre.ethers.getContractFactory("piNFTMethods", {
          libraries: {
          LibShare: await LibShare.getAddress()
          }
      })
      const piNftMethods = await upgrades.deployProxy(piNFTMethods, ["0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"], {
          initializer: "initialize",
          kind: "uups",
          unsafeAllow: ["external-library-linking"],
      })

      const LibCalculations = await hre.ethers.deployContract("LibCalculations", []);
      await LibCalculations.waitForDeployment();

      const LibNFTLendingBorrowing = await hre.ethers.deployContract("LibNFTLendingBorrowing", []);
      await LibNFTLendingBorrowing.waitForDeployment();

      const NFTlendingBorrowing = await hre.ethers.getContractFactory("NFTlendingBorrowing", {
        libraries: {
          LibCalculations: await LibCalculations.getAddress(),
          LibNFTLendingBorrowing: await LibNFTLendingBorrowing.getAddress()
        }
      })
      nftLendBorrow = await upgrades.deployProxy(NFTlendingBorrowing, [await aconomyFee.getAddress()], {
        initializer: "initialize",
        kind: "uups",
        unsafeAllow: ["external-library-linking"],
      })
  
      const mintToken = await hre.ethers.deployContract("mintToken", ["100000000000"]);
      sampleERC20 = await mintToken.waitForDeployment();

      const pi = await hre.ethers.getContractFactory("piNFT")
      piNFT = await upgrades.deployProxy(pi, ["Aconomy", "ACO", await piNftMethods.getAddress(), "0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"], {
          initializer: "initialize",
          kind: "uups"
      })
  
      return { piNFT, sampleERC20, nftLendBorrow, aconomyFee, alice, validator, bob, royaltyReceiver, carl, random, newFeeAddress };
    }
  
    describe("Deployment", function () {

        it("should deploy the NFTlendingBorrowing Contract", async () => {
            let {piNFT, sampleERC20, nftLendBorrow, aconomyFee, alice, validator, bob, royaltyReceiver, carl, random, newFeeAddress} = await deployContractFactory()
            expect(
              nftLendBorrow * sampleERC20 * nftLendBorrow).to.not.equal(undefined ||
                "" ||
                null ||
                NaN
            );
        });

        it("should not let non owner set aconomy fees", async () => {
          await expect(aconomyFee.connect(royaltyReceiver).setAconomyNFTLendBorrowFee(100)
          ).to.be.revertedWith("Ownable: caller is not the owner")

          await expect(aconomyFee.connect(royaltyReceiver).setAconomyPoolFee(100)
          ).to.be.revertedWith("Ownable: caller is not the owner")

          await expect(aconomyFee.connect(royaltyReceiver).setAconomyPiMarketFee(100)
          ).to.be.revertedWith("Ownable: caller is not the owner")

          await aconomyFee.setAconomyNFTLendBorrowFee(100)
          await aconomyFee.setAconomyPoolFee(100)
          await aconomyFee.setAconomyPiMarketFee(100)
        })

        it("mint NFT and list for lending", async () => {
            const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReceiver, 500]]);
            await aconomyFee.setAconomyNFTLendBorrowFee(100);
            const feee = await aconomyFee.AconomyNFTLendBorrowFee();
            // console.log("protocolFee", feee.toString());
            const tokenId = 0
            expect(tokenId).to.equal(0);
            expect(await piNFT.balanceOf(alice)).to.equal(1);
        
            await expect(nftLendBorrow.listNFTforBorrowing(
              tokenId,
              await piNFT.getAddress(),
              200,
              300,
              3600,
              1000000
            )).to.be.revertedWithoutReason()
        
            const tx1 = await nftLendBorrow.listNFTforBorrowing(
              tokenId,
              await piNFT.getAddress(),
              200,
              300,
              3600,
              200000000000
            );
            const NFTid = 1;
            expect(NFTid).to.equal(1);
          });
        
          it("should check contract address isn't 0 address", async() => {
            await expect(
              nftLendBorrow.listNFTforBorrowing(
                0,
                "0x0000000000000000000000000000000000000000",
                200,
                300,
                3600,
                200000000000
              )).to.be.revertedWithoutReason();
          })
        
          it("should check percent must be greater than 0.1%", async() => {
            await expect(
              nftLendBorrow.listNFTforBorrowing(
                0,
                await piNFT.getAddress(),
                9,
                300,
                3600,
                200000000000
              )).to.be.revertedWithoutReason();
          })
        
          it("should check expected amount must be greater than 1^6", async() => {
            await expect(
              nftLendBorrow.listNFTforBorrowing(
                0,
                await piNFT.getAddress(),
                200,
                300,
                3600,
                100000
              )).to.be.revertedWithoutReason();
          })
        
          it("should not put on borrow if the contract is paused", async () => {
            const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReceiver, 500]]);
            const tokenId = 1;
            await nftLendBorrow.pause();
            await expect(
              nftLendBorrow.connect(alice).listNFTforBorrowing(
                tokenId,
                await piNFT.getAddress(),
                200,
                300,
                3600,
                200000000000,
                { from: alice }
              )).to.be.revertedWith('Pausable: paused'
            );
            await nftLendBorrow.unpause();
          });
        
          it("let alice Set new percent fee", async () => {
            const tx = await nftLendBorrow.setPercent(1, 1000);
            await expect(
              nftLendBorrow.connect(bob).setPercent(1, 1000)).to.be.revertedWith("Not the owner"
            );
            let details = await nftLendBorrow.NFTdetails(1);
            const Percent = details[6];
            expect(Percent == 1000, "Percent should be 1000");
          });
        
          it("let alice Set new Duration Time", async () => {
            const tx = await nftLendBorrow.setDurationTime(1, 200);
            await expect(
              nftLendBorrow.connect(bob).setDurationTime(1, 200)).to.be.revertedWith("Not the owner"
            );
            let details = await nftLendBorrow.NFTdetails(1);
            const Duration = details[3];
            expect(Duration == 200, "Duration should be 200");
          });
        
          it("let alice Set new Expected Amount", async () => {
            const tx = await nftLendBorrow.setExpectedAmount(1, 100000000000);
        
            await expect(
              nftLendBorrow.setExpectedAmount(1, 1000000)).to.be.revertedWithoutReason()
        
            await expect(
              nftLendBorrow.connect(bob).setExpectedAmount(1, 100000000000)).to.be.revertedWith("Not the owner"
            );
            let details = await nftLendBorrow.NFTdetails(1);
            const expectedAmount = details[5];
            expect(expectedAmount == 100000000000, "Amount should be 1000");
          });
        
          it("Bid for NFT", async () => {
            await sampleERC20.mint(bob, 100000000000);
            await sampleERC20.connect(bob).approve(await nftLendBorrow.getAddress(), 100000000000);
        
            await expect(nftLendBorrow.connect(bob).Bid(
              1,
              1000000,
              await sampleERC20.getAddress(),
              10,
              200,
              200
            )).to.be.revertedWith("bid amount too low")
        
            const tx = await nftLendBorrow.connect(bob).Bid(
              1,
              100000000000,
              await sampleERC20.getAddress(),
              10,
              200,
              200
            );
            const BidId = 0;
            expect(BidId).to.equal(0);
        
            await sampleERC20.mint(carl, 100000000000);
            await sampleERC20.connect(carl).approve(await nftLendBorrow.getAddress(), 100000000000);
            const tx2 = await nftLendBorrow.connect(carl).Bid(
              1,
              100000000000,
              await sampleERC20.getAddress(),
              10,
              200,
              200
            );
        
            const BidId2 = 1;
            expect(BidId2).to.equal(1);
        
            await sampleERC20.mint(carl, 100000000000);
            await sampleERC20.connect(carl).approve(await nftLendBorrow.getAddress(), 100000000000);
            const tx3 = await nftLendBorrow.connect(carl).Bid(
              1,
              100000000000,
              await sampleERC20.getAddress(),
              10,
              200,
              200,
            );
        
            const BidId3 = 2;
            expect(BidId3).to.equal(2)
          });
        
          it("should check while Bid ERC20 address is not 0", async() => {
            await sampleERC20.mint(random, 100000000000);
            await sampleERC20.connect(random).approve(await nftLendBorrow.getAddress(), 100000000000);
            await expect(
              nftLendBorrow.connect(random).Bid(
                1,
                100000000000,
                "0x0000000000000000000000000000000000000000",
                10,
                200,
                200
              )).to.be.revertedWithoutReason();
          })
        
          it("should check Bid amount must be greater than 10^6", async() => {
            await sampleERC20.mint(random, 100000000000);
            await sampleERC20.connect(random).approve(await nftLendBorrow.getAddress(), 100000000000);
            await expect(
              nftLendBorrow.connect(random).Bid(
                1,
                10000,
                await sampleERC20.getAddress(),
                10,
                200,
                200
              )).to.be.revertedWith("bid amount too low"
            );
          })
        
          it("should check percent must be greater than 0.1%", async() => {
            await sampleERC20.mint(random, 100000000000);
            await sampleERC20.connect(random).approve(await nftLendBorrow.getAddress(), 100000000000);
            await expect(
              nftLendBorrow.connect(random).Bid(
                1,
                100000000000,
                await sampleERC20.getAddress(),
                9,
                200,
                200
              )).to.be.revertedWith("interest percent too low"
            );
          })
        
          it("Should Accept Bid", async () => {
            await aconomyFee.transferOwnership(newFeeAddress);
            let feeAddress = await aconomyFee.getAconomyOwnerAddress();
            await aconomyFee.connect(newFeeAddress).setAconomyNFTLendBorrowFee(200);
            expect(feeAddress).to.equal(await newFeeAddress.getAddress());
            const feee = await aconomyFee.AconomyNFTLendBorrowFee();
            // console.log("protocolFee", feee.toString());
        
            let b1 = await sampleERC20.balanceOf(feeAddress);
            // console.log("fee 1", b1.toNumber());
        
            await piNFT.approve(await nftLendBorrow.getAddress(), 0);
        
            const tx = await nftLendBorrow.AcceptBid(1, 0);
            let b2 = await sampleERC20.balanceOf(feeAddress);
            // console.log("fee 2", b2.toNumber());
            expect(b2 - b1).to.equal(1000000000);
            let nft = await nftLendBorrow.NFTdetails(1);
            let bid = await nftLendBorrow.Bids(1, 0);
            expect(nft.bidAccepted).to.equal(true);
            expect(nft.listed).to.equal(true);
            expect(nft.repaid).to.equal(false);
            expect(bid.bidAccepted).to.equal(true);
            expect(bid.withdrawn).to.equal(false);
          });
        
          it("should check anyone can't Bid on already Accepted bid", async() => {
            await sampleERC20.mint(random, 100000000000);
            await sampleERC20.connect(random).approve(await nftLendBorrow.getAddress(), 100000000000);
            await expect(
              nftLendBorrow.connect(random).Bid(
                1,
                100000000000,
                await sampleERC20.getAddress(),
                10,
                200,
                200
              )).to.be.revertedWith(
              "Bid Already Accepted"
            );
          })
        
        
          it("Should Reject Third Bid by NFT Owner", async () => {
            const newBalance1 = await sampleERC20.balanceOf(carl);
            // console.log("dd", newBalance1.toString());
            expect(newBalance1).to.equal(0);
        
            const tx = await nftLendBorrow.rejectBid(1, 2);
            let Bid = await nftLendBorrow.Bids(1, 2);
            expect(Bid.withdrawn).to.equal(true);
            const newBalance = await sampleERC20.balanceOf(carl);
            // console.log("dd", newBalance.toString());
            expect(
              newBalance).to.equal(
              100000000000);
          });
        
          it("Withdraw Third Bid", async () => {
            await expect(
              nftLendBorrow.connect(carl).withdraw(1, 2)).to.be.revertedWith(
              "Already withdrawn"
            );
          });
        
          it("Should Repay Bid", async () => {
            let val = await nftLendBorrow.viewRepayAmount(1, 0);
            await sampleERC20.approve(await nftLendBorrow.getAddress(), val);
            const tx = await nftLendBorrow.Repay(1, 0);
            let nft = await nftLendBorrow.NFTdetails(1);
            expect(nft[7]).to.equal(false);
          });
        
          it("Should Withdraw second Bid", async () => {
            const res = await nftLendBorrow.connect(carl).withdraw(1, 1);
            let bid = await nftLendBorrow.Bids(1, 1);
            expect(bid[10]).to.equal(false);
            expect(bid[9]).to.equal(true);
          });
        
          it("Should remove the NFT from listing", async () => {
            const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReceiver, 500]]);
            const tokenId = 2;
            expect(tokenId).to.equal(2)
            expect(await piNFT.balanceOf(alice)).to.equal(3)
        
            const tx1 = await nftLendBorrow.listNFTforBorrowing(
              tokenId,
              await piNFT.getAddress(),
              200,
              200,
              3600,
              100000000000
            );
            const tx2 = await nftLendBorrow.removeNFTfromList(2);
            let t = await nftLendBorrow.NFTdetails(2);
            expect(t[7]).to.equal(false);
          });
        
          it("should fail to Bid after expiration", async () => {
            const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReceiver, 500]]);
            const tokenId = 3;
            expect(tokenId).to.equal(3);
            // expect(await piNFT.balanceOf(alice), 3, "Failed to mint");
        
            const tx1 = await nftLendBorrow.listNFTforBorrowing(
              tokenId,
              await piNFT.getAddress(),
              200,
              200,
              3600,
              100000000000
            );
            const NFTid = await nftLendBorrow.NFTid()
        
            await sampleERC20.mint(carl, 100000000000);
            await sampleERC20.connect(carl).approve(await nftLendBorrow.getAddress(), 100000000000);
            
            const tx2 = await nftLendBorrow.connect(carl).Bid(
              NFTid,
              100000000000,
              await sampleERC20.getAddress(),
              10,
              200,
              200
            );
        
            await time.increase(3601);
        
            await expect(
              nftLendBorrow.connect(carl).Bid(
                NFTid,
                100000000000,
                await sampleERC20.getAddress(),
                10,
                200,
                200
              )).to.be.revertedWith(
              "Bid time over"
            );
          })
        
        
          it("should mint the NFT and list for Borrowing", async() => {
            const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReceiver, 500]]);
            const tokenId = 4;
            // console.log("tokenid",tokenId);
            expect(tokenId).to.equal(4);
        
            const tx1 = await nftLendBorrow.listNFTforBorrowing(
              4,
              await piNFT.getAddress(),
              200,
              300,
              3600,
              200000000000
            );
        
            const NFTid = await nftLendBorrow.NFTid()
            // console.log("nftId",NFTid)
            expect(NFTid).to.equal(4);
          })
        
          it("should check someone can only bid on listed NFT", async() => {
               await sampleERC20.mint(random, 100000000000);
              await sampleERC20.connect(random).approve(await nftLendBorrow.getAddress(), 100000000000);
        
                await expect(
                  nftLendBorrow.connect(random).Bid(
                    2,
                    100000000000,
                    await sampleERC20.getAddress(),
                    10,
                    200,
                    200
                  )).to.be.revertedWith(
                  "You can't Bid on this NFT"
                );
          })
        
          it("Should check that NFT owner can Accept the Bid", async () => {
        
            await sampleERC20.mint(carl, 100000000000);
            await sampleERC20.connect(carl).approve(await nftLendBorrow.getAddress(), 100000000000);
        
            await nftLendBorrow.connect(carl).Bid(
                4,
                100000000000,
                await sampleERC20.getAddress(),
                10,
                200,
                200
              )
        
            // const tx = await nftLendBorrow.AcceptBid(1, 0);
        
            await expect(
              nftLendBorrow.connect(random).AcceptBid(
                4,
                0
              )).to.be.revertedWith(
              "You can't Accept This Bid"
            );
        
          });
        
        
          it("Should check owner can't accept the bid if it's already accepted and can't remove NFT after accepting Bid ", async () => {
        
            await sampleERC20.mint(carl, 100000000000);
            await sampleERC20.connect(carl).approve(await nftLendBorrow.getAddress(), 100000000000);
        
            await nftLendBorrow.connect(carl).Bid(
                4,
                100000000000,
                await sampleERC20.getAddress(),
                10,
                200,
                200
              )
        
            await piNFT.approve(await nftLendBorrow.getAddress(), 4);
            const tx = await nftLendBorrow.AcceptBid(4, 0);
        
            await expect(
              nftLendBorrow.removeNFTfromList(
                4
              )).to.be.revertedWith(
              "Only token owner can execute"
            );
        
            await expect(
              nftLendBorrow.AcceptBid(
                4,
                0
              )).to.be.revertedWith(
              "bid already accepted"
            );
          });
        
          it("Should check owner can't accept another bid if it's already accepted a bid", async () => {
            await expect(
              nftLendBorrow.AcceptBid(
                4,
                0
              )).to.be.revertedWith(
              "bid already accepted"
            );
          });
        
          it("Should check only NFT owner can Reject the Bid", async () => {
        
            await expect(
              nftLendBorrow.connect(random).rejectBid(
                4,
                1
              )).to.be.revertedWith(
              "You can't Reject This Bid"
            );
        
          });
        
          it("Should check Bid can't reject which is already accepted", async () => {
        
            await expect(
              nftLendBorrow.connect(random).rejectBid(
                4,
                0,
                { from: random }
              )).to.be.revertedWith(
              "Bid Already Accepted"
            );
        
          });
        
          it("Should check Anyone can't repay untill Bid is accepted", async () => {
        
            const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReceiver, 500]]);
            const tokenId = 5;
            // console.log("tokenid",tokenId);
            expect(tokenId).to.equal(5);
        
            const tx1 = await nftLendBorrow.listNFTforBorrowing(
              5,
              await piNFT.getAddress(),
              200,
              300,
              3600,
              200000000000
            );
        
            const NFTid = await nftLendBorrow.NFTid()
            // console.log("nftId",NFTid)
            expect(NFTid).to.equal(5);
        
            await sampleERC20.mint(carl, 100000000000);
            await sampleERC20.connect(carl).approve(await nftLendBorrow.getAddress(), 100000000000);
        
            await nftLendBorrow.connect(carl).Bid(
                5,
                100000000000,
                await sampleERC20.getAddress(),
                10,
                200,
                200
              )
        
            await expect(
              nftLendBorrow.Repay(
                5,
                0,
              )).to.be.revertedWith(
              "Bid Not Accepted yet"
            );
        
          });
        
          it("Should check user can't repay again if It's already repaid'", async () => {
        
            await piNFT.approve(await nftLendBorrow.getAddress(), 5);
            await nftLendBorrow.AcceptBid(5, 0);
        
            let val = await nftLendBorrow.viewRepayAmount(5, 0);
            await sampleERC20.approve(await nftLendBorrow.getAddress(), val);
            const tx = await nftLendBorrow.Repay(5, 0);
            let nft = await nftLendBorrow.NFTdetails(5);
            expect(nft[7]).to.equal(false);
            // console.log("nft",nft)
        
            await expect(
              nftLendBorrow.Repay(
                5,
                0,
              )).to.be.revertedWith(
              "It's not listed for Borrowing"
            );
        
          });
        
          it("should check only bidder can withdraw the bid", async() => {
        
            const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReceiver, 500]]);
            const tokenId = 6
            // console.log("tokenid",tokenId);
            expect(tokenId).to.equal(6)
        
            const tx1 = await nftLendBorrow.listNFTforBorrowing(
              6,
              await piNFT.getAddress(),
              200,
              300,
              3600,
              200000000000
            );
        
            const NFTid = await nftLendBorrow.NFTid()
            // console.log("nftId",NFTid)
            expect(NFTid).to.equal(6)
        
        
            await sampleERC20.mint(newFeeAddress, 100000000000);
            await sampleERC20.connect(newFeeAddress).approve(await nftLendBorrow.getAddress(), 100000000000);
            await nftLendBorrow.connect(newFeeAddress).Bid(
              6,
              100000000000,
              await sampleERC20.getAddress(),
              10,
              200,
              200
            )
        
            await expect(
              nftLendBorrow.connect(random).withdraw(
                6,
                0
              )).to.be.revertedWith(
              "You can't withdraw this Bid"
            );
          })
        
          it("should check Bidder can't withdraw before expiration ", async() => {
            await expect(
              nftLendBorrow.connect(newFeeAddress).withdraw(
                6,
                0
              )).to.be.revertedWith(
              "Can't withdraw Bid before expiration"
            );
          })
        
          it("should check only Token owner can remove from borrowing ", async() => {
        
            const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReceiver, 500]]);
            const tokenId = 7;
            // console.log("tokenid",tokenId);
            expect(tokenId).to.equal(7);
        
            const tx1 = await nftLendBorrow.listNFTforBorrowing(
              7,
              await piNFT.getAddress(),
              200,
              300,
              3600,
              200000000000
            );
        
            const NFTid = await nftLendBorrow.NFTid();
            // console.log("nftId",NFTid)
            expect(NFTid).to.equal(7);
        
            await expect(
              nftLendBorrow.connect(newFeeAddress).removeNFTfromList(
                7
              )).to.be.revertedWith(
              "Only token owner can execute"
            );
          })
        
          it("should check Bid can't be accepted after It's expired ", async() => {
        
            const tx = await piNFT.mintNFT(alice, "URI1", [[royaltyReceiver, 500]]);
            const tokenId = 8;
            // console.log("tokenid",tokenId);
            expect(tokenId).to.equal(8);
        
            const tx1 = await nftLendBorrow.listNFTforBorrowing(
              8,
              await piNFT.getAddress(),
              200,
              300,
              3600,
              200000000000
            );
        
            const NFTid = await nftLendBorrow.NFTid()
            // console.log("nftId",NFTid)
            expect(NFTid).to.equal(8);
        
            await sampleERC20.mint(newFeeAddress, 100000000000);
            await sampleERC20.connect(newFeeAddress).approve(await nftLendBorrow.getAddress(), 100000000000);
            let b1 = await sampleERC20.balanceOf(newFeeAddress);
            // console.log("fee 1", b1.toNumber());
            await nftLendBorrow.connect(newFeeAddress).Bid(
              8,
              100000000000,
              await sampleERC20.getAddress(),
              10,
              200,
              200
            )
            let b2 = await sampleERC20.balanceOf(newFeeAddress);
            // console.log("fee 1", b2.toNumber());
        
            await time.increase(201);
        
            await expect(
              nftLendBorrow.AcceptBid(
                8,
                0
              )).to.be.revertedWith(
              "Bid is expired"
            );
        
            await expect(
              nftLendBorrow.rejectBid(
                8,
                0
              )).to.be.revertedWith(
              "Bid is expired"
            );
            
        
          })
        
          it("should withdraw the Bid after expiration",async() => {
            let b1 = await sampleERC20.balanceOf(newFeeAddress);
            console.log("fee 1", b1);
              
        
              await expect(
                nftLendBorrow.withdraw(
                  8,
                  0
                )).to.be.revertedWith(
                "You can't withdraw this Bid"
              );
        
              nftLendBorrow.connect(newFeeAddress).withdraw(
                8,
                0
              )
        
            await sampleERC20.mint(random, 100000000000);
            await sampleERC20.connect(random).approve(await nftLendBorrow.getAddress(), 100000000000);

            await nftLendBorrow.connect(random).Bid(
              8,
              100000000000,
              await sampleERC20.getAddress(),
              10,
              200,
              200
            )
            
            await time.increase(201);
            expect(await sampleERC20.balanceOf(random)).to.equal(500000000000);
        
            await nftLendBorrow.connect(random).withdraw(
              8,
              1
            )
            expect(await sampleERC20.balanceOf(random)).to.equal(600000000000);
            // console.log("fee 5", b5.toNumber());
            let bid = await nftLendBorrow.Bids(8, 1);
            expect(bid[9]).to.equal(true);
        
          })
    })
  })