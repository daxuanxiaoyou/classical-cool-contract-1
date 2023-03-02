const { ethers } = require('ethers')
// const { network } = require('hardhat')
const { getContractAt } = require('@nomiclabs/hardhat-ethers/internal/helpers')

// Helper method for fetching environment variables from .env
function getEnvVariable(key, defaultValue) {
  if (process.env[key]) {
    return process.env[key]
  }
  if (!defaultValue) {
    throw `${key} is not defined and no default value was provided`
  }
  return defaultValue
}

// Helper method for fetching a connection provider to the Ethereum network
function getProvider() {
  let alchemyKey = ''
  if (getNetwork() === 'maticmum') {
    alchemyKey = getEnvVariable('MATICMUM_ALCHEMY_API_KEY')
  } else {
    alchemyKey = getEnvVariable('GOERLI_ALCHEMY_API_KEY')
  }
  return new ethers.providers.AlchemyProvider(
    (network = getNetwork()),
    alchemyKey,
  )
}

function getNetwork() {
  return getEnvVariable('NETWORK')
}

// Helper method for fetching a wallet account using an environment variable for the PK
function getAccount() {
  return new ethers.Wallet(getEnvVariable('ACCOUNT_PRIVATE_KEY'), getProvider())
}

// Helper method for fetching a contract instance at a given address
function getContract(contractName, hre) {
  const account = getAccount()
  return getContractAt(
    hre,
    contractName,
    getEnvVariable('CONTRACT_ADDRESS'),
    account,
  )
}

module.exports = {
  getEnvVariable,
  getProvider,
  getAccount,
  getContract,
  getNetwork,
}
