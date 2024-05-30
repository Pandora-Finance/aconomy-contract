const { upgrades } = require("hardhat");
const hre = require("hardhat");
require('dotenv').config()
let walletAddress = process.env.WALLET_ADDRESS
async function main() {
//   const LibShare = await hre.ethers.deployContract("LibShare", []);
//   await LibShare.waitForDeployment();
//   const LibPiNFTMethods = await hre.ethers.deployContract("LibPiNFTMethods", []);
//   await LibPiNFTMethods.waitForDeployment();
//   const piNFTMethods = await hre.ethers.getContractFactory("piNFTMethods", {
//     libraries: {
//       LibPiNFTMethods: await LibPiNFTMethods.getAddress(),
//       LibShare: await LibShare.getAddress(),
//     }
//   })
const ValidatorStake = await hre.ethers.getContractFactory("validatorStake")
    // const instance = await upgrades.forceImport("0x26Cd55C405a4FD18Cca86e6549A6a6a93924d473", ValidatorStake)
    const Stake = await upgrades.upgradeProxy("0x26Cd55C405a4FD18Cca86e6549A6a6a93924d473", ValidatorStake, {
        kind: "uups",
        // unsafeAllow: ["external-library-linking"],
      })
    console.log("ValidatorStake upgraded to: ", Stake.target);
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});