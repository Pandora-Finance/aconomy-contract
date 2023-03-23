const PiMarket = artifacts.require("piMarket");
// require("dotenv").config();

module.exports = async function (deployer) {
  await deployer.deploy(PiMarket, "0x7852ef7e88f74138755883fee684abc50af3341e");
  let market = await PiMarket.deployed();
  console.log("market:", market.address);
};