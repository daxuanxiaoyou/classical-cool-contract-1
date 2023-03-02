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
Contract deployed to address: 0xdE30ED5535c7f1918136E0e1C29ee7421154C99A

# verify
hh verify 0xdE30ED5535c7f1918136E0e1C29ee7421154C99A

Nothing to compile
No need to generate any newer typings.
Successfully submitted source code for contract
contracts/ClassicalNFT.sol:ClassicalNFT at 0xdE30ED5535c7f1918136E0e1C29ee7421154C99A
for verification on the block explorer. Waiting for verification result...

Successfully verified contract ClassicalNFT on Etherscan.
https://goerli.etherscan.io/address/0xdE30ED5535c7f1918136E0e1C29ee7421154C99A#code
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
