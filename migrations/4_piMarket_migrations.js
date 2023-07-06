const { deployProxy } = require("@openzeppelin/truffle-upgrades");

const PiMarket = artifacts.require("piMarket");
const LibMarket = artifacts.require("LibMarket");
const aconomyFee = artifacts.require("AconomyFee")

const CollectionFactory = artifacts.require("CollectionFactory")
const CollectionMethods = artifacts.require("CollectionMethods")
// require("dotenv").config();

module.exports = async function (deployer) {
  await deployer.deploy(LibMarket);
  await deployer.link(LibMarket, [PiMarket])

  let collectionFactory = await CollectionFactory.deployed();
  var aconomyfee = await aconomyFee.deployed();

  var market = await deployProxy(PiMarket, [aconomyfee.address, collectionFactory.address], {
    initializer: "initialize",
    kind: "uups",
    unsafeAllow: ["external-library-linking"],
  });

  console.log("piMarket:", market.address);
};