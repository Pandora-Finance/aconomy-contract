const PiNFT = artifacts.require("piNFT");
const SampleERC20 = artifacts.require("mintToken");

module.exports = async function (deployer) {
  await deployer.deploy(PiNFT, "Aconomy", "ACO");
  let pi = await PiNFT.deployed();
  console.log("piNFT: ", pi.address);
  //deployer.deploy(SampleERC20, "1000000");
};