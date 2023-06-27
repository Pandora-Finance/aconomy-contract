const PiNFT = artifacts.require("piNFT");
const SampleERC20 = artifacts.require("mintToken");

module.exports = async function (deployer) {
  await deployer.deploy(PiNFT, "Aconomy", "ACO", "0xd8253782c45a12053594b9deB72d8e8aB2Fca54c");
  let pi = await PiNFT.deployed();
  console.log("piNFT: ", pi.address);
  //deployer.deploy(SampleERC20, "1000000");
};