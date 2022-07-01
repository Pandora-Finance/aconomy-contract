const PiMarket = artifacts.require("piMarket");

module.exports = function (deployer) {
  deployer.deploy(PiMarket);
};
