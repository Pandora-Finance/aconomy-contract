const attestationRegistry = artifacts.require("AttestationRegistry");
const attestationServices = artifacts.require("AttestationServices");
const poolRegistry = artifacts.require("poolRegistry");
const libPool = artifacts.require("LibPool")
const libCalc = artifacts.require("LibCalculations")
const aconomyfee = artifacts.require("AconomyFee")
const ERC20 = artifacts.require("ERC20")

module.exports = async function (deployer,network, accounts) {
  await deployer.deploy(aconomyfee);
  

  await deployer.deploy(attestationRegistry)
  var attestRegistry = await attestationRegistry.deployed();

  await deployer.deploy(attestationServices, attestRegistry.address)
  var attestServices =await attestationServices.deployed()


  await deployer.deploy(libCalc);
  await deployer.link(libCalc, [libPool]);

  await deployer.deploy(libPool);
 
  await deployer.link(libPool, [poolRegistry]);

  await deployer.deploy(poolRegistry, attestServices.address,accounts[0] )

  // await deployer.deploy(ER)
};
