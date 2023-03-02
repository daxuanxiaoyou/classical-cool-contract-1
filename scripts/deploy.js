const { task } = require('hardhat/config')
const { getAccount } = require('./helpers')

task('deploy', 'Deploys the ClassicalNFT.sol contract').setAction(
  async function (taskArguments, hre) {
    console.log(hre.network)
    const nftContractFactory = await hre.ethers.getContractFactory(
      'ClassicalNFT',
      getAccount(),
    )

    const _treasuryAddress = '0xd332DCa2B5681Cc5e7E69C44B00182EbA2A6dcF5'
    const _publicGoodAddress = '0xb86EB6f8a39Db243a9ae544F180ef958dBA4e8b4'
    const nft = await nftContractFactory.deploy(
      _treasuryAddress,
      _publicGoodAddress,
      300,
    )
    console.log(`Contract deployed to address: ${nft.address}`)
  },
)
