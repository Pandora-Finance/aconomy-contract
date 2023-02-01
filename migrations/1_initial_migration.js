const attestationRegistry = artifacts.require("AttestationRegistry");
const attestationServices = artifacts.require("AttestationServices");
const poolRegistry = artifacts.require("poolRegistry");
const libPool = artifacts.require("LibPool")
const libCalc = artifacts.require("LibCalculations")
const aconomyFee = artifacts.require("AconomyFee")
const lendingToken = artifacts.require("lendingToken")
const accountStatus = artifacts.require("accountStatus")

module.exports = async function (deployer,network, accounts) {
  await deployer.deploy(aconomyFee);
  var aconomyfee = await aconomyFee.deployed();
   await deployer.deploy(accountStatus)
   var accountstatus = await accountStatus.deployed()
  await deployer.deploy(attestationRegistry)
  var attestRegistry = await attestationRegistry.deployed();

  await deployer.deploy(attestationServices, attestRegistry.address)
  var attestServices =await attestationServices.deployed()


  await deployer.deploy(libCalc);
  await deployer.link(libCalc, [libPool]);

  await deployer.deploy(libPool);
 
  await deployer.link(libPool, [poolRegistry]);

  await deployer.deploy(poolRegistry, attestServices.address,aconomyfee.address,accountstatus.address)

   await deployer.deploy(lendingToken, 10000000)

};
