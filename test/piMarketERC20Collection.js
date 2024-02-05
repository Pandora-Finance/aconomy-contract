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

describe("piMarketERC20Collection", function () {

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

        // const LibPiNFTMethods = await hre.ethers.deployContract("LibPiNFTMethods", []);
        // await LibPiNFTMethods.waitForDeployment();

        const piNFTMethods = await hre.ethers.getContractFactory("piNFTMethods", {
            libraries: {
                LibShare: await LibShare.getAddress(),
                // LibPiNFTMethods: await LibPiNFTMethods.getAddress(),
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

        console.log("AconomyFee : ", await aconomyFee.getAddress());
        console.log("CollectionMethods : ", await CollectionMethod.getAddress());
        console.log("CollectionFactory : ", await factory.getAddress());
        console.log("mintToken : ", await sampleERC20.getAddress());
        console.log("piNFT: ", await piNFT.getAddress());
        console.log("piNFTMethods", await piNftMethods.getAddress());
        console.log("piMarket:", await piMarket.getAddress());

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



        it("should create a piNFT with 500 erc20 tokens to carl", async () => {

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
            const bal = await collectionContract.balanceOf(carl);
            expect(bal).to.equal(1);

            await piNftMethods
                .connect(carl)
                .addValidator(collectionContract.getAddress(), 0, validator.getAddress());
            await sampleERC20
                .connect(validator)
                .approve(piNftMethods.getAddress(), 500);
                let exp = new BN(await time.latest()).add(new BN(3600));
            await piNftMethods
                .connect(validator)
                .addERC20(collectionContract.getAddress(), 0, sampleERC20.getAddress(), 500, 1000, [
                    [validator.getAddress(), 200],
                ]);

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
                    sampleERC20.getAddress()
                )
            ).to.be.revertedWithoutReason();
        })

        it("should not place nft on sale if contract address is 0", async () => {
            await collectionContract.approve(piMarket.getAddress(), 0);
            await expect(
                piMarket.sellNFT(
                    "0x0000000000000000000000000000000000000000",
                    0,
                    50000,
                    sampleERC20.getAddress()
                )
            ).to.be.revertedWithoutReason();
        })

        it("should let alice place piNFT on sale", async () => {

            await collectionContract.approve(piMarket.getAddress(), 0);
            await piMarket.sellNFT(
                collectionContract.getAddress(),
                0,
                50000,
                sampleERC20.getAddress()
            );
            expect(await collectionContract.ownerOf(0)).to.equal(
                await piMarket.getAddress()
            );
        });


        it("should edit the price after listing on sale", async () => {
            await piMarket.connect(alice).editSalePrice(1, 60000);
            await expect(
                piMarket.connect(bob).editSalePrice(1, 60000)
            ).to.be.revertedWith("You are not the owner");

            await expect(
                piMarket.connect(alice).editSalePrice(1, 60)
            ).to.be.revertedWithoutReason();

            let data = await piMarket._tokenMeta(1);
            expect(await data.price).to.equal("60000");
            await piMarket.connect(alice).editSalePrice(1, 50000);
            let newdata = await piMarket._tokenMeta(1);
            expect(await newdata.price).to.equal(50000);
        });

        it("should not let seller buy their own nft", async () => {



            await sampleERC20.connect(alice).approve(piMarket.getAddress(), 50000);
            await expect(
                piMarket.BuyNFT(1, true)
            ).to.be.revertedWithoutReason();
        })

        it("should let bob buy piNFT", async () => {
            let meta = await piMarket._tokenMeta(1);
            expect(meta.status).to.equal(true);
            await sampleERC20.mint(bob, 50000);

            let _balance1 = await sampleERC20.balanceOf(alice.getAddress());
            let _balance2 = await sampleERC20.balanceOf(royaltyReceiver.getAddress());
            let _balance3 = await sampleERC20.balanceOf(feeReceiver.getAddress());
            let _balance4 = await sampleERC20.balanceOf(validator.getAddress());

            await sampleERC20.connect(bob).approve(piMarket.getAddress(), 50000);

            result2 = await piMarket.connect(bob).BuyNFT(1, true);
            expect(await collectionContract.ownerOf(0)).to.equal(await bob.getAddress());
            /*validator 200
                        royalties 500
                        fee 100
                        total = 800
            
                        mean alic should get 10000 - 800 = 9200 = 92%
            
                        */

            let balance1 = await sampleERC20.balanceOf(alice.getAddress());
            let balance2 = await sampleERC20.balanceOf(royaltyReceiver.getAddress());
            let balance3 = await sampleERC20.balanceOf(feeReceiver.getAddress());
            let balance4 = await sampleERC20.balanceOf(validator.getAddress());
            let temp = BigNumber(balance1.toString()).minus(
                BigNumber(_balance1.toString())
            );
            let alicegotAmount = (50000 * 8200) / 10000;
            expect(temp.toString()).to.equal(alicegotAmount.toString());
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

            let newMeta = await piMarket._tokenMeta(1);
            expect(newMeta.status).to.equal(false);

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

            await collectionContract.connect(bob).approve(piNftMethods.getAddress(), 0);
            await piNftMethods
                .connect(bob)
                .withdraw(collectionContract.getAddress(), 0, sampleERC20.getAddress(), 200);
            expect(await sampleERC20.balanceOf(bob)).to.equal(200);
            expect(await collectionContract.ownerOf(0)).to.equal(await piNftMethods.getAddress());
        });

        it("should let bob withdraw more funds from the NFT", async () => {
            await piNftMethods
                .connect(bob)
                .withdraw(collectionContract.getAddress(), 0, sampleERC20.getAddress(), 100);
            expect(await sampleERC20.balanceOf(bob)).to.equal(300);
            expect(await collectionContract.ownerOf(0)).to.equal(await piNftMethods.getAddress());
        });


        it("should let bob repay funds to the NFT", async () => {
            await sampleERC20.connect(bob).approve(piNftMethods.getAddress(), 300);
            await piNftMethods
                .connect(bob)
                .Repay(collectionContract.getAddress(), 0, sampleERC20.getAddress(), 300);
            expect(await sampleERC20.balanceOf(bob)).to.equal(0);
            expect(await collectionContract.ownerOf(0)).to.equal(await bob.getAddress());
        });

        it("should allow validator to add erc20 and change commission and royalties", async () => {
            await sampleERC20
                .connect(validator)
                .approve(piNftMethods.getAddress(), 500);
                let exp = new BN(await time.latest()).add(new BN(7500));
                await time.increase(3601);
            await piNftMethods
                .connect(validator)
                .addERC20(collectionContract.getAddress(), 0, sampleERC20.getAddress(), 500, 100, [
                    [validator.getAddress(), 300],
                ]);
            let commission = await piNftMethods.validatorCommissions(
                collectionContract.getAddress(),
                0
            );
            expect(commission.isValid).to.equal(false);
            expect(commission.commission.account).to.equal(
                await validator.getAddress()
            );
            expect(commission.commission.value).to.equal(100);
        })

        it("should let bob place piNFT on sale", async () => {
            await collectionContract.connect(bob).approve(piMarket.getAddress(), 0);
            const result = await piMarket
                .connect(bob)
                .sellNFT(collectionContract.getAddress(), 0, 50000, sampleERC20.getAddress());
            expect(await collectionContract.ownerOf(0)).to.equal(await piMarket.getAddress());
        });

        it("should let alice buy piNFT", async () => {
            let meta = await piMarket._tokenMeta(2);
            expect(meta.status).to.equal(true);

            let _balance1 = await sampleERC20.balanceOf(bob.getAddress());
            let _balance2 = await sampleERC20.balanceOf(royaltyReceiver.getAddress());
            let _balance3 = await sampleERC20.balanceOf(feeReceiver.getAddress());
            let _balance4 = await sampleERC20.balanceOf(validator.getAddress());

            await sampleERC20.connect(alice).approve(piMarket.getAddress(), 50000);

            result2 = await piMarket
                .connect(alice)
                .BuyNFT(2, true);
            expect(await collectionContract.ownerOf(0)).to.equal(await alice.getAddress());
            /*validator 200
                        royalties 500
                        fee 100
                        total = 800
            
                        mean alic should get 10000 - 800 = 9200 = 92%
            
                        */

            let balance1 = await sampleERC20.balanceOf(bob.getAddress());
            let balance2 = await sampleERC20.balanceOf(royaltyReceiver.getAddress());
            let balance3 = await sampleERC20.balanceOf(feeReceiver.getAddress());
            let balance4 = await sampleERC20.balanceOf(validator.getAddress());
            let temp = BigNumber(balance1.toString()).minus(
                BigNumber(_balance1.toString())
            );
            let alicegotAmount = (50000 * 9100) / 10000;
            expect(temp.toString()).to.equal(alicegotAmount.toString());
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

            let newMeta = await piMarket._tokenMeta(1);
            expect(newMeta.status).to.equal(false);

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
                .sellNFT(collectionContract.getAddress(), 0, 10000, sampleERC20.getAddress());
            expect(await collectionContract.ownerOf(0)).to.equal(await piMarket.getAddress());
        });

        it("should not let non owner cancel sale", async () => {
            await expect(
                piMarket.connect(alice).cancelSale(3)
            ).to.be.revertedWithoutReason();
        });

        it("should let bob cancel sale", async () => {
            await piMarket.connect(bob).cancelSale(3);
            meta = await piMarket._tokenMeta(3);
            expect(meta.status).to.equal(false);
        });

        it("should let bob redeem piNFT", async () => {
            await collectionContract.connect(bob).approve(piNftMethods.getAddress(), 0);
            await piNftMethods
                .connect(bob)
                .redeemOrBurnPiNFT(
                    collectionContract.getAddress(),
                    0,
                    alice,
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
                8500
            );

            expect(await collectionContract.ownerOf(0)).to.equal(await alice.getAddress());

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
    })



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
                    1000,
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
                    sampleERC20.getAddress()
                )
            ).to.be.revertedWithoutReason();
        })

        it("should not place nft on auction if contract address is 0", async () => {
            await collectionContract.approve(piMarket.getAddress(), 1);
            await expect(
                piMarket.SellNFT_byBid(
                    "0x0000000000000000000000000000000000000000",
                    1,
                    50000,
                    300,
                    sampleERC20.getAddress()
                )
            ).to.be.revertedWithoutReason();
        })

        it("should not place nft on auction if auction time is 0", async () => {
            await collectionContract.approve(piMarket.getAddress(), 1);
            await expect(
                piMarket.SellNFT_byBid(
                    collectionContract.getAddress(),
                    1,
                    50000,
                    0,
                    sampleERC20.getAddress()
                )
            ).to.be.revertedWithoutReason();
        })

        // it("should let alice place piNFT on auction", async () => {
        //     await collectionContract.approve(piMarket.getAddress(), 1);
        //     await piMarket.SellNFT_byBid(
        //         collectionContract.getAddress(),
        //         1,
        //         50000,
        //         300,
        //         sampleERC20.getAddress()
        //     );
        //     expect(await collectionContract.ownerOf(1)).to.equal(await piMarket.getAddress());

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
        // })

        it("should allow validator to add erc20 and change commission and royalties", async () => {

            await sampleERC20
                .connect(validator)
                .approve(piNftMethods.getAddress(), 500);
                let exp = new BN(await time.latest()).add(new BN(7500));
                await time.increase(3601);
            await piNftMethods
                .connect(validator)
                .addERC20(collectionContract.getAddress(), 1, sampleERC20.getAddress(), 500, 100, [
                    [validator.getAddress(), 300],
                ]);
            let commission = await piNftMethods.validatorCommissions(
                collectionContract.getAddress(),
                1
            );
            expect(commission.isValid).to.equal(true);
            expect(commission.commission.account).to.equal(
                await validator.getAddress()
            );
            expect(commission.commission.value).to.equal(100);
        })

        it("should let alice place piNFT on auction", async () => {
            await collectionContract.approve(piMarket.getAddress(), 1);
            await piMarket.SellNFT_byBid(
                collectionContract.getAddress(),
                1,
                50000,
                300,
                sampleERC20.getAddress()
            );
            expect(await collectionContract.ownerOf(1)).to.equal(await piMarket.getAddress());

            const result = await piMarket._tokenMeta(4);
            expect(result.bidSale).to.equal(true);
        });

        it("should let alice change the start price of the auction", async () => {
            await piMarket.editSalePrice(4, 10000);
            let result = await piMarket._tokenMeta(4);
            expect(result.price).to.equal(10000);
            await piMarket.editSalePrice(4, 50000);
            result = await piMarket._tokenMeta(4);
            expect(result.price).to.equal(50000);
        })

        it("should let bidders place bid on piNFT", async () => {
            await sampleERC20.mint(bidder1.getAddress(), 130000);
            await sampleERC20.mint(bidder2.getAddress(), 65000);
            await sampleERC20.connect(bidder2).approve(piMarket.getAddress(), 65000);
            await sampleERC20.connect(bidder1).approve(piMarket.getAddress(), 130000);

            await expect(
                piMarket.connect(alice).Bid(4, 60000)
            ).to.be.revertedWithoutReason();

            await expect(
                piMarket.connect(bidder1).Bid(4, 50000)
            ).to.be.revertedWithoutReason();

            await piMarket.connect(bidder1).Bid(4, 60000);
            await piMarket.connect(bidder2).Bid(4, 65000);
            await piMarket.connect(bidder1).Bid(4, 70000);

            result = await piMarket.Bids(4, 2);
            expect(result.buyerAddress).to.equal(await bidder1.getAddress());
        });

        it("should not let alice change the auction price after bidding has begun", async () => {
            await expect(piMarket.editSalePrice(4, 10000)).to.be.revertedWith(
                "Bid has started"
            );
        })

        it("should let alice execute highest bid", async () => {
            let _balance1 = await sampleERC20.balanceOf(alice.getAddress());
            let _balance2 = await sampleERC20.balanceOf(royaltyReceiver.getAddress());
            let _balance3 = await sampleERC20.balanceOf(feeReceiver.getAddress());
            let _balance4 = await sampleERC20.balanceOf(validator.getAddress());

            await expect(
                piMarket.connect(bob).executeBidOrder(4, 2, true)
            ).to.be.revertedWithoutReason();

            await piMarket.connect(alice).executeBidOrder(4, 2, true);

            expect(await collectionContract.ownerOf(1)).to.equal(await bidder1.getAddress());

            let balance1 = await sampleERC20.balanceOf(alice.getAddress());
            let balance2 = await sampleERC20.balanceOf(royaltyReceiver.getAddress());
            let balance3 = await sampleERC20.balanceOf(feeReceiver.getAddress());
            let balance4 = await sampleERC20.balanceOf(validator.getAddress());
            let bal = BigNumber(balance1.toString()).minus(
                BigNumber(_balance1.toString())
            );
            let _bal = (70000 * 9000) / 10000;
            expect(bal.toString()).to.equal(_bal.toString());


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
            let _bal3 = (70000 * 400) / 10000;
            expect(bal3.toString()).to.equal(_bal3.toString());

            let commission = await piNftMethods.validatorCommissions(
                collectionContract.getAddress(),
                1
            );
            expect(commission.isValid).to.equal(false);
            expect(commission.commission.account).to.equal(
                await validator.getAddress()
            );
            expect(commission.commission.value).to.equal(100);
        });

        it("should not let wallet withdraw anothers bid", async () => {
            await expect(
                piMarket.connect(bidder2).withdrawBidMoney(4, 0)
            ).to.be.revertedWithoutReason();
        })

        it("should let other bidders withdraw their bids", async () => {
            await piMarket.connect(bidder1).withdrawBidMoney(4, 0);
            await piMarket.connect(bidder2).withdrawBidMoney(4, 1);
            const balance1 = await sampleERC20.balanceOf(piMarket.getAddress())
            expect(balance1.toString()).to.equal("0");
        });

        it("should not let bidder withdraw again", async () => {
            await expect(
                piMarket.connect(bidder1).withdrawBidMoney(4, 0)
            ).to.be.revertedWithoutReason();
        })

        it("should not execute a withdrawn bid", async () => {
            await expect(
                piMarket.connect(alice).executeBidOrder(4, 1, false)
            ).to.be.revertedWithoutReason();
        })

        it("should let alice place piNFT on auction", async () => {
            await collectionContract.connect(bidder1).safeTransferFrom(bidder1.getAddress(), alice.getAddress(), 1)
            await collectionContract.approve(piMarket.getAddress(), 1);
            await piMarket.SellNFT_byBid(
                collectionContract.getAddress(),
                1,
                50000,
                300,
                sampleERC20.getAddress()
            );
            expect(await collectionContract.ownerOf(1)).to.equal(await piMarket.getAddress());

            const result = await piMarket._tokenMeta(5);
            expect(result.bidSale).to.equal(true);
        });

        it("should let bidders place bid on piNFT", async () => {
            await sampleERC20.mint(bidder1.getAddress(), 70000);
            await sampleERC20.connect(bidder1).approve(piMarket.getAddress(), 70000);

            await expect(
                piMarket.connect(alice).Bid(5, 70000)
            ).to.be.revertedWithoutReason();

            await expect(
                piMarket.connect(bidder1).Bid(5, 50000)
            ).to.be.revertedWithoutReason();

            await piMarket.connect(bidder1).Bid(5, 70000);

            result = await piMarket.Bids(5, 0);
            expect(result.buyerAddress).to.equal(await bidder1.getAddress());
        });

        it("should let alice execute highest bid", async () => {

            let _balance1 = await sampleERC20.balanceOf(alice.getAddress());
            let _balance2 = await sampleERC20.balanceOf(royaltyReceiver.getAddress());
            let _balance3 = await sampleERC20.balanceOf(feeReceiver.getAddress());
            let _balance4 = await sampleERC20.balanceOf(validator.getAddress());

            await expect(
                piMarket.connect(bob).executeBidOrder(5, 0, true)
            ).to.be.revertedWithoutReason();

            await piMarket.connect(alice).executeBidOrder(5, 0, true);
            expect(await collectionContract.ownerOf(1)).to.equal(await bidder1.getAddress());

            let balance1 = await sampleERC20.balanceOf(alice.getAddress());
            let balance2 = await sampleERC20.balanceOf(royaltyReceiver.getAddress());
            let balance3 = await sampleERC20.balanceOf(feeReceiver.getAddress());
            let balance4 = await sampleERC20.balanceOf(validator.getAddress());
            let bal = BigNumber(balance1.toString()).minus(
                BigNumber(_balance1.toString())
            );
            let _bal = (70000 * 9100) / 10000;
            expect(bal.toString()).to.equal(_bal.toString());


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
            expect(commission.commission.value).to.equal(100);
        });


        it("should let bidder disintegrate NFT and ERC20 tokens", async () => {
            await collectionContract.connect(bidder1).approve(piNftMethods.getAddress(), 1);
            await piNftMethods
                .connect(bidder1)
                .redeemOrBurnPiNFT(
                    collectionContract.getAddress(),
                    1,
                    bob.getAddress(),
                    "0x0000000000000000000000000000000000000000",
                    sampleERC20.getAddress(),
                    false
                );
            const validatorBal = await sampleERC20.balanceOf(validator.getAddress());
            expect(
                await piNftMethods.viewBalance(
                    collectionContract.getAddress(),
                    1,
                    sampleERC20.getAddress()
                )
            ).to.equal(0);
            expect(await sampleERC20.balanceOf(validator.getAddress())).to.equal(
                14400
            );
            expect(await collectionContract.ownerOf(1)).to.equal(await bob.getAddress());

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
    })
})