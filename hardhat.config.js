require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
require('solidity-coverage')
require("hardhat-gas-reporter");
require('dotenv').config()

require("solidity-docgen");

// import 'solidity-docgen';

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
    },
    arbitrum: {
      url: "https://arb1.arbitrum.io/rpc",  // Arbitrum One RPC URL
      accounts: [process.env.PK], // Use your private key from .env or directly
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org/",  // BNB Mainnet RPC URL
      accounts: [process.env.PK],  // Use your private key from the .env file
    },
    sepolia: {
      url: "https://sepolia.infura.io/v3/9a5b274c0d3542cf9b79260a741c06ef", 
      accounts: [process.env.PK],       
      chainId: 11155111                 
    }
  },
  gasReporter: {
    currency: 'CHF',
    gasPrice: 21
  },
  etherscan: {
    apiKey: {
      arbitrumGoerli: `${process.env.ARBISCAN}`,
      polygonMumbai : `${process.env.MATICSCAN}`,
      bsc: `${process.env.BSCSCAN}`,
      arbitrumOne: `${process.env.arbitrum}`,
      sepolia: `${process.env.SEPOLIASCAN}`,
    }
  }
};
