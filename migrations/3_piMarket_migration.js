const PiMarket = artifacts.require("piMarket");
require("dotenv").config();

module.exports = function (deployer) {
  deployer.deploy(PiMarket, process.env.FEE_ADDRESS);
};
