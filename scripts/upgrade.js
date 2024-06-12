const { upgrades } = require("hardhat");
const hre = require("hardhat");
require('dotenv').config()
let walletAddress = process.env.WALLET_ADDRESS
async function main() {
//   const LibShare = await hre.ethers.deployContract("LibShare", []);
//   await LibShare.waitForDeployment();
const PiNFT = await hre.ethers.getContractFactory("piNFT")
    const instance = await upgrades.forceImport("0x1216FB6d886B82F5aefcEc1c709cbFef4b788413", PiNFT)
    const Stake = await upgrades.upgradeProxy("0xE0F30A4BF5fdAe8cff3cc8b50B4344C5306143A3", PiNFT, {
        kind: "uups",
        // unsafeAllow: ["external-library-linking"],
      })
    console.log("piNFT upgraded to: ", Stake.target);
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});