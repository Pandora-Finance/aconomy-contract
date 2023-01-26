# Aconomy Contracts

**Aconomy** is a decentralized NFT Marketplace for illiquid real-world asset classes to leverage all the monetary benfits that gets unlocked when the assets are brought on-chain in the form of **PiNFTs**.

**PiNFTs** are special kind of NFTs which possess underlying value in the form of ERC20 tokens(stable coins).

```text
PiNFT
  =
Asset NFT
  +
Underlying Value (ERC20 tokens)
```

## Features

- Mint asset NFT
- Add ERC 20 tokens(PiNFT)
- Redeem/burn PiNFTs
- Sell/Auction PiNFTs
- Buy/Bid on PiNFTs 
- Swap PiNFTs
- Pools
- TBD (coming many more)

## Installation

- Clone the repository
- Install the dependancies 

        npm install

## Compile Contracts

- Run the truffle compilation 

        truffle compile --all
        
## Test Contracts

### Truffle Tests

- Run the local truffle develpment environment and run the test cases within the environment

        truffle develop
        test
    
### Foundry Tests
- Run the following commands to compile contracts and run tests

        forge build
        forge test


## Deploy contracts to the BSC testnet

- Create a .env file storing a metamask private key and bscscan api(To verify contracts after deployment)
- the .env stucture should be as follows:

        PK=<Private Key>
        BSC_API=<API key>
        FEE_ADDRESS=<Fee Receiving Address>

- Then run the truffle migration command

        truffle migrate --reset --network bscTestnet







