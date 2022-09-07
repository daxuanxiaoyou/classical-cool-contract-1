const { task } = require('hardhat/config');
const { getAccount, getNetwork } = require('./helpers');

task('deploy', 'Deploys the ClassicalBookNFT.sol contract').setAction(
  async function (taskArguments, hre) {
    const nftContractFactory = await hre.ethers.getContractFactory(
      'ClassicalBookNFT',
      getAccount()
    );
    const nft = await nftContractFactory.deploy();
    console.log(`Contract deployed to address: ${nft.address}`);
  }
);
