# ClassicalBookNFT Smart Contract Project

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

# 部署
hh deploy
Contract deployed to address: 0xd15294F1D0132ed5C46e3cf568CFfc717fC583F4

# verify
hh verify 0xd15294F1D0132ed5C46e3cf568CFfc717fC583F4

Nothing to compile
No need to generate any newer typings.
Successfully submitted source code for contract
contracts/ClassicalBookNFT.sol:ClassicalBookNFT at 0xd15294F1D0132ed5C46e3cf568CFfc717fC583F4
for verification on the block explorer. Waiting for verification result...

Successfully verified contract ClassicalBookNFT on Etherscan.
https://rinkeby.etherscan.io/address/0xd15294F1D0132ed5C46e3cf568CFfc717fC583F4#code
```

## 报错

```shell
# 报错 case 1
Nothing to compile
No need to generate any newer typings.
Error in plugin @nomiclabs/hardhat-etherscan: Failed to obtain list of solc versions. Reason: getaddrinfo ENOTFOUND solc-bin.ethereum.org

# 报错 case 2
Nothing to compile
No need to generate any newer typings.
Error in plugin @nomiclabs/hardhat-etherscan: Failed to send contract verification request.
Endpoint URL: https://api-rinkeby.etherscan.io/api
Reason: read ECONNRESET

# 报错 case 3
An unexpected error occurred:

ConnectTimeoutError: Connect Timeout Error
    at onConnectTimeout (/Users/sh00460ml/workspace/github/booknft-ink/booknft-ink-contract/node_modules/undici/lib/core/connect.js:131:24)
    at /Users/sh00460ml/workspace/github/booknft-ink/booknft-ink-contract/node_modules/undici/lib/core/connect.js:78:46
    at Immediate._onImmediate (/Users/sh00460ml/workspace/github/booknft-ink/booknft-ink-contract/node_modules/undici/lib/core/connect.js:119:9)
    at processImmediate (node:internal/timers:466:21) {
  code: 'UND_ERR_CONNECT_TIMEOUT'
}

# 报错 case 4
An unexpected error occurred:

Error: getaddrinfo ENOTFOUND eth-rinkeby.alchemyapi.io
    at GetAddrInfoReqWrap.onlookup [as oncomplete] (node:dns:71:26) {
  errno: -3008,
  code: 'ENOTFOUND',
  syscall: 'getaddrinfo',
  hostname: 'eth-rinkeby.alchemyapi.io'
}
```
