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
Contract deployed to address: 0x1a9D8d59592311CD424FC4C22a1AACd28F1D0C9B

# verify
hh verify 0x1a9D8d59592311CD424FC4C22a1AACd28F1D0C9B

Nothing to compile
No need to generate any newer typings.
Successfully submitted source code for contract
contracts/ClassicalNFT.sol:ClassicalNFT at 0x1a9D8d59592311CD424FC4C22a1AACd28F1D0C9B
for verification on the block explorer. Waiting for verification result...

Successfully verified contract ClassicalNFT on Etherscan.
https://goerli.etherscan.io/address/0x1a9D8d59592311CD424FC4C22a1AACd28F1D0C9B#code
```

# UT Case

如果你需要在 localhost 跑 UT 测试，需要先启动本地节点

```shell
hh node
```

跑全部 case

```shell
hh test --network localhost
```

在本地 node 环境跑签名 case

```shell
hh test --grep 'sign message' --network localhost
```
