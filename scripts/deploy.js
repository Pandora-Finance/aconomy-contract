// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { upgrades } = require("hardhat");
const hre = require("hardhat");
require('dotenv').config()
let walletAddress = process.env.WALLET_ADDRESS
async function main() {
  // const aconomy = await hre.ethers.deployContract("Aconomy", []);
  // await aconomy.waitForDeployment();
  // console.log("Aconomy deployed at:", await aconomy.getAddress());
  // const aconomyfee = await hre.ethers.deployContract("AconomyFee", []);
  // await aconomyfee.waitForDeployment();
  // // await aconomyfee.setAconomyPoolFee(100)
  // // await aconomyfee.setAconomyPiMarketFee(100)
  // // await aconomyfee.setAconomyNFTLendBorrowFee(100)
  // const LibShare = await hre.ethers.deployContract("LibShare", []);
  // await LibShare.waitForDeployment();
  // const piNFTMethods = await hre.ethers.getContractFactory("piNFTMethods", {
  //   libraries: {
  //     LibShare: await LibShare.getAddress()
  //   }
  // })
  // const piNftMethods = await upgrades.deployProxy(piNFTMethods, ["0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"], {
  //   initializer: "initialize",
  //   kind: "uups",
  //   unsafeAllow: ["external-library-linking"],
  // })
  // const LibCollection = await hre.ethers.deployContract("LibCollection", []);
  // await LibCollection.waitForDeployment();
  // const CollectionMethods = await hre.ethers.deployContract("CollectionMethods", []);
  // let CollectionMethod = await CollectionMethods.waitForDeployment();
  // const CollectionFactory = await hre.ethers.getContractFactory("CollectionFactory", {
  //   libraries: {
  //     LibCollection: await LibCollection.getAddress()
  //   }
  // })
  // const collectionFactory = await upgrades.deployProxy(CollectionFactory, [await CollectionMethod.getAddress(), await piNftMethods.getAddress()], {
  //   initializer: "initialize",
  //   kind: "uups",
  //   unsafeAllow: ["external-library-linking"],
  // })
  // await CollectionMethods.initialize(walletAddress, await collectionFactory.getAddress(), "xyz", "xyz")


  // const LibCalculations = await hre.ethers.deployContract("LibCalculations", []);
  // await LibCalculations.waitForDeployment();
  // const LibNFTLendingBorrowing = await hre.ethers.deployContract("LibNFTLendingBorrowing", []);
  // await LibNFTLendingBorrowing.waitForDeployment();

  // const NFTlendingBorrowing = await hre.ethers.getContractFactory("NFTlendingBorrowing", {
  //   libraries: {
  //     LibCalculations: await LibCalculations.getAddress(),
  //     LibNFTLendingBorrowing: await LibNFTLendingBorrowing.getAddress()
  //   }
  // })
  // const lending = await upgrades.deployProxy(NFTlendingBorrowing, ["0x4a3639F748a384896cBE9cC4f600a1a10830e3d9"], {
  //   initializer: "initialize",
  //   kind: "uups",
  //   unsafeAllow: ["external-library-linking"],
  // })






  // const piNFT = await hre.ethers.getContractFactory("piNFT")
  // const pi = await upgrades.deployProxy(piNFT, ["Aconomy", "ACONOMY", await piNftMethods.getAddress(), "0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"], {
  //   initializer: "initialize",
  //   kind: "uups"
  // })
  // const LibMarket = await hre.ethers.deployContract("LibMarket", []);
  // await LibMarket.waitForDeployment();
  // const piMarket = await hre.ethers.getContractFactory("piMarket", {
  //   libraries: {
  //     LibMarket: await LibMarket.getAddress()
  //   }
  // })
  // const market = await upgrades.deployProxy(piMarket, [await aconomyfee.getAddress(), await collectionFactory.getAddress(), await piNftMethods.getAddress(), await pi.getAddress()], {
  //   initializer: "initialize",
  //   kind: "uups",
  //   unsafeAllow: ["external-library-linking"],
  // })
  // await piNftMethods.setPiMarket(market.getAddress());
  // const ValidatorStake = await hre.ethers.getContractFactory("validatorStake")
  // const Stake = await upgrades.deployProxy(ValidatorStake, [], {
  //   initializer: "initialize",
  //   kind: "uups"
  // })
  // const validateNFT = await hre.ethers.getContractFactory("validatedNFT")
  // validatedNFT = await upgrades.deployProxy(
  //   validateNFT,
  //   ["aconomy","ACO" ,"0x86C44EA998c33cD46Cbc1856CBC6e3268083D7d4"],
  //   {
  //     initializer: "initialize",
  //     kind: "uups",
  //   }
  // );

  const stakingyield = await hre.ethers.deployContract("StakingYield", [
    "0xf09451EE328471390ac0C01cb17753b3d05e7eB8",
    "0x37a6F444c6b3A42fA37476bB1Ed79F567b26b82D",
  ]);
  stakingYield = await stakingyield.waitForDeployment();

  console.log("stakingYield : ", await stakingYield.getAddress());
  // console.log("ValidatedNFT : ", await validatedNFT.getAddress())
  //  console.log("ValidatorStake : ", await Stake.getAddress())
  // console.log("AconomyFee : ", await aconomyfee.getAddress())
  // console.log("CollectionMethods : ", await CollectionMethod.getAddress())
  // console.log("CollectionFactory : ", await collectionFactory.getAddress())
  // console.log("NFTlendingBorrowing : ", await lending.getAddress())
  // console.log("piNFT: ", await pi.getAddress());
  // console.log("piNFTMethods", await piNftMethods.getAddress());
  // console.log("piMarket:", await market.getAddress());



//   const lock = await hre.ethers.deployContract("Lock", [unlockTime], {
//     value: lockedAmount,
//   });
//   await lock.waitForDeployment();
//   console.log(
//     `Lock with ${ethers.formatEther(
//       lockedAmount
//     )}ETH and unlock timestamp ${unlockTime} deployed to ${lock.target}`
//   );
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});