const {
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BN } = require("@openzeppelin/test-helpers");

const BigNumber = require("big-number");
const { assert } = require("ethers");

let collectionContract;

describe("piMarketCollection", function () {
    async function deploypiMarket() {
        [
            alice,
            validator,
            bob,
            carl,
            royaltyReceiver,
            feeReceiver,
            bidder1,
            bidder2,
            bidder3,
        ] = await ethers.getSigners();

        const aconomyfee = await hre.ethers.deployContract("AconomyFee", []);
        aconomyFee = await aconomyfee.waitForDeployment();

        await aconomyFee.setAconomyPoolFee(50);
        await aconomyFee.setAconomyPiMarketFee(50);
        await aconomyFee.setAconomyNFTLendBorrowFee(50);

        const LibShare = await hre.ethers.deployContract("LibShare", []);
        await LibShare.waitForDeployment();

        const piNFTMethods = await hre.ethers.getContractFactory("piNFTMethods", {
            libraries: {
                LibShare: await LibShare.getAddress(),
            },
        });
        piNftMethods = await upgrades.deployProxy(
            piNFTMethods,
            ["0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"],
            {
                initializer: "initialize",
                kind: "uups",
                unsafeAllow: ["external-library-linking"],
            }
        );

        const LibCollection = await hre.ethers.deployContract("LibCollection", []);
        await LibCollection.waitForDeployment();

        const CollectionFactory = await hre.ethers.getContractFactory(
            "CollectionFactory",
            {
                libraries: {
                    LibCollection: await LibCollection.getAddress(),
                },
            }
        );

        const CollectionMethods = await hre.ethers.deployContract(
            "CollectionMethods",
            []
        );
        let CollectionMethod = await CollectionMethods.waitForDeployment();

        factory = await upgrades.deployProxy(
            CollectionFactory,
            [await CollectionMethod.getAddress(), await piNftMethods.getAddress()],
            {
                initializer: "initialize",
                kind: "uups",
                unsafeAllow: ["external-library-linking"],
            }
        );

        await CollectionMethods.initialize(
            alice.getAddress(),
            await factory.getAddress(),
            "xyz",
            "xyz"
        );

        const piNfT = await hre.ethers.getContractFactory("piNFT");
        piNFT = await upgrades.deployProxy(
            piNfT,
            [
                "Aconomy",
                "ACO",
                await piNftMethods.getAddress(),
                "0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d",
            ],
            {
                initializer: "initialize",
                kind: "uups",
            }
        );

        const LibMarket = await hre.ethers.deployContract("LibMarket", []);
        await LibMarket.waitForDeployment();

        const pimarket = await hre.ethers.getContractFactory("piMarket", {
            libraries: {
                LibMarket: await LibMarket.getAddress(),
            },
        });
        piMarket = await upgrades.deployProxy(
            pimarket,
            [
                await aconomyFee.getAddress(),
                await factory.getAddress(),
                await piNftMethods.getAddress(),
            ],
            {
                initializer: "initialize",
                kind: "uups",
                unsafeAllow: ["external-library-linking"],
            }
        );

        await piNftMethods.setPiMarket(piMarket.getAddress());

        const mintToken = await hre.ethers.deployContract("mintToken", [
            "100000000000",
        ]);
        sampleERC20 = await mintToken.waitForDeployment();

        // console.log("AconomyFee : ", await aconomyFee.getAddress());
        // console.log("CollectionMethods : ", await CollectionMethod.getAddress());
        // console.log("CollectionFactory : ", await factory.getAddress());
        // console.log("mintToken : ", await sampleERC20.getAddress());
        // console.log("piNFT: ", await piNFT.getAddress());
        // console.log("piNFTMethods", await piNftMethods.getAddress());
        // console.log("piMarket:", await piMarket.getAddress());

        return {
            piNFT,
            piMarket,
            sampleERC20,
            piNftMethods,
            factory,
            aconomyFee,
            alice,
            validator,
            bob,
            carl,
            royaltyReceiver,
            feeReceiver,
            bidder1,
            bidder2,
            bidder3,
        };
    }

    describe("Direct Sale", function () {
        it("should deploy the contracts", async () => {
            let {
                piNFT,
                piMarket,
                sampleERC20,
                piNftMethods,
                factory,
                aconomyFee,
                alice,
                validator,
                bob,
                carl,
                royaltyReceiver,
                feeReceiver,
                bidder1,
                bidder2,
                bidder3,
            } = await deploypiMarket();
        });

        it("should create a private piNFT with 500 erc20 tokens to carl", async () => {
            await aconomyFee.setAconomyPiMarketFee(100);
            await aconomyFee.transferOwnership(feeReceiver.getAddress());
            await sampleERC20.mint(validator.getAddress(), 1000);
            await factory.createCollection("PANDORA", "PAN", "xyz", "xyz", [
                [royaltyReceiver, 500],
            ]);
            let meta = await factory.collections(1);
            let address = await meta.contractAddress;
            collectionContract = await hre.ethers.getContractAt(
                "CollectionMethods",
                address
            );

            await collectionContract.mintNFT(carl.getAddress(), "URI1");
            const owner = await collectionContract.ownerOf(0);
            expect(owner).to.equal(await carl.getAddress());
            const bal = await collectionContract.balanceOf(carl.getAddress());
            expect(bal).to.equal(1);

            await piNftMethods
                .connect(carl)
                .addValidator(
                    collectionContract.getAddress(),
                    0,
                    validator.getAddress()
                );
                let exp = new BN(await time.latest()).add(new BN(3600));
            await sampleERC20
                .connect(validator)
                .approve(piNftMethods.getAddress(), 500);
            await piNftMethods
                .connect(validator)
                .addERC20(
                    collectionContract.getAddress(),
                    0,
                    sampleERC20.getAddress(),
                    500,
                    1000,
                    "uri",
                    [[validator.getAddress(), 200]]
                );

            const tokenBal = await piNftMethods.viewBalance(
                collectionContract.getAddress(),
                0,
                sampleERC20.getAddress()
            );

            expect(tokenBal).to.equal(500);

            let commission = await piNftMethods.validatorCommissions(
                collectionContract.getAddress(),
                0
            );
            expect(commission.isValid).to.equal(true);
            expect(commission.commission.account).to.equal(
                await validator.getAddress()
            );
            expect(commission.commission.value).to.equal(1000);
        });

        it("should let carl transfer piNFT to alice", async () => {
            await collectionContract
                .connect(carl)
                .safeTransferFrom(carl.getAddress(), alice.getAddress(), 0);
            expect(await collectionContract.ownerOf(0)).to.equal(
                await alice.getAddress()
            );
        });

        it("should not place nft on sale if price < 10000", async () => {
            await collectionContract.approve(piMarket.getAddress(), 0);
            await expect(
                piMarket.sellNFT(
                    collectionContract.getAddress(),
                    0,
                    100,
                    "0x0000000000000000000000000000000000000000"
                )
            ).to.be.revertedWithoutReason();
        });

        it("should not place nft on sale if contract address is 0", async () => {
            await collectionContract.approve(piMarket.getAddress(), 0);
            await expect(
                piMarket.sellNFT(
                    "0x0000000000000000000000000000000000000000",
                    0,
                    50000,
                    "0x0000000000000000000000000000000000000000"
                )
            ).to.be.revertedWithoutReason();
        });

        it("should let alice place piNFT on sale", async () => {
            await collectionContract.approve(piMarket.getAddress(), 0);
            await piMarket.sellNFT(
                collectionContract.getAddress(),
                0,
                50000,
                "0x0000000000000000000000000000000000000000"
            );
            expect(await collectionContract.ownerOf(0)).to.equal(
                await piMarket.getAddress()
            );
        });

        it("should edit the price after listing on sale", async () => {
            await piMarket.connect(alice).editSalePrice(1, 60000, 500);
            await expect(
                piMarket.connect(bob).editSalePrice(1, 60000, 500)
            ).to.be.revertedWithoutReason();

            await expect(
                piMarket.connect(alice).editSalePrice(1, 60, 500)
            ).to.be.revertedWithoutReason();

            let data = await piMarket._tokenMeta(1);
            expect(await data.price).to.equal("60000");
            await piMarket.connect(alice).editSalePrice(1, 50000, 500);
            let newdata = await piMarket._tokenMeta(1);
            expect(await newdata.price).to.equal(50000);
        });

        it("should not let seller buy their own nft", async () => {
            await expect(
                piMarket.BuyNFT(1, true, { from: alice, value: 50000 })
            ).to.be.revertedWithoutReason();
        });

        it("should let bob buy piNFT", async () => {
            let meta = await piMarket._tokenMeta(1);
            expect(await meta.status).to.equal(true);
            // assert.equal(meta.status, true);

            const _balance1 = await ethers.provider.getBalance(alice.getAddress());
            const _balance2 = await ethers.provider.getBalance(
                royaltyReceiver.getAddress()
            );
            const _balance3 = await ethers.provider.getBalance(
                feeReceiver.getAddress()
            );
            const _balance4 = await ethers.provider.getBalance(
                validator.getAddress()
            );

            result2 = await piMarket.connect(bob).BuyNFT(1, true, { value: 50000 });
            expect(await collectionContract.ownerOf(0)).to.equal(
                await bob.getAddress()
            );

            const balance1 = await ethers.provider.getBalance(alice.getAddress());
            const balance2 = await ethers.provider.getBalance(
                royaltyReceiver.getAddress()
            );
            const balance3 = await ethers.provider.getBalance(
                feeReceiver.getAddress()
            );
            const balance4 = await ethers.provider.getBalance(validator.getAddress());

            let temp1 = BigNumber(balance1.toString()).minus(
                BigNumber(_balance1.toString())
            );
            let gotAmount1 = (50000 * 8200) / 10000;
            expect(temp1.toString()).to.equal(gotAmount1.toString());

            let temp2 = BigNumber(balance2.toString()).minus(
                BigNumber(_balance2.toString())
            );
            let gotAmount2 = (50000 * 500) / 10000;
            expect(temp2.toString()).to.equal(gotAmount2.toString());

            let temp3 = BigNumber(balance3.toString()).minus(
                BigNumber(_balance3.toString())
            );
            let gotAmount3 = (50000 * 100) / 10000;
            expect(temp3.toString()).to.equal(gotAmount3.toString());

            let temp4 = BigNumber(balance4.toString()).minus(
                BigNumber(_balance4.toString())
            );
            let gotAmount4 = (50000 * 1200) / 10000;
            expect(temp4.toString()).to.equal(gotAmount4.toString());

            meta = await piMarket._tokenMeta(1);
            expect(await meta.status).to.equal(false);
            // assert.equal(meta.status, false);
            let commission = await piNftMethods.validatorCommissions(
                collectionContract.getAddress(),
                0
            );
            expect(commission.isValid).to.equal(false);
            expect(commission.commission.account).to.equal(
                await validator.getAddress()
            );
            expect(commission.commission.value).to.equal(1000);
        });

        it("should let bob withdraw funds from the NFT", async () => {
            await collectionContract
                .connect(bob)
                .approve(piNftMethods.getAddress(), 0);
            await piNftMethods
                .connect(bob)
                .withdraw(
                    collectionContract.getAddress(),
                    0,
                    sampleERC20.getAddress(),
                    200
                );
            expect(await sampleERC20.balanceOf(bob)).to.equal(200);
            expect(await collectionContract.ownerOf(0)).to.equal(
                await piNftMethods.getAddress()
            );
        });

        it("should let bob withdraw more funds from the NFT", async () => {
            await piNftMethods
                .connect(bob)
                .withdraw(
                    collectionContract.getAddress(),
                    0,
                    sampleERC20.getAddress(),
                    100
                );
            expect(await sampleERC20.balanceOf(bob)).to.equal(300);
            expect(await collectionContract.ownerOf(0)).to.equal(
                await piNftMethods.getAddress()
            );
        });

        it("should let bob repay funds to the NFT", async () => {
            await sampleERC20.connect(bob).approve(piNftMethods.getAddress(), 300);
            await piNftMethods
                .connect(bob)
                .Repay(
                    collectionContract.getAddress(),
                    0,
                    sampleERC20.getAddress(),
                    300
                );

            expect(await sampleERC20.balanceOf(bob)).to.equal(0);
            expect(await collectionContract.ownerOf(0)).to.equal(
                await bob.getAddress()
            );
        });

        it("should allow validator to add erc20 and change commission and royalties", async () => {
            await sampleERC20
                .connect(validator)
                .approve(piNftMethods.getAddress(), 500);
                let exp = new BN(await time.latest()).add(new BN(7500));
                await time.increase(3601);
            await piNftMethods
                .connect(validator)
                .addERC20(
                    collectionContract.getAddress(),
                    0,
                    sampleERC20.getAddress(),
                    500,
                    100,
                    "uri",
                    [[validator.getAddress(), 300]]
                );
            let commission = await piNftMethods.validatorCommissions(
                collectionContract.getAddress(),
                0
            );
            expect(commission.isValid).to.equal(false);
            expect(commission.commission.account).to.equal(
                await validator.getAddress()
            );
            expect(commission.commission.value).to.equal(100);
        });

        it("should let bob place piNFT on sale again", async () => {
            await collectionContract.connect(bob).approve(piMarket.getAddress(), 0);
            await piMarket
                .connect(bob)
                .sellNFT(
                    collectionContract.getAddress(),
                    0,
                    50000,
                    "0x0000000000000000000000000000000000000000"
                );
            expect(await collectionContract.ownerOf(0)).to.equal(
                await piMarket.getAddress()
            );
        });

        it("should let alice buy piNFT", async () => {
            let meta = await piMarket._tokenMeta(2);
            expect(await meta.status).to.equal(true);
            const _balance1 = await ethers.provider.getBalance(bob.getAddress());
            const _balance2 = await ethers.provider.getBalance(
                royaltyReceiver.getAddress()
            );
            const _balance3 = await ethers.provider.getBalance(
                feeReceiver.getAddress()
            );
            const _balance4 = await ethers.provider.getBalance(
                validator.getAddress()
            );

            result2 = await piMarket.connect(alice).BuyNFT(2, true, { value: 50000 });
            expect(await collectionContract.ownerOf(0)).to.equal(
                await alice.getAddress()
            );

            const balance1 = await ethers.provider.getBalance(bob.getAddress());
            const balance2 = await ethers.provider.getBalance(
                royaltyReceiver.getAddress()
            );
            const balance3 = await ethers.provider.getBalance(
                feeReceiver.getAddress()
            );
            const balance4 = await ethers.provider.getBalance(validator.getAddress());

            let temp1 = BigNumber(balance1.toString()).minus(
                BigNumber(_balance1.toString())
            );
            let gotAmount1 = (50000 * 9100) / 10000;
            expect(temp1.toString()).to.equal(gotAmount1.toString());

            let temp2 = BigNumber(balance2.toString()).minus(
                BigNumber(_balance2.toString())
            );
            let gotAmount2 = (50000 * 500) / 10000;
            expect(temp2.toString()).to.equal(gotAmount2.toString());

            let temp3 = BigNumber(balance3.toString()).minus(
                BigNumber(_balance3.toString())
            );
            let gotAmount3 = (50000 * 100) / 10000;
            expect(temp3.toString()).to.equal(gotAmount3.toString());

            let temp4 = BigNumber(balance4.toString()).minus(
                BigNumber(_balance4.toString())
            );
            let gotAmount4 = (50000 * 300) / 10000;
            expect(temp4.toString()).to.equal(gotAmount4.toString());

            meta = await piMarket._tokenMeta(1);
            expect(await meta.status).to.equal(false);
            // assert.equal(meta.status, false);
            let commission = await piNftMethods.validatorCommissions(
                collectionContract.getAddress(),
                0
            );
            expect(commission.isValid).to.equal(false);
            expect(commission.commission.account).to.equal(
                await validator.getAddress()
            );
            expect(commission.commission.value).to.equal(100);

            await collectionContract
                .connect(alice)
                .safeTransferFrom(alice.getAddress(), bob.getAddress(), 0);
        });

        it("should let bob place piNFT on sale again", async () => {
            await collectionContract.connect(bob).approve(piMarket.getAddress(), 0);
            await piMarket
                .connect(bob)
                .sellNFT(
                    collectionContract.getAddress(),
                    0,
                    10000,
                    "0x0000000000000000000000000000000000000000"
                );
            expect(await collectionContract.ownerOf(0)).to.equal(
                await piMarket.getAddress()
            );
        });

        it("should not let non owner cancel sale", async () => {
            // await expectRevert.unspecified(piMarket.cancelSale(3, { from: alice }))

            await expect(
                piMarket.connect(alice).cancelSale(3)
            ).to.be.revertedWithoutReason();
        });

        it("should let bob cancel sale", async () => {
            await piMarket.connect(bob).cancelSale(3);
            meta = await piMarket._tokenMeta(3);
            expect(await meta.status).to.equal(false);
        });

        it("should let bob redeem piNFT", async () => {
            await collectionContract
                .connect(bob)
                .approve(piNftMethods.getAddress(), 0);
            await piNftMethods
                .connect(bob)
                .redeemOrBurnPiNFT(
                    collectionContract.getAddress(),
                    0,
                    alice.getAddress(),
                    "0x0000000000000000000000000000000000000000",
                    sampleERC20.getAddress(),
                    false
                );
            const validatorBal = await sampleERC20.balanceOf(validator.getAddress());
            expect(
                await piNftMethods.viewBalance(
                    collectionContract.getAddress(),
                    0,
                    sampleERC20.getAddress()
                )
            ).to.equal(0);
            expect(await sampleERC20.balanceOf(validator.getAddress())).to.equal(
                1000
            );

            expect(await collectionContract.ownerOf(0)).to.equal(
                await alice.getAddress()
            );

            let commission = await piNftMethods.validatorCommissions(
                collectionContract.getAddress(),
                0
            );
            expect(commission.isValid).to.equal(false);
            expect(commission.commission.account).to.equal(
                "0x0000000000000000000000000000000000000000"
            );
            expect(commission.commission.value).to.equal(0);
        });
    });

    describe("Auction sale", () => {
        it("should create a piNFT with 500 erc20 tokens to alice", async () => {
            await sampleERC20.mint(validator.getAddress(), 1000);
            await collectionContract.mintNFT(alice.getAddress(), "URI2");
            let tokenId = 1;
            const owner = await collectionContract.ownerOf(tokenId);
            expect(owner).to.equal(await alice.getAddress());
            const bal = await collectionContract.balanceOf(alice.getAddress());
            expect(bal).to.equal(2);

            await piNftMethods.addValidator(
                collectionContract.getAddress(),
                tokenId,
                validator.getAddress()
            );
            let exp = new BN(await time.latest()).add(new BN(3600));
            // await time.increase(7501);
            await sampleERC20
                .connect(validator)
                .approve(piNftMethods.getAddress(), 500);
            await piNftMethods
                .connect(validator)
                .addERC20(
                    collectionContract.getAddress(),
                    tokenId,
                    sampleERC20.getAddress(),
                    500,
                    1000,
                    "uri",
                    [[validator.getAddress(), 200]]
                );

            let commission = await piNftMethods.validatorCommissions(
                collectionContract.getAddress(),
                1
            );
            expect(commission.isValid).to.equal(true);
            expect(commission.commission.account).to.equal(
                await validator.getAddress()
            );
            expect(commission.commission.value).to.equal(1000);
        });

        it("should not place nft on auction if price < 10000", async () => {
            await collectionContract.approve(piMarket.getAddress(), 1);
            await expect(
                piMarket.SellNFT_byBid(
                    collectionContract.getAddress(),
                    1,
                    100,
                    300,
                    "0x0000000000000000000000000000000000000000"
                )
            ).to.be.revertedWithoutReason();
        });

        it("should not place nft on auction if contract address is 0", async () => {
            await collectionContract.approve(piMarket.getAddress(), 1);
            await expect(
                piMarket.SellNFT_byBid(
                    "0x0000000000000000000000000000000000000000",
                    1,
                    50000,
                    300,
                    "0x0000000000000000000000000000000000000000"
                )
            ).to.be.revertedWithoutReason();
        });

        it("should not place nft on auction if auction time is 0", async () => {
            await collectionContract.approve(piMarket.getAddress(), 1);
            await expect(
                piMarket.SellNFT_byBid(
                    collectionContract.getAddress(),
                    1,
                    50000,
                    0,
                    "0x0000000000000000000000000000000000000000"
                )
            ).to.be.revertedWithoutReason();
        });

        // it("should let alice place piNFT on auction", async () => {
        //     await collectionContract.approve(piMarket.getAddress(), 1);
        //     await piMarket.SellNFT_byBid(
        //         collectionContract.getAddress(),
        //         1,
        //         50000,
        //         300,
        //         "0x0000000000000000000000000000000000000000"
        //     );
        //     expect(await collectionContract.ownerOf(1)).to.equal(
        //         await piMarket.getAddress()
        //     );

        //     const result = await piMarket._tokenMeta(4);
        //     expect(result.bidSale).to.equal(true);
        // });

        // it("should let alice change the start price of the auction", async () => {
        //     await piMarket.editSalePrice(4, 10000);
        //     let result = await piMarket._tokenMeta(4);
        //     expect(result.price).to.equal(10000);
        //     await piMarket.editSalePrice(4, 50000);
        //     result = await piMarket._tokenMeta(4);
        //     expect(result.price).to.equal(50000);
        // });

        it("should allow validator to add erc20 and change commission and royalties", async () => {
            await sampleERC20
                .connect(validator)
                .approve(piNftMethods.getAddress(), 500);
                let exp = new BN(await time.latest()).add(new BN(7500));
                await time.increase(3601);
            await piNftMethods
                .connect(validator)
                .addERC20(
                    collectionContract.getAddress(),
                    1,
                    sampleERC20.getAddress(),
                    500,
                    900,
                    "uri",
                    [[validator.getAddress(), 300]]
                );
            let commission = await piNftMethods.validatorCommissions(
                collectionContract.getAddress(),
                1
            );
            expect(commission.isValid).to.equal(true);
            expect(commission.commission.account).to.equal(
                await validator.getAddress()
            );
            expect(commission.commission.value).to.equal(900);
        });

        it("should let alice place piNFT on auction", async () => {
            await collectionContract.approve(piMarket.getAddress(), 1);
            await piMarket.SellNFT_byBid(
                collectionContract.getAddress(),
                1,
                50000,
                300,
                "0x0000000000000000000000000000000000000000"
            );
            expect(await collectionContract.ownerOf(1)).to.equal(
                await piMarket.getAddress()
            );

            const result = await piMarket._tokenMeta(4);
            expect(result.bidSale).to.equal(true);
        });

        it("should let alice change the start price of the auction", async () => {
            await piMarket.editSalePrice(4, 10000, 500);
            let result = await piMarket._tokenMeta(4);
            expect(result.price).to.equal(10000);
            await piMarket.editSalePrice(4, 50000, 500);
            result = await piMarket._tokenMeta(4);
            expect(result.price).to.equal(50000);
        });

        it("should let bidders place bid on piNFT", async () => {
            await expect(
                piMarket.connect(alice).Bid(4, 60000, { value: 60000 })
            ).to.be.revertedWithoutReason();

            await expect(
                piMarket.connect(bidder1).Bid(4, 50000, { value: 50000 })
            ).to.be.revertedWithoutReason();

            await piMarket.connect(bidder1).Bid(4, 60000, { value: 60000 });
            await piMarket.connect(bidder2).Bid(4, 65000, { value: 65000 });
            await piMarket.connect(bidder1).Bid(4, 70000, { value: 70000 });

            result = await piMarket.Bids(4, 2);
            expect(result.buyerAddress).to.equal(await bidder1.getAddress());
        });

        it("should not let alice change the auction price after bidding has begun", async () => {
            await expect(piMarket.editSalePrice(4, 10000, 500)).to.be.revertedWith(
                "Bid has started"
            );
        });

        it("should let alice execute highest bid", async () => {
            const _balance1 = await ethers.provider.getBalance(alice.getAddress());
            const _balance2 = await ethers.provider.getBalance(
                royaltyReceiver.getAddress()
            );
            const _balance3 = await ethers.provider.getBalance(
                feeReceiver.getAddress()
            );
            const _balance4 = await ethers.provider.getBalance(
                validator.getAddress()
            );

            await expect(
                piMarket.connect(bob).executeBidOrder(4, 2, true)
            ).to.be.revertedWithoutReason();

            await piMarket.connect(alice).executeBidOrder(4, 2, true);
            // result = await piNFT.ownerOf(1);
            expect(await collectionContract.ownerOf(1)).to.equal(
                await bidder1.getAddress()
            );

            const balance1 = await ethers.provider.getBalance(alice.getAddress());
            const balance2 = await ethers.provider.getBalance(
                royaltyReceiver.getAddress()
            );
            const balance3 = await ethers.provider.getBalance(
                feeReceiver.getAddress()
            );
            const balance4 = await ethers.provider.getBalance(validator.getAddress());

            let bal1 = BigNumber(balance2.toString()).minus(
                BigNumber(_balance2.toString())
            );
            let _bal1 = (70000 * 500) / 10000;
            expect(bal1.toString()).to.equal(_bal1.toString());

            let bal2 = BigNumber(balance3.toString()).minus(
                BigNumber(_balance3.toString())
            );
            let _bal2 = (70000 * 100) / 10000;
            expect(bal2.toString()).to.equal(_bal2.toString());

            let bal3 = BigNumber(balance4.toString()).minus(
                BigNumber(_balance4.toString())
            );
            let _bal3 = (70000 * 1200) / 10000;
            expect(bal3.toString()).to.equal(_bal3.toString());

            let commission = await piNftMethods.validatorCommissions(
                collectionContract.getAddress(),
                1
            );
            expect(commission.isValid).to.equal(false);
            expect(commission.commission.account).to.equal(
                await validator.getAddress()
            );
            expect(commission.commission.value).to.equal(900);
        });

        it("should not let wallet withdraw anothers bid", async () => {
            await expect(
                piMarket.connect(bidder2).withdrawBidMoney(4, 0)
            ).to.be.revertedWithoutReason();
        });

        it("should let other bidders withdraw their bids", async () => {
            await piMarket.connect(bidder1).withdrawBidMoney(4, 0);
            await piMarket.connect(bidder2).withdrawBidMoney(4, 1);
            const balance1 = await ethers.provider.getBalance(piMarket.getAddress());
            expect(balance1.toString()).to.equal("0");
            await collectionContract
                .connect(bidder1)
                .safeTransferFrom(bidder1.getAddress(), alice.getAddress(), 1);
        });

        it("should not let bidder withdraw again", async () => {
            // await expectRevert.unspecified(piMarket.withdrawBidMoney(4, 0, { from: bidder1 }))
            await expect(
                piMarket.connect(bidder1).withdrawBidMoney(4, 0)
            ).to.be.revertedWithoutReason();
        });

        it("should not execute a withdrawn bid", async () => {
            // await expectRevert.unspecified(piMarket.executeBidOrder(4, 1, true, { from: alice }))
            await expect(
                piMarket.connect(alice).executeBidOrder(4, 1, true)
            ).to.be.revertedWithoutReason();
        });

        it("should let alice place piNFT on auction", async () => {
            await collectionContract.approve(piMarket.getAddress(), 1);
            await piMarket.SellNFT_byBid(
                collectionContract.getAddress(),
                1,
                50000,
                300,
                "0x0000000000000000000000000000000000000000"
            );
            expect(await collectionContract.ownerOf(1)).to.equal(
                await piMarket.getAddress()
            );
            const result = await piMarket._tokenMeta(5);
            expect(result.bidSale).to.equal(true);
        });

        it("should let bidders place bid on piNFT", async () => {
            await piMarket.connect(bidder1).Bid(5, 70000, { value: 70000 });
            result = await piMarket.Bids(5, 0);

            expect(result.buyerAddress).to.equal(await bidder1.getAddress());
        });

        it("should let alice execute highest bid", async () => {
            const _balance1 = await ethers.provider.getBalance(alice.getAddress());
            const _balance2 = await ethers.provider.getBalance(
                royaltyReceiver.getAddress()
            );
            const _balance3 = await ethers.provider.getBalance(
                feeReceiver.getAddress()
            );
            const _balance4 = await ethers.provider.getBalance(
                validator.getAddress()
            );

            await expect(
                piMarket.connect(bob).executeBidOrder(4, 2, true)
            ).to.be.revertedWithoutReason();

            await piMarket.connect(alice).executeBidOrder(5, 0, true);
            // result = await piNFT.ownerOf(1);
            expect(await collectionContract.ownerOf(1)).to.equal(
                await bidder1.getAddress()
            );

            const balance1 = await ethers.provider.getBalance(alice.getAddress());
            const balance2 = await ethers.provider.getBalance(
                royaltyReceiver.getAddress()
            );
            const balance3 = await ethers.provider.getBalance(
                feeReceiver.getAddress()
            );
            const balance4 = await ethers.provider.getBalance(validator.getAddress());

            let bal1 = BigNumber(balance2.toString()).minus(
                BigNumber(_balance2.toString())
            );
            let _bal1 = (70000 * 500) / 10000;
            expect(bal1.toString()).to.equal(_bal1.toString());

            let bal2 = BigNumber(balance3.toString()).minus(
                BigNumber(_balance3.toString())
            );
            let _bal2 = (70000 * 100) / 10000;
            expect(bal2.toString()).to.equal(_bal2.toString());

            let bal3 = BigNumber(balance4.toString()).minus(
                BigNumber(_balance4.toString())
            );
            let _bal3 = (70000 * 300) / 10000;
            expect(bal3.toString()).to.equal(_bal3.toString());

            let commission = await piNftMethods.validatorCommissions(
                collectionContract.getAddress(),
                1
            );
            expect(commission.isValid).to.equal(false);
            expect(commission.commission.account).to.equal(
                await validator.getAddress()
            );
            expect(commission.commission.value).to.equal(900);
        });

        it("should let bidder disintegrate NFT and ERC20 tokens", async () => {
            await collectionContract
                .connect(bidder1)
                .approve(piNftMethods.getAddress(), 1);
            await piNftMethods
                .connect(bidder1)
                .redeemOrBurnPiNFT(
                    collectionContract.getAddress(),
                    1,
                    bob,
                    "0x0000000000000000000000000000000000000000",
                    sampleERC20.getAddress(),
                    false
                );
            await sampleERC20.balanceOf(validator.getAddress());
            expect(
                await piNftMethods.viewBalance(
                    collectionContract.getAddress(),
                    1,
                    sampleERC20.getAddress()
                )
            ).to.equal(0);
            expect(await sampleERC20.balanceOf(validator.getAddress())).to.equal(
                2000
            );
            expect(await collectionContract.ownerOf(1)).to.equal(
                await bob.getAddress()
            );

            let commission = await piNftMethods.validatorCommissions(
                collectionContract.getAddress(),
                1
            );
            expect(commission.isValid).to.equal(false);
            expect(commission.commission.account).to.equal(
                "0x0000000000000000000000000000000000000000"
            );
            expect(commission.commission.value).to.equal(0);
        });

        it("should create a piNFT with 500 erc20 tokens to alice", async () => {
            await sampleERC20.mint(validator.getAddress(), 1000);
            await collectionContract.mintNFT(alice.getAddress(), "URI2");
            let tokenId = 2;
            const owner = await collectionContract.ownerOf(tokenId);
            expect(owner).to.equal(await alice.getAddress());
            const bal = await collectionContract.balanceOf(alice.getAddress());
            expect(bal).to.equal(2);

            await piNftMethods.addValidator(
                collectionContract.getAddress(),
                tokenId,
                validator.getAddress()
            );
            let exp = new BN(await time.latest()).add(new BN(3600));
            await sampleERC20
                .connect(validator)
                .approve(piNftMethods.getAddress(), 500);
            await piNftMethods
                .connect(validator)
                .addERC20(
                    collectionContract.getAddress(),
                    tokenId,
                    sampleERC20.getAddress(),
                    500,
                    1000,
                    "uri",
                    [[validator.getAddress(), 200]]
                );

            let commission = await piNftMethods.validatorCommissions(
                collectionContract.getAddress(),
                2
            );
            expect(commission.isValid).to.equal(true);
            expect(commission.commission.account).to.equal(
                await validator.getAddress()
            );
            expect(commission.commission.value).to.equal(1000);
        });

        it("should let alice place piNFT on auction", async () => {
            await collectionContract.approve(piMarket.getAddress(), 2);
            await piMarket.SellNFT_byBid(
                collectionContract.getAddress(),
                2,
                50000,
                300,
                "0x0000000000000000000000000000000000000000"
            );
            expect(await collectionContract.ownerOf(2)).to.equal(
                await piMarket.getAddress()
            );

            const result = await piMarket._tokenMeta(6);
            expect(result.bidSale).to.equal(true);
        });

        it("should let bidders place bid on piNFT", async () => {
            await expect(
                piMarket.connect(alice).Bid(4, 60000, { value: 60000 })
            ).to.be.revertedWithoutReason();

            await expect(
                piMarket.connect(bidder1).Bid(4, 50000, { value: 50000 })
            ).to.be.revertedWithoutReason();

            await piMarket.connect(bidder2).Bid(6, 65000, { value: 65000 });
            await piMarket.connect(bidder1).Bid(6, 70000, { value: 70000 });

            result = await piMarket.Bids(6, 1);
            expect(result.buyerAddress).to.equal(await bidder1.getAddress());
        });

        it("should let bidder2 withdraw the bid", async () => {
            await piMarket.connect(bidder2).withdrawBidMoney(6, 0);
            result = await piMarket.Bids(6, 0);
            expect(result.withdrawn).to.equal(true);
        });

        it("should not allow owner to accept withdrawn bid", async () => {
            await expect(
                piMarket.executeBidOrder(6, 0, true)
            ).to.be.revertedWithoutReason();
        });

        it("should let highest bidder withdraw after auction expires", async () => {
            await time.increase(400);
            await piMarket.connect(bidder1).withdrawBidMoney(6, 1);
            result = await piMarket.Bids(6, 1);
            expect(result.withdrawn).to.equal(true);
        });
    });

    describe("Swap NFTs", () => {
        it("should create a piNFT with 500 erc20 tokens to alice", async () => {
            await sampleERC20.mint(validator.getAddress(), 1000);
            await collectionContract.mintNFT(alice.getAddress(), "URI2");
            let tokenId = 3;
            const owner = await collectionContract.ownerOf(tokenId);
            expect(owner).to.equal(await alice.getAddress());
            const bal = await collectionContract.balanceOf(alice.getAddress());
            expect(bal).to.equal(2);

            await piNftMethods.addValidator(
                collectionContract.getAddress(),
                tokenId,
                validator.getAddress()
            );
            let exp = new BN(await time.latest()).add(new BN(3600));
            await sampleERC20
                .connect(validator)
                .approve(piNftMethods.getAddress(), 500);
            await piNftMethods
                .connect(validator)
                .addERC20(
                    collectionContract.getAddress(),
                    tokenId,
                    sampleERC20.getAddress(),
                    500,
                    1000,
                    "uri",
                    [[validator.getAddress(), 200]]
                );
        });

        it("should create a piNFT with 1000 erc20 tokens to bob", async () => {
            await sampleERC20.mint(validator.getAddress(), 1000);
            await collectionContract.mintNFT(bob.getAddress(), "URI2");
            let tokenId = 4;
            const owner = await collectionContract.ownerOf(tokenId);
            expect(owner).to.equal(await bob.getAddress());
            const bal = await collectionContract.balanceOf(bob.getAddress());
            expect(bal).to.equal(2);

            await piNftMethods
                .connect(bob)
                .addValidator(
                    collectionContract.getAddress(),
                    tokenId,
                    validator.getAddress()
                );
                let exp = new BN(await time.latest()).add(new BN(3600));
            await sampleERC20
                .connect(validator)
                .approve(piNftMethods.getAddress(), 500);
            await piNftMethods
                .connect(validator)
                .addERC20(
                    collectionContract.getAddress(),
                    tokenId,
                    sampleERC20.getAddress(),
                    500,
                    0,
                    "uri",
                    [[validator.getAddress(), 200]]
                );
        });

        it("should create a piNFT again with 500 erc20 tokens to alice", async () => {
            await sampleERC20.mint(validator.getAddress(), 1000);
            await collectionContract.mintNFT(alice.getAddress(), "URI2");
            let tokenId = 5;
            const owner = await collectionContract.ownerOf(tokenId);
            expect(owner).to.equal(await alice.getAddress());
            const bal = await collectionContract.balanceOf(alice.getAddress());
            expect(bal).to.equal(3);

            await piNftMethods.addValidator(
                collectionContract.getAddress(),
                tokenId,
                validator.getAddress()
            );
            await sampleERC20
                .connect(validator)
                .approve(piNftMethods.getAddress(), 500);
                let exp = new BN(await time.latest()).add(new BN(3600));
            await piNftMethods
                .connect(validator)
                .addERC20(
                    collectionContract.getAddress(),
                    tokenId,
                    sampleERC20.getAddress(),
                    500,
                    0,
                    "uri",
                    [[validator.getAddress(), 200]]
                );
        });

        it("should let alice initiate swap request", async () => {
            await collectionContract.approve(piMarket.getAddress(), 3);
            await piMarket.makeSwapRequest(
                collectionContract.getAddress(),
                collectionContract.getAddress(),
                3,
                4
            );

            // let data = await piMarket._swaps(0);

            // expect(await data.initiator).to.equal(await alice.getAddress());

            expect(await collectionContract.ownerOf(3)).to.equal(
                await piMarket.getAddress()
            );
        });

        it("should let alice initiate swap request again", async () => {
            await collectionContract.approve(piMarket.getAddress(), 5);
            await piMarket.makeSwapRequest(
                collectionContract.getAddress(),
                collectionContract.getAddress(),
                5,
                4
            );

            // let data = await piMarket._swaps(0);

            // expect(await data.initiator).to.equal(await alice.getAddress());

            expect(await collectionContract.ownerOf(5)).to.equal(
                await piMarket.getAddress()
            );
        });

        it("should cancel the swap if requested token owner has changed", async () => {
            await collectionContract
                .connect(bob)
                .safeTransferFrom(bob.getAddress(), carl.getAddress(), 4);
            await collectionContract.connect(carl).approve(piMarket.getAddress(), 4);

            await expect(
                piMarket.connect(carl).acceptSwapRequest(0)
            ).to.be.revertedWith("requesting token owner has changed");
            await collectionContract
                .connect(carl)
                .safeTransferFrom(carl.getAddress(), bob.getAddress(), 4);
        });

        it("should not let an address that is not bob accept the swap request", async () => {
            await expect(
                piMarket.connect(carl).acceptSwapRequest(0)
            ).to.be.revertedWith("Only requested owner can accept swap");
        });

        it("should let bob accept the swap request", async () => {
            await collectionContract.connect(bob).approve(piMarket.getAddress(), 4);
            // let res = await piMarket._swaps(0);
            // expect(await res.status).to.equal(true);
            await piMarket.connect(bob).acceptSwapRequest(0);
            expect(await collectionContract.ownerOf(3)).to.equal(
                await bob.getAddress()
            );
            expect(await collectionContract.ownerOf(4)).to.equal(
                await alice.getAddress()
            );
            // res = await piMarket._swaps(0);
            // expect(await res.status).to.equal(false);
        });

        it("should let alice cancle the swap request", async () => {
            // let res = await piMarket._swaps(1);
            // expect(await res.status).to.equal(true);
            await piMarket.connect(alice).cancelSwap(1);
            expect(await collectionContract.ownerOf(5)).to.equal(
                await alice.getAddress()
            );
            // res = await piMarket._swaps(1);
            // expect(await res.status).to.equal(false);
        });
    });
});
