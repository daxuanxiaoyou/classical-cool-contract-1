import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
require('dotenv').config();
require('./scripts/deploy.js');

const { ALCHEMY_API_URL, ACCOUNT_PRIVATE_KEY, ETHERSCAN_API_KEY } = process.env;

// verify时报错的话，设置proxy
// see https://github.com/NomicFoundation/hardhat/issues/2684
// const proxyUrl = 'http://127.0.0.1:1087';
// const { ProxyAgent, setGlobalDispatcher } = require('undici');
// const proxyAgent = new ProxyAgent(proxyUrl);
// setGlobalDispatcher(proxyAgent);
// --- end ---

const config: HardhatUserConfig = {
  solidity: '0.8.1',
  defaultNetwork: 'goerli',
  networks: {
    hardhat: {},
    goerli: {
      url: ALCHEMY_API_URL,
      accounts: [`0x${ACCOUNT_PRIVATE_KEY}`],
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};

export default config;
