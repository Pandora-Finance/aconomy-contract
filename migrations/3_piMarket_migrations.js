const PiMarket = artifacts.require("piMarket");
const LibMarket = artifacts.require("LibMarket");

const CollectionFactory = artifacts.require("CollectionFactory")
const CollectionMethods = artifacts.require("CollectionMethods")
// require("dotenv").config();

module.exports = async function (deployer) {
  await deployer.deploy(LibMarket);
  await deployer.link(LibMarket, [PiMarket])

  let collectionFactory = await CollectionFactory.deployed();

  await deployer.deploy(PiMarket, "0xFF708C09221d5BA90eA3e3A3C42E2aBc8cA8aAc9", collectionFactory.address);
  let market = await PiMarket.deployed();
  console.log("market:", market.address);
};