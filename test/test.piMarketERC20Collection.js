const BigNumber = require("big-number");
const CollectionFactory = artifacts.require("CollectionFactory")
const CollectionMethods = artifacts.require("CollectionMethods")
const SampleERC20 = artifacts.require("mintToken");
const PiMarket = artifacts.require("piMarket");
const { BN, constants, expectEvent, shouldFail, time, expectRevert } = require('@openzeppelin/test-helpers');
// require("dotenv").config();

contract("PiMarket", async (accounts) => {
    let factory, collectionContract, sampleERC20, piMarket;
    let alice = accounts[0];
    let validator = accounts[1];
    let bob = accounts[2];
    let carl = accounts[3];
    let royaltyReceiver = accounts[3];
    let feeReceiver = '0xFF708C09221d5BA90eA3e3A3C42E2aBc8cA8aAc9';
    let bidder1 = accounts[5];
    let bidder2 = accounts[6];

    describe("Direct Sale", () => {
        it("should create a piNFT with 500 erc20 tokens to carl", async () => {
            factory = await CollectionFactory.deployed();
            sampleERC20 = await SampleERC20.deployed();
            await sampleERC20.mint(validator, 1000);
            await factory.createCollection("PANDORA", "PAN", "xyz", "xyz", [[royaltyReceiver, 500]])
            let meta = await factory.collections(1);
            let address = meta.contractAddress
            collectionContract = await CollectionMethods.at(address)
            const tx1 = await collectionContract.mintNFT(carl, "URI1");
            const tokenId = tx1.logs[0].args.tokenId.toNumber();
            assert(tokenId === 0, "Failed to mint or wrong token Id");

            await collectionContract.addValidator(tokenId, validator, { from: carl });
            await sampleERC20.approve(collectionContract.address, 500, { from: validator });
            const tx = await collectionContract.addERC20(
                tokenId,
                sampleERC20.address,
                500,
                [[validator, 200]],
                {
                    from: validator,
                }
            );

            const tokenBal = await collectionContract.viewBalance(tokenId, sampleERC20.address);
            assert(tokenBal == 500, "Failed to add ERC20 tokens into NFT");
        });

        it("should deploy the marketplace contract", async () => {
            piMarket = await PiMarket.deployed();
            assert(piMarket !== undefined, "PiMarket contract was not deployed");
        });

        it("should let carl transfer piNFT to alice", async () => {
            await collectionContract.safeTransferFrom(carl, alice, 0, { from: carl });
            assert.equal(await collectionContract.ownerOf(0), alice, "Failed to transfer piNFT");
        });

        it("should let alice place piNFT on sale", async () => {
            await collectionContract.approve(piMarket.address, 0);
            const result = await piMarket.sellNFT(collectionContract.address, 0, 50000, sampleERC20.address);
            assert.equal(
                await collectionContract.ownerOf(0),
                piMarket.address,
                "Failed to put piNFT on Sale"
            );
        });

        it("should edit the price after listing on sale", async () => {
            const tx = await piMarket.editSalePrice(1, 60000, { from: alice });
            await expectRevert(piMarket.editSalePrice(1, 60000, { from: bob }), "You are not the owner");
            let price = tx.logs[0].args.Price.toNumber()
            console.log("newPrice", price);
            assert.equal(
                price,
                60000,
                "Price not updated"
            );
            const tx1 = await piMarket.editSalePrice(1, 50000, { from: alice });
            let newPrice = tx1.logs[0].args.Price.toNumber()
            assert.equal(
                newPrice,
                50000,
                "Price is still 6000"
            );
        })

        it("should let bob buy piNFT", async () => {
            let meta = await piMarket._tokenMeta(1);
            assert.equal(meta.status, true);
            await sampleERC20.mint(bob, 50000);

            let _balance1 = await sampleERC20.balanceOf(alice);
            let _balance2 = await sampleERC20.balanceOf(royaltyReceiver);
            let _balance3 = await sampleERC20.balanceOf(feeReceiver);
            let _balance4 = await sampleERC20.balanceOf(validator);
            // console.log("Balance",_balance4.toString(), _balance1.toString())
            await sampleERC20.approve(piMarket.address, 50000, { from: bob });
            result2 = await piMarket.BuyNFT(1, true, { from: bob });
            // console.log(result2.receipt.rawLogs)
            assert.equal(await collectionContract.ownerOf(0), bob);

            /*validator 200
            royalties 500
            fee 100
            total = 800

            mean alic should get 10000 - 800 = 9200 = 92%

            */


            let balance1 = await sampleERC20.balanceOf(alice);
            let balance2 = await sampleERC20.balanceOf(royaltyReceiver);
            let balance3 = await sampleERC20.balanceOf(feeReceiver);
            let balance4 = await sampleERC20.balanceOf(validator);
            // let temp = (BigNumber(balance1).minus(BigNumber(_balance1)))
            // console.log("NewBalance",balance1.toString(), " ", _balance1.toString())
            assert.equal(
                (balance1 - _balance1),
                (50000 * 9200) / 10000,
                "Failed to transfer NFT amount"
            );

            assert.equal(
                balance2 - _balance2,
                (50000 * 500) / 10000,
                "Failed to transfer royalty amount"
            );

            // console.log(Number(web3.utils.toBN(balance2)-(web3.utils.toBN(_balance2))))

            // console.log(Number(BigNumber(balance3).minus(BigNumber(_balance3))));
            assert.equal(
                balance3 - _balance3,
                (50000 * 100) / 10000,
                "Failed to transfer fee amount"
            );

            assert.equal(
                balance4 - _balance4,
                (50000 * 200) / 10000,
                "Failed to transfer validator amount"
            );

            meta = await piMarket._tokenMeta(1);
            assert.equal(meta.status, false);
        });

        it("should let bob withdraw funds from the NFT", async () => {
            await collectionContract.withdraw(0, sampleERC20.address, 200, { from: bob });
            let balance = await sampleERC20.balanceOf(bob)
            assert.equal(balance.toNumber(), 200);
            assert.equal(await collectionContract.ownerOf(0), collectionContract.address);
        })

        it("should let bob withdraw more funds from the NFT", async () => {
            await collectionContract.withdraw(0, sampleERC20.address, 100, { from: bob });
            let balance = await sampleERC20.balanceOf(bob)
            assert.equal(balance.toNumber(), 300);
            assert.equal(await collectionContract.ownerOf(0), collectionContract.address);
        })

        it("should let bob repay funds to the NFT", async () => {
            await sampleERC20.approve(collectionContract.address, 300, { from: bob });
            await collectionContract.Repay(0, sampleERC20.address, 300, { from: bob });
            assert.equal(await sampleERC20.balanceOf(bob), 0);
            assert.equal(await collectionContract.ownerOf(0), bob);
        })

        it("should let bob place piNFT on sale again", async () => {
            await collectionContract.approve(piMarket.address, 0, { from: bob });
            const result = await piMarket.sellNFT(collectionContract.address, 0, 10000, sampleERC20.address, {
                from: bob,
            });
            assert.equal(
                await collectionContract.ownerOf(0),
                piMarket.address,
                "Failed to put piNFT on Sale"
            );
        });

        it("should let bob cancel sale", async () => {
            await piMarket.cancelSale(2, { from: bob });
            meta = await piMarket._tokenMeta(2);
            assert.equal(meta.status, false);
        });

        it("should let bob redeem piNFT", async () => {
            await collectionContract.redeemOrBurnPiNFT(0, alice, '0x0000000000000000000000000000000000000000', sampleERC20.address, false, {
                from: bob,
            });
            const validatorBal = await sampleERC20.balanceOf(validator);
            assert.equal(
                await collectionContract.viewBalance(0, sampleERC20.address),
                0,
                "Failed to remove ERC20 tokens from NFT"
            );
            //100 sale royalty
            assert.equal(
                await sampleERC20.balanceOf(validator),
                2000,
                "Failed to transfer ERC20 tokens to validator"
            );
            assert.equal(
                await collectionContract.ownerOf(0),
                alice,
                "Failed to transfer NFT to alice"
            );
        });
    });

    describe("Auction sale", () => {
        it("should create a piNFT with 500 erc20 tokens to alice", async () => {
            sampleERC20 = await SampleERC20.deployed();
            piMarket = await PiMarket.deployed();
            await sampleERC20.mint(validator, 1000);
            const tx1 = await collectionContract.mintNFT(alice, "URI2");
            const tokenId = tx1.logs[0].args.tokenId.toNumber();
            assert(tokenId === 1, "Failed to mint or wrong token Id");

            await collectionContract.addValidator(tokenId, validator);
            await sampleERC20.approve(collectionContract.address, 500, { from: validator });
            const tx = await collectionContract.addERC20(
                tokenId,
                sampleERC20.address,
                500,
                [[validator, 200]],
                {
                    from: validator,
                }
            );
        });

        it("should let alice place piNFT on auction", async () => {
            await collectionContract.approve(piMarket.address, 1);
            const tx = await piMarket.SellNFT_byBid(collectionContract.address, 1, 50000, 300, sampleERC20.address);
            assert.equal(
                await collectionContract.ownerOf(1),
                piMarket.address,
                "Failed to put piNFT on Auction"
            );
            const result = await piMarket._tokenMeta(3);
            assert.equal(result.bidSale, true);
        });

        it("should let bidders place bid on piNFT", async () => {
            await sampleERC20.mint(bidder1, 130000);
            await sampleERC20.mint(bidder2, 65000);

            await sampleERC20.approve(piMarket.address, 60000, { from: bidder1 })
            await piMarket.Bid(3, 60000, { from: bidder1, value: 60000 });
            await sampleERC20.approve(piMarket.address, 65000, { from: bidder2 })
            await piMarket.Bid(3, 65000, { from: bidder2, value: 65000 });
            await sampleERC20.approve(piMarket.address, 70000, { from: bidder1 })
            await piMarket.Bid(3, 70000, { from: bidder1, value: 70000 });

            result = await piMarket.Bids(3, 2);
            assert.equal(result.buyerAddress, bidder1);
        });

        it("should let alice execute highest bid", async () => {
            let _balance1 = await sampleERC20.balanceOf(alice);
            let _balance2 = await sampleERC20.balanceOf(royaltyReceiver);
            let _balance3 = await sampleERC20.balanceOf(feeReceiver);
            let _balance4 = await sampleERC20.balanceOf(validator);

            console.log("ss1", _balance1.toString())

            await piMarket.executeBidOrder(3, 2, true, { from: alice });
            result = await collectionContract.ownerOf(1);
            assert.equal(result, bidder1);

            let balance1 = await sampleERC20.balanceOf(alice);
            let balance2 = await sampleERC20.balanceOf(royaltyReceiver);
            let balance3 = await sampleERC20.balanceOf(feeReceiver);
            let balance4 = await sampleERC20.balanceOf(validator);
            // let tt = BigNumber(_balance1).minus(BigNumber(balance1));
            // console.log("Alic Balance",balance1-_balance1);
            // console.log(BigNumber(balance2).minus(BigNumber(_balance2)));
            // console.log(BigNumber(balance3).minus(BigNumber(_balance3)));

            assert.equal(
                balance1 - _balance1,
                (70000 * 9200) / 10000,
                "Failed to transfer NFT amount"
            );
            console.log("Get Token", (70000 * 9200) / 10000);
            assert.equal(
                balance2 - _balance2,
                (70000 * 500) / 10000,
                "Failed to transfer royalty amount"
            );
            assert.equal(
                balance3 - _balance3,
                (70000 * 100) / 10000,
                "Failed to transfer fee amount"
            );
            assert.equal(
                balance4 - _balance4,
                (70000 * 200) / 10000,
                "Failed to transfer validator amount"
            );
        });

        it("should let other bidders withdraw their bids", async () => {
            result = await sampleERC20.balanceOf(piMarket.address);
            assert.equal(result, 125000);
            await piMarket.withdrawBidMoney(3, 0, { from: bidder1 });
            await piMarket.withdrawBidMoney(3, 1, { from: bidder2 });
            result = await sampleERC20.balanceOf(piMarket.address);
            assert.equal(result, 0);
        });

        it("should let bidder disintegrate NFT and ERC20 tokens", async () => {
            await collectionContract.redeemOrBurnPiNFT(1, bob, '0x0000000000000000000000000000000000000000', sampleERC20.address, false, {
                from: bidder1,
            });
            const validatorBal = await sampleERC20.balanceOf(validator);
            assert.equal(
                await collectionContract.viewBalance(1, sampleERC20.address),
                0,
                "Failed to remove ERC20 tokens from NFT"
            );
            //140 bid royalty
            assert.equal(
                await sampleERC20.balanceOf(validator),
                4400,
                "Failed to transfer ERC20 tokens to validator"
            );
            assert.equal(
                await collectionContract.ownerOf(1),
                bob,
                "Failed to transfer NFT to bob"
            );
        });
    });
})