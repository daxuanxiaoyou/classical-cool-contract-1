# ClassicalNFT Smart Contract Project

> 典籍NFT

## 为了节省时间，安装 hh 命令

> hh 代替 npx hardhat

```shell
# 安装 hh
npm install --global hardhat-shorthand

# 安装自动完成提示功能
hardhat-completion install
```

## 开始

```shell
# clean
hh clean

# 编译合约
hh compile

Generating typings for: 17 artifacts in dir: typechain-types for target: ethers-v5
Successfully generated 46 typings!
Compiled 17 Solidity files successfully

# 部署
hh deploy
Contract deployed to address: 0x8311D4CdF4EEB244936c2404d13B0EB9d02d5C67

# verify
hh verify 0x8311D4CdF4EEB244936c2404d13B0EB9d02d5C67

Nothing to compile
No need to generate any newer typings.
Successfully submitted source code for contract
contracts/ClassicalNFT.sol:ClassicalNFT at 0x8311D4CdF4EEB244936c2404d13B0EB9d02d5C67
for verification on the block explorer. Waiting for verification result...

Successfully verified contract ClassicalNFT on Etherscan.
https://goerli.etherscan.io/address/0x8311D4CdF4EEB244936c2404d13B0EB9d02d5C67#code
```
