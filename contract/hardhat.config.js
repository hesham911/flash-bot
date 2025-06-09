require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();

const PRIVATE_KEY = process.env.PRIVATE_KEY || "0x0000000000000000000000000000000000000000000000000000000000000000";
const RPC_URL = process.env.RPC_URL || "https://polygon-rpc.com";
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY || "";

module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      },
      viaIR: true
    }
  },
  networks: {
    hardhat: {
      chainId: 1337,
      forking: {
        url: RPC_URL,
        blockNumber: 50000000
      }
    },
    polygon: {
      url: RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 137,
      gasPrice: 35000000000,
      gas: 2100000
    }
  },
  etherscan: {
    apiKey: {
      polygon: POLYGONSCAN_API_KEY
    }
  }
};
