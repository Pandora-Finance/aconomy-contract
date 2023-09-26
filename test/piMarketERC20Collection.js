const {
    loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { time } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

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
            await piNFT.mintNFT(carl.getAddress(), "URI1", [
                [royaltyReceiver.getAddress(), 500],
            ]);

            const owner = await piNFT.ownerOf(0);
            expect(owner).to.equal(await carl.getAddress());
            const bal = await piNFT.balanceOf(carl);
            expect(bal).to.equal(1);

            await piNftMethods
                .connect(carl)
                .addValidator(piNFT.getAddress(), 0, validator.getAddress());
            await sampleERC20
                .connect(validator)
                .approve(piNftMethods.getAddress(), 500);
            await piNftMethods
                .connect(validator)
                .addERC20(piNFT.getAddress(), 0, sampleERC20.getAddress(), 500, 1000, [
                    [validator.getAddress(), 200],
                ]);

            const tokenBal = await piNftMethods.viewBalance(
                piNFT.getAddress(),
                0,
                sampleERC20.getAddress()
            );

            expect(tokenBal).to.equal(500);

            let commission = await piNftMethods.validatorCommissions(
                piNFT.getAddress(),
                0
            );
            expect(commission.isValid).to.equal(true);
            expect(commission.commission.account).to.equal(
                await validator.getAddress()
            );
            expect(commission.commission.value).to.equal(1000);
        });

        //   it("should deploy the marketplace contract", async () => {
        //     piMarket = await PiMarket.deployed();
        //     assert(piMarket !== undefined, "PiMarket contract was not deployed");
        //   });

    })
})