const attestationRegistry = artifacts.require("AttestationRegistry");
const attestationServices = artifacts.require("AttestationServices");
const poolRegistry = artifacts.require("poolRegistry");
const libPool = artifacts.require("LibPool")
const libCalc = artifacts.require("LibCalculations")
const aconomyFee = artifacts.require("AconomyFee")
const lendingToken = artifacts.require("mintToken")
const FundingPool = artifacts.require("FundingPool")
const poolAddress = artifacts.require("poolAddress")
const NftLendingBorrowing = artifacts.require("NFTlendingBorrowing");
const CollectionFactory = artifacts.require("CollectionFactory")
const CollectionMethods = artifacts.require("CollectionMethods")
const LibCollection = artifacts.require("LibCollection")


module.exports = async function (deployer) {


  await deployer.deploy(aconomyFee);
  var aconomyfee = await aconomyFee.deployed();

  await deployer.deploy(attestationRegistry)
  var attestRegistry = await attestationRegistry.deployed();

  await deployer.deploy(attestationServices, attestRegistry.address)
  var attestServices = await attestationServices.deployed()


  await deployer.deploy(libCalc);
  await deployer.link(libCalc, [libPool, FundingPool]);

  await deployer.deploy(libPool);

  await deployer.deploy(LibCollection);
  await deployer.link(LibCollection, [CollectionFactory]);

  await deployer.deploy(CollectionMethods);
  var CollectionMethod = await CollectionMethods.deployed();

  await deployer.deploy(CollectionFactory, CollectionMethod.address);
  var collectionFactory = await CollectionFactory.deployed();



  await deployer.deploy(FundingPool);
  var fundingPool = await FundingPool.deployed();

  await deployer.link(libPool, [poolRegistry]);

  await deployer.deploy(poolRegistry, attestServices.address, aconomyfee.address, fundingPool.address)
  var poolRegis = await poolRegistry.deployed()

  await deployer.link(libCalc, [poolAddress, NftLendingBorrowing]);

  await deployer.deploy(poolAddress, poolRegis.address, aconomyfee.address)

  await deployer.deploy(NftLendingBorrowing, aconomyfee.address)


  await deployer.deploy(lendingToken, 100000000000)


};