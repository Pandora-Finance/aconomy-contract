const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const PiNFT = artifacts.require("piNFT");
const SampleERC20 = artifacts.require("mintToken");
const piNFTMethods = artifacts.require("piNFTMethods");
const LibShare = artifacts.require("LibShare");

module.exports = async function (deployer) {
  var piNftMethods = await piNFTMethods.deployed();
  await deployer.link(LibShare, [PiNFT])

  var pi = await deployProxy(PiNFT, ["Aconomy", "ACO", piNftMethods.address, "0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"], {
    initializer: "initialize",
    kind: "uups",
    //unsafeAllow: ["external-library-linking"],
  });

  console.log("piNFT: ", pi.address);
  console.log("piNFTMethods", piNftMethods.address);
  //deployer.deploy(SampleERC20, "1000000");
};