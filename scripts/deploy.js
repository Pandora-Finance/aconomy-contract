// // We require the Hardhat Runtime Environment explicitly here. This is optional
// // but useful for running the script in a standalone fashion through `node <script>`.
// //
// // You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// // will compile your contracts, add the Hardhat Runtime Environment's members to the
// // global scope, and execute the script.
// const { upgrades } = require("hardhat");
// const hre = require("hardhat");
// require('dotenv').config()

// let walletAddress = process.env.WALLET_ADDRESS

// async function main() {
//   const aconomyfee = await hre.ethers.deployContract("AconomyFee", []);
//   await aconomyfee.waitForDeployment();

//   await aconomyfee.setAconomyPoolFee(50)
//   await aconomyfee.setAconomyPiMarketFee(50)
//   await aconomyfee.setAconomyNFTLendBorrowFee(50)

//   const attestRegistry = await hre.ethers.deployContract("AttestationRegistry", []);
//   await attestRegistry.waitForDeployment();

//   const attestServices = await hre.ethers.deployContract("AttestationServices", [attestRegistry.getAddress()]);
//   await attestServices.waitForDeployment();

//   const LibShare = await hre.ethers.deployContract("LibShare", []);
//   await LibShare.waitForDeployment();

//   const LibPiNFTMethods = await hre.ethers.deployContract("LibPiNFTMethods", []);
//   await LibPiNFTMethods.waitForDeployment();

//   const piNFTMethods = await hre.ethers.getContractFactory("piNFTMethods", {
//     libraries: {
//       LibShare: await LibShare.getAddress(),
//       LibPiNFTMethods: await LibPiNFTMethods.getAddress(),
//     }
//   })
//   const piNftMethods = await upgrades.deployProxy(piNFTMethods, ["0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"], {
//     initializer: "initialize",
//     kind: "uups",
//     unsafeAllow: ["external-library-linking"],
//   })

//   const LibCollection = await hre.ethers.deployContract("LibCollection", []);
//   await LibCollection.waitForDeployment();

//   const CollectionMethods = await hre.ethers.deployContract("CollectionMethods", []);
//   let CollectionMethod = await CollectionMethods.waitForDeployment();

//   const CollectionFactory = await hre.ethers.getContractFactory("CollectionFactory", {
//     libraries: {
//       LibCollection: await LibCollection.getAddress()
//     }
//   })
//   const collectionFactory = await upgrades.deployProxy(CollectionFactory, [await CollectionMethod.getAddress(), await piNftMethods.getAddress()], {
//     initializer: "initialize",
//     kind: "uups",
//     unsafeAllow: ["external-library-linking"],
//   })

//   await CollectionMethods.initialize(walletAddress, await collectionFactory.getAddress(), "xyz", "xyz")

//   const LibCalculations = await hre.ethers.deployContract("LibCalculations", []);
//   await LibCalculations.waitForDeployment();

//   const LibNFTLendingBorrowing = await hre.ethers.deployContract("LibNFTLendingBorrowing", []);
//   await LibNFTLendingBorrowing.waitForDeployment();

//   const LibPool = await hre.ethers.deployContract("LibPool", []);
//   await LibPool.waitForDeployment();

//   const FundingPool = await hre.ethers.getContractFactory("FundingPool", {
//     libraries: {
//       LibCalculations: await LibCalculations.getAddress()
//     }
//   })
//   const fundingPool = await FundingPool.deploy();
//   await fundingPool.waitForDeployment();

//   const poolRegistry = await hre.ethers.getContractFactory("poolRegistry", {
//     libraries: {
//       LibPool: await LibPool.getAddress()
//     }
//   })
//   const poolRegis = await upgrades.deployProxy(poolRegistry, [await attestServices.getAddress(), await aconomyfee.getAddress(), await fundingPool.getAddress()], {
//     initializer: "initialize",
//     kind: "uups",
//     unsafeAllow: ["external-library-linking"],
//   })

//   await fundingPool.initialize(walletAddress, await poolRegis.getAddress())

//   const BokkyPooBahsDateTimeLibrary = await hre.ethers.deployContract("BokkyPooBahsDateTimeLibrary", []);
//   await BokkyPooBahsDateTimeLibrary.waitForDeployment();

//   const LibPoolAddress = await hre.ethers.getContractFactory("LibPoolAddress", {
//     libraries: {
//       LibCalculations: await LibCalculations.getAddress()
//     }
//   })
//   const libPoolAddress = await LibPoolAddress.deploy();
//   await libPoolAddress.waitForDeployment();

//   const poolAddress = await hre.ethers.getContractFactory("poolAddress", {
//     libraries: {
//       LibCalculations: await LibCalculations.getAddress(),
//       LibPoolAddress: await libPoolAddress.getAddress()
//     }
//   })
//   const pooladdress = await upgrades.deployProxy(poolAddress, [await poolRegis.getAddress(), await aconomyfee.getAddress()], {
//     initializer: "initialize",
//     kind: "uups",
//     unsafeAllow: ["external-library-linking"],
//   })

//   const NFTlendingBorrowing = await hre.ethers.getContractFactory("NFTlendingBorrowing", {
//     libraries: {
//       LibCalculations: await LibCalculations.getAddress(),
//       LibNFTLendingBorrowing: await LibNFTLendingBorrowing.getAddress()
//     }
//   })
//   const lending = await upgrades.deployProxy(NFTlendingBorrowing, [await aconomyfee.getAddress()], {
//     initializer: "initialize",
//     kind: "uups",
//     unsafeAllow: ["external-library-linking"],
//   })

//   const mintToken = await hre.ethers.deployContract("mintToken", ["100000000000"]);
//   let token = await mintToken.waitForDeployment();

//   const piNFT = await hre.ethers.getContractFactory("piNFT")
//   const pi = await upgrades.deployProxy(piNFT, ["Aconomy", "ACO", await piNftMethods.getAddress(), "0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"], {
//     initializer: "initialize",
//     kind: "uups"
//   })

//   const LibMarket = await hre.ethers.deployContract("LibMarket", []);
//   await LibMarket.waitForDeployment();

//   const piMarket = await hre.ethers.getContractFactory("piMarket", {
//     libraries: {
//       LibMarket: await LibMarket.getAddress()
//     }
//   })
//   const market = await upgrades.deployProxy(piMarket, [await aconomyfee.getAddress(), await collectionFactory.getAddress(), await piNftMethods.getAddress()], {
//     initializer: "initialize",
//     kind: "uups",
//     unsafeAllow: ["external-library-linking"],
//   })

//   await piNftMethods.setPiMarket(market.getAddress());

//   const validateNFT = await hre.ethers.getContractFactory("validatedNFT")

//     validatedNFT = await upgrades.deployProxy(
//       validateNFT,
//       [await piNftMethods.getAddress()],
//       {
//         initializer: "initialize",
//         kind: "uups",
//       }
//     );

//   // console.log("AconomyFee : ", await aconomyfee.getAddress())
//   // console.log("AttestationRegistry : ", await attestRegistry.getAddress())
//   // console.log("AttestationServices : ", await attestServices.getAddress())
//   // console.log("CollectionMethods : ", await CollectionMethod.getAddress())
//   // console.log("CollectionFactory : ", await collectionFactory.getAddress())
//   // console.log("FundingPool : ", await fundingPool.getAddress())
//   // console.log("poolRegistry : ", await poolRegis.getAddress())
//   // console.log("poolAddress : ", await pooladdress.getAddress())
//   // console.log("NFTlendingBorrowing : ", await lending.getAddress())
//   // console.log("mintToken : ", await token.getAddress())
//   // console.log("piNFT: ", await pi.getAddress());
//   // console.log("piNFTMethods", await piNftMethods.getAddress());
//   // console.log("piMarket:", await market.getAddress());
//   console.log("validatedNFT:", await validatedNFT.getAddress());



// //   const lock = await hre.ethers.deployContract("Lock", [unlockTime], {
// //     value: lockedAmount,
// //   });

// //   await lock.waitForDeployment();

// //   console.log(
// //     `Lock with ${ethers.formatEther(
// //       lockedAmount
// //     )}ETH and unlock timestamp ${unlockTime} deployed to ${lock.target}`
// //   );
// }

// // We recommend this pattern to be able to use async/await everywhere
// // and properly handle errors.
// main().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });

// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { upgrades } = require("hardhat");
const hre = require("hardhat");
require('dotenv').config()

let walletAddress = process.env.WALLET_ADDRESS

async function main() {
  const aconomyfee = await hre.ethers.deployContract("AconomyFee", []);
  await aconomyfee.waitForDeployment();

  await aconomyfee.setAconomyPoolFee(50)
  await aconomyfee.setAconomyPiMarketFee(50)
  await aconomyfee.setAconomyNFTLendBorrowFee(50)

  // const attestRegistry = await hre.ethers.deployContract("AttestationRegistry", []);
  // await attestRegistry.waitForDeployment();

  // const attestServices = await hre.ethers.deployContract("AttestationServices", [attestRegistry.getAddress()]);
  // await attestServices.waitForDeployment();

  const LibShare = await hre.ethers.deployContract("LibShare", []);
  await LibShare.waitForDeployment();

  const piNFTMethods = await hre.ethers.getContractFactory("piNFTMethods", {
    libraries: {
      LibShare: await LibShare.getAddress()
    }
  })
  const piNftMethods = await upgrades.deployProxy(piNFTMethods, ["0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"], {
    initializer: "initialize",
    kind: "uups",
    unsafeAllow: ["external-library-linking"],
  })

  const LibCollection = await hre.ethers.deployContract("LibCollection", []);
  await LibCollection.waitForDeployment();

  const CollectionMethods = await hre.ethers.deployContract("CollectionMethods", []);
  let CollectionMethod = await CollectionMethods.waitForDeployment();

  const CollectionFactory = await hre.ethers.getContractFactory("CollectionFactory", {
    libraries: {
      LibCollection: await LibCollection.getAddress()
    }
  })
  const collectionFactory = await upgrades.deployProxy(CollectionFactory, [await CollectionMethod.getAddress(), await piNftMethods.getAddress()], {
    initializer: "initialize",
    kind: "uups",
    unsafeAllow: ["external-library-linking"],
  })

  await CollectionMethods.initialize(walletAddress, await collectionFactory.getAddress(), "xyz", "xyz")

  const LibCalculations = await hre.ethers.deployContract("LibCalculations", []);
  await LibCalculations.waitForDeployment();

  const LibNFTLendingBorrowing = await hre.ethers.deployContract("LibNFTLendingBorrowing", []);
  await LibNFTLendingBorrowing.waitForDeployment();

  // const LibPool = await hre.ethers.deployContract("LibPool", []);
  // await LibPool.waitForDeployment();

  // const FundingPool = await hre.ethers.getContractFactory("FundingPool", {
  //   libraries: {
  //     LibCalculations: await LibCalculations.getAddress()
  //   }
  // })
  // const fundingPool = await FundingPool.deploy();
  // await fundingPool.waitForDeployment();

  // const poolRegistry = await hre.ethers.getContractFactory("poolRegistry", {
  //   libraries: {
  //     LibPool: await LibPool.getAddress()
  //   }
  // })
  // const poolRegis = await upgrades.deployProxy(poolRegistry, [await attestServices.getAddress(), await aconomyfee.getAddress(), await fundingPool.getAddress()], {
  //   initializer: "initialize",
  //   kind: "uups",
  //   unsafeAllow: ["external-library-linking"],
  // })

  // await fundingPool.initialize(walletAddress, await poolRegis.getAddress())

  // const BokkyPooBahsDateTimeLibrary = await hre.ethers.deployContract("BokkyPooBahsDateTimeLibrary", []);
  // await BokkyPooBahsDateTimeLibrary.waitForDeployment();

  // const LibPoolAddress = await hre.ethers.getContractFactory("LibPoolAddress", {
  //   libraries: {
  //     LibCalculations: await LibCalculations.getAddress()
  //   }
  // })
  // const libPoolAddress = await LibPoolAddress.deploy();
  // await libPoolAddress.waitForDeployment();

  // const poolAddress = await hre.ethers.getContractFactory("poolAddress", {
  //   libraries: {
  //     LibCalculations: await LibCalculations.getAddress(),
  //     LibPoolAddress: await libPoolAddress.getAddress()
  //   }
  // })
  // const pooladdress = await upgrades.deployProxy(poolAddress, [await poolRegis.getAddress(), await aconomyfee.getAddress()], {
  //   initializer: "initialize",
  //   kind: "uups",
  //   unsafeAllow: ["external-library-linking"],
  // })

  const NFTlendingBorrowing = await hre.ethers.getContractFactory("NFTlendingBorrowing", {
    libraries: {
      LibCalculations: await LibCalculations.getAddress(),
      LibNFTLendingBorrowing: await LibNFTLendingBorrowing.getAddress()
    }
  })
  const lending = await upgrades.deployProxy(NFTlendingBorrowing, [await aconomyfee.getAddress()], {
    initializer: "initialize",
    kind: "uups",
    unsafeAllow: ["external-library-linking"],
  })

  // const mintToken = await hre.ethers.deployContract("mintToken", ["100000000000"]);
  // let token = await mintToken.waitForDeployment();

  const piNFT = await hre.ethers.getContractFactory("piNFT")
  const pi = await upgrades.deployProxy(piNFT, ["Aconomy", "ACO", await piNftMethods.getAddress(), "0xBf175FCC7086b4f9bd59d5EAE8eA67b8f940DE0d"], {
    initializer: "initialize",
    kind: "uups"
  })

  const LibMarket = await hre.ethers.deployContract("LibMarket", []);
  await LibMarket.waitForDeployment();

  const piMarket = await hre.ethers.getContractFactory("piMarket", {
    libraries: {
      LibMarket: await LibMarket.getAddress()
    }
  })
  const market = await upgrades.deployProxy(piMarket, [await aconomyfee.getAddress(), await collectionFactory.getAddress(), await piNftMethods.getAddress()], {
    initializer: "initialize",
    kind: "uups",
    unsafeAllow: ["external-library-linking"],
  })

  await piNftMethods.setPiMarket(market.getAddress());

  console.log("AconomyFee : ", await aconomyfee.getAddress())
  // console.log("AttestationRegistry : ", await attestRegistry.getAddress())
  // console.log("AttestationServices : ", await attestServices.getAddress())
  console.log("CollectionMethods : ", await CollectionMethod.getAddress())
  console.log("CollectionFactory : ", await collectionFactory.getAddress())
  // console.log("FundingPool : ", await fundingPool.getAddress())
  // console.log("poolRegistry : ", await poolRegis.getAddress())
  // console.log("poolAddress : ", await pooladdress.getAddress())
  console.log("NFTlendingBorrowing : ", await lending.getAddress())
  // console.log("mintToken : ", await token.getAddress())
  console.log("piNFT: ", await pi.getAddress());
  console.log("piNFTMethods", await piNftMethods.getAddress());
  console.log("piMarket:", await market.getAddress());



//   const lock = await hre.ethers.deployContract("Lock", [unlockTime], {
//     value: lockedAmount,
//   });

//   await lock.waitForDeployment();

//   console.log(
//     `Lock with ${ethers.formatEther(
//       lockedAmount
//     )}ETH and unlock timestamp ${unlockTime} deployed to ${lock.target}`
//   );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
