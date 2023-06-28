const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const PiNFT = artifacts.require("piNFT");
const SampleERC20 = artifacts.require("mintToken");
const piNFTMethods = artifacts.require("piNFTMethods");

module.exports = async function (deployer) {
  var piNftMethods = await piNFTMethods.deployed();
  await deployer.deploy(PiNFT, "Aconomy", "ACO", piNftMethods.address, "0xd8253782c45a12053594b9deB72d8e8aB2Fca54c");
  let pi = await PiNFT.deployed();
  console.log("piNFT: ", pi.address);
  console.log("piNFTMethods", piNftMethods.address);
  //deployer.deploy(SampleERC20, "1000000");
};