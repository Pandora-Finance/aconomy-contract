const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const PiMarketV2 = artifacts.require("piMarketV2");
const LibMarketV2 = artifacts.require("LibMarketV2");

module.exports = async function (deployer) {
  await deployer.deploy(LibMarketV2);
  await deployer.link(LibMarketV2, [PiMarketV2])
};