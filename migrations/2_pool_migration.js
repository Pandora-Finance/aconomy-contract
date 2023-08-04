const { deployProxy } = require("@openzeppelin/truffle-upgrades");

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
const BPBDTL = artifacts.require("BokkyPooBahsDateTimeLibrary")
const piNFTMethods = artifacts.require("piNFTMethods");
const LibPoolAddress = artifacts.require("LibPoolAddress");
const LibNFTLendingBorrowing = artifacts.require("LibNFTLendingBorrowing");
require('dotenv').config()

let walletAddress = process.env.WALLET_ADDRESS


module.exports = async function (deployer) {


  // await deployer.deploy(aconomyFee);
  // var aconomyfee = await aconomyFee.deployed();

  // await aconomyfee.setAconomyPoolFee(50)
  // await aconomyfee.setAconomyPiMarketFee(50)
  // await aconomyfee.setAconomyNFTLendBorrowFee(50)

  // await deployer.deploy(attestationRegistry)
  // var attestRegistry = await attestationRegistry.deployed();

  // await deployer.deploy(attestationServices, attestRegistry.address)
  // var attestServices = await attestationServices.deployed()

  // var piNftMethods = await deployProxy(piNFTMethods, ["0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"], {
  //   initializer: "initialize",
  //   kind: "uups",
  // });


  // await deployer.deploy(LibCollection);
  // await deployer.link(LibCollection, [CollectionFactory]);

  // await deployer.deploy(CollectionMethods);
  // var CollectionMethod = await CollectionMethods.deployed();

  // var collectionFactory = await deployProxy(CollectionFactory, [CollectionMethod.address, piNftMethods.address], {
  //   initializer: "initialize",
  //   kind: "uups",
  //   unsafeAllow: ["external-library-linking"],
  // });

  // await CollectionMethod.initialize(walletAddress, collectionFactory.address, "xyz", "xyz")

  // await deployer.deploy(libCalc);
  // await deployer.link(libCalc, [libPool, FundingPool, LibNFTLendingBorrowing]);

  // await deployer.deploy(LibNFTLendingBorrowing);
  // await deployer.link(LibNFTLendingBorrowing, [NftLendingBorrowing]);

  // await deployer.deploy(libPool);

  // await deployer.deploy(FundingPool);
  // var fundingPool = await FundingPool.deployed();

  // await deployer.link(libPool, [poolRegistry]);

  // var poolRegis = await deployProxy(poolRegistry, [attestServices.address, aconomyfee.address, fundingPool.address], {
  //   initializer: "initialize",
  //   kind: "uups",
  //   unsafeAllow: ["external-library-linking"],
  // });

  // await fundingPool.initialize(walletAddress, poolRegis.address)

  // await deployer.link(libCalc, [poolAddress, NftLendingBorrowing, LibPoolAddress]);

  // await deployer.deploy(BPBDTL);
  // await deployer.link(BPBDTL, [poolAddress]);

  // await deployer.deploy(LibPoolAddress);
  // await deployer.link(LibPoolAddress, [poolAddress]);

  // var pooladdress = await deployProxy(poolAddress, [poolRegis.address, aconomyfee.address], {
  //   initializer: "initialize",
  //   kind: "uups",
  //   unsafeAllow: ["external-library-linking"],
  // });

  // var lending = await deployProxy(NftLendingBorrowing, [aconomyfee.address], {
  //   initializer: "initialize",
  //   kind: "uups",
  //   unsafeAllow: ["external-library-linking"],
  // });

  // console.log("AconomyFee : ", aconomyfee.address)
  // console.log("AttestationRegistry : ", attestRegistry.address)
  // console.log("AttestationServices : ", attestServices.address)
  // console.log("CollectionMethods : ", CollectionMethod.address)
  // console.log("CollectionFactory : ", collectionFactory.address)
  // console.log("FundingPool : ", fundingPool.address)
  // console.log("poolRegistry : ", poolRegis.address)
  // console.log("poolAddress : ", pooladdress.address)
  // console.log("NFTlendingBorrowing : ", lending.address)


   await deployer.deploy(lendingToken, 100000000000)


};