require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
require('solidity-coverage')
require("hardhat-gas-reporter");
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.11",
  networks: {
    maticMumbai: {
      url: `https://polygon-mumbai-bor.publicnode.com`,
      accounts: [process.env.PK]
    },
    bscTestnet: {
      url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
      accounts: [process.env.PK]
    },
    arbitrum_goerli: {
      url: `https://goerli-rollup.arbitrum.io/rpc`,
      accounts: [process.env.PK]
    }
  },
  gasReporter: {
    currency: 'CHF',
    gasPrice: 21
  },
  etherscan: {
    apiKey: {
      arbitrumGoerli: `${process.env.ARBISCAN}`,
      polygonMumbai : `${process.env.MATICSCAN}`
    }
  }
};
