import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "dotenv/config";
import "hardhat-deploy";
import "@nomiclabs/hardhat-ethers";
import "hardhat-deploy-ethers";
import "hardhat-gas-reporter";
import "@typechain/hardhat";
import "solidity-coverage";
require("dotenv").config();
require("./scripts/deploy.js");
const { getAccount, getNetwork } = require("./scripts/helpers");
const {
  GOERLI_ALCHEMY_API_URL,
  MATICMUM_ALCHEMY_API_URL,
  ACCOUNT_PRIVATE_KEY,
  ETHERSCAN_API_KEY,
  POLYGONSCAN_API_KEY,
} = process.env;

// verify时报错的话，设置proxy
// see https://github.com/NomicFoundation/hardhat/issues/2684
// const proxyUrl = 'http://127.0.0.1:1087';
// const { ProxyAgent, setGlobalDispatcher } = require('undici');
// const proxyAgent = new ProxyAgent(proxyUrl);
// setGlobalDispatcher(proxyAgent);
// --- end ---

const config: HardhatUserConfig = {
  // solidity: "0.8.7",
  defaultNetwork: "goerli",
  networks: {
    hardhat: {
      chainId: 31337,
      allowUnlimitedContractSize: true,
    },
    localhost: {
      chainId: 31337,
      allowUnlimitedContractSize: true,
    },
    goerli: {
      url: GOERLI_ALCHEMY_API_URL,
      accounts: [`0x${ACCOUNT_PRIVATE_KEY}`],
    },
    maticmum: {
      url: MATICMUM_ALCHEMY_API_URL,
      // url: "https://matic-mumbai.chainstacklabs.com",
      accounts: [`0x${ACCOUNT_PRIVATE_KEY}`],
      chainId: 80001,
    },
  },
  etherscan: {
    apiKey:
      getNetwork() === "maticmum" ? POLYGONSCAN_API_KEY : ETHERSCAN_API_KEY,
  },
  solidity: {
    compilers: [
      {
        version: "0.8.7",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
};

export default config;
