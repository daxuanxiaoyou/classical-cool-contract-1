import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { utils, Wallet } from "ethers";
import {
  concat,
  hashMessage,
  joinSignature,
  keccak256,
  toUtf8Bytes,
} from "ethers/lib/utils";
import { SigningKey } from "@ethersproject/signing-key";
import { serialize } from "@ethersproject/transactions";

// import { keccak256 } from "@ethersproject/keccak256";

describe("ClassicalNFT", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployClassicalNFTFixture() {
    const ONE_GWEI = 1_000_000_000;

    const ClassicalNFTedAmount = ONE_GWEI;

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const ClassicalNFT = await ethers.getContractFactory("ClassicalNFT");
    const classicalNFT = await ClassicalNFT.deploy();
    await classicalNFT.deployed();
    // const classicalNFT = await ClassicalNFT.deploy();

    return { classicalNFT, ClassicalNFTedAmount, owner, otherAccount };
  }

  /**
   * 长度太大了，达到了 193，导致签名失败，底层实现比这个要复杂的多。
   * @param message
   * @param privateKey
   * @returns
   */
  async function signMsgFromString(message: string, privateKey: string) {
    const prefix = "\x19Ethereum Signed Message:\n20";
    const messageHash = keccak256(Buffer.from(prefix + message));
    const privateKeyBuffer = Buffer.from(privateKey, "hex");
    const signingKey = new utils.SigningKey(privateKeyBuffer);
    const signature = signingKey.signDigest(messageHash);
    const { r, s, v } = utils.splitSignature(signature);
    const signatureBytes = Buffer.concat([
      Buffer.from(r),
      Buffer.from(s),
      Buffer.from([v]),
    ]);
    const signedMessage = Buffer.concat([
      Buffer.from(prefix),
      Buffer.from(message),
      signatureBytes,
    ]);
    // const signedMessageHex = signedMessage.toString("hex");
    const signedMessageArrayify = utils.arrayify(signedMessage);
    console.log(
      "signedMessageArrayify:",
      signedMessageArrayify,
      signedMessageArrayify.length
    );
    return signedMessageArrayify;
  }

  /**
   * 因为地址类型在 js 端是 42 为，减去 0x 2位，剩余 40 位（ js 端是按照4位算1位，所以算出来 length 是 40），在 solidity 端却是按照 8 bit 一位，所以 lenght 是 20 位。
   * 两端的 length 计算逻辑不一样，所以结果不一样，就需要在 js 端通过 keccak256 算法将地址 address 转化为 256 位，也就是length 32（256/8）
   * 然后在 solidity 端验签的时候，需要在 prefix 里面一样通过 keccak256 转化为 32 的 message。
   * 这样在 js 和 dolidity 的 prefix 都是 32,解析就一致了。
   * @param msg
   * @param privateKey
   * @returns
   */
  async function signMsgFromAddress(msg: string, privateKey: string) {
    const signingKey = new SigningKey(privateKey);
    const message = ethers.utils.solidityKeccak256(["address"], [msg]);
    const data = ethers.utils.arrayify(message);
    const hashData = hashMessage(data);
    const digestData = signingKey.signDigest(hashData);
    const signature = joinSignature(digestData);

    console.log("data:", data);
    console.log("data length:", data.length);
    console.log("hashData:", hashData);
    console.log("hashData length:", hashData.length);
    console.log("digestData:", digestData);
    console.log("signature:", signature);
    console.log("signature length:", signature.length);

    return signature;
  }

  /**
   *
   * @param msg
   * @param privateKey
   * @returns
   */
  async function signMsgFrom20(msg: string, privateKey: string) {
    const signingKey = new SigningKey(privateKey);
    console.log("----------------------:::", msg, msg.length);

    const messagePrefix = "\x19Ethereum Signed Message:\n20";
    let bytesMsg: Uint8Array = Uint8Array.from([]);
    if (typeof msg === "string") {
      bytesMsg = toUtf8Bytes(msg);
    }

    console.log(bytesMsg, "-----bytesMsg-----", bytesMsg.length);

    const hashStr = keccak256(concat([toUtf8Bytes(messagePrefix), bytesMsg]));

    console.log(hashStr, "-----hashStr-----", hashStr.length);

    const signature = joinSignature(
      // signingKey.signDigest(hashMessage("1"))
      signingKey.signDigest(hashStr)
    );
    console.log(signature);
    return signature;
  }

  async function signMsgFromWallet(msg: string, privateKey: string) {
    const walletPrivateKey = new Wallet(privateKey);
    const signedMsg = await walletPrivateKey.signMessage(msg);

    console.log(walletPrivateKey.getAddress());
    console.log("signedMsg:", signedMsg);
    return signedMsg;
  }
  // async function recoverSignedMsg(signedMessage: string) {
  //   const recoveredAddress = utils.recoverAddress(messageHash, signature);
  //   return recoveredAddress;
  // }

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      const { classicalNFT, owner } = await loadFixture(
        deployClassicalNFTFixture
      );

      await classicalNFT.setPublicKey(owner.address);
      const pk = await classicalNFT.getPublickey();

      expect(pk).to.equal(owner.address);
    });
    it("verify sign message", async function () {
      const { classicalNFT, owner } = await loadFixture(
        deployClassicalNFTFixture
      );
      await classicalNFT.setPublicKey(owner.address);

      const privateKey =
        "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
      const privateKeyNo0x =
        "ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

      // 1、------------------------全部自己实现的逻辑 ------------------------
      // const sigedMsg = signMsgFromString(
      //   "99999999999999999999999999999999", //普通 32 位字符
      //   privateKeyNo0x
      // );

      // 2、------------------------针对长度为 20 的普通字符做验证------------------------
      const sigedMsg = signMsgFrom20(
        "99999999999999999999", //普通 20 位字符
        privateKey
      );

      const verifyRtn = await classicalNFT._verify20(sigedMsg);

      // 对应的合约代码
      // // TODO:need use internal
      // function _verify20(bytes memory signature) public view returns (bool verified) {
      //   bytes memory prefix = "\x19Ethereum Signed Message:\n20";
      //   bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, '99999999999999999999'));
      //   address calculated_public_key = ECDSA.recover(prefixedHash, signature); // same： prefixedHash.recover(signature)
      //   console.log('---------------');
      //   console.logBytes(signature);
      //   console.log(signature.length);
      //   console.logBytes32(prefixedHash);
      //   console.log(prefixedHash.length);
      //   console.logAddress(calculated_public_key);

      //   return (calculated_public_key == public_key);
      // }

      // 3、------------------------针对 address 验证------------------------
      // const sigedMsg = signMsgFromAddress(
      //   owner.address, //msg.sender
      //   privateKey
      // );

      // const verifyRtn = await classicalNFT._verifyAddress(sigedMsg);
      // const verifyRtn = await classicalNFT._verify2(sigedMsg);

      // 对应的合约代码
      //   function _verifyAddress(bytes memory signature) public view returns (bool verified) {
      //     bytes memory prefix = "\x19Ethereum Signed Message:\n32";
      //     bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, keccak256( abi.encodePacked(msg.sender))));
      //     address calculated_public_key = ECDSA.recover(prefixedHash, signature); // same： prefixedHash.recover(signature)
      //     console.log('---------------');
      //     console.logBytes(abi.encode(msg.sender)); //去除0x，32 Byte，加 0x 66 个十六进制
      //     console.logBytes(abi.encodePacked(msg.sender)); //去除0x，20 Byte，和 Address 一样，加 0x 42 个十六进制
      //     console.logBytes(signature);
      //     console.log(signature.length);
      //     console.logBytes32(prefixedHash);
      //     console.log(prefixedHash.length);
      //     console.logAddress(calculated_public_key);
      //     console.logAddress(public_key);
      //     console.log((calculated_public_key == public_key));
      //     return (calculated_public_key == public_key);
      // }

      // const verifyRtn = await classicalNFT._verify(sigedMsg);
      // const verifyRtn = await classicalNFT._verify2(sigedMsg);

      expect(verifyRtn).to.equal(true);
    });

    it("Should receive and store the funds to ClassicalNFT", async function () {
      const { ClassicalNFT, ClassicalNFTedAmount } = await loadFixture(
        deployClassicalNFTFixture
      );

      expect(await ethers.provider.getBalance(ClassicalNFT.address)).to.equal(
        ClassicalNFTedAmount
      );
    });

    it("Should fail if the unClassicalNFTTime is not in the future", async function () {
      // We don't use the fixture here because we want a different deployment
      const latestTime = await time.latest();
      const ClassicalNFT = await ethers.getContractFactory("ClassicalNFT");
      await expect(
        ClassicalNFT.deploy(latestTime, { value: 1 })
      ).to.be.revertedWith("UnClassicalNFT time should be in the future");
    });
  });

  describe("Withdrawals", function () {
    describe("Validations", function () {
      it("Should revert with the right error if called too soon", async function () {
        const { ClassicalNFT } = await loadFixture(deployClassicalNFTFixture);

        await expect(ClassicalNFT.withdraw()).to.be.revertedWith(
          "You can't withdraw yet"
        );
      });

      it("Should revert with the right error if called from another account", async function () {
        const { ClassicalNFT, unClassicalNFTTime, otherAccount } =
          await loadFixture(deployClassicalNFTFixture);

        // We can increase the time in Hardhat Network
        await time.increaseTo(unClassicalNFTTime);

        // We use ClassicalNFT.connect() to send a transaction from another account
        await expect(
          ClassicalNFT.connect(otherAccount).withdraw()
        ).to.be.revertedWith("You aren't the owner");
      });

      it("Shouldn't fail if the unClassicalNFTTime has arrived and the owner calls it", async function () {
        const { ClassicalNFT, unClassicalNFTTime } = await loadFixture(
          deployClassicalNFTFixture
        );

        // Transactions are sent using the first signer by default
        await time.increaseTo(unClassicalNFTTime);

        await expect(ClassicalNFT.withdraw()).not.to.be.reverted;
      });
    });

    describe("Events", function () {
      it("Should emit an event on withdrawals", async function () {
        const { ClassicalNFT, unClassicalNFTTime, ClassicalNFTedAmount } =
          await loadFixture(deployClassicalNFTFixture);

        await time.increaseTo(unClassicalNFTTime);

        await expect(ClassicalNFT.withdraw())
          .to.emit(ClassicalNFT, "Withdrawal")
          .withArgs(ClassicalNFTedAmount, anyValue); // We accept any value as `when` arg
      });
    });

    describe("Transfers", function () {
      it("Should transfer the funds to the owner", async function () {
        const {
          ClassicalNFT,
          unClassicalNFTTime,
          ClassicalNFTedAmount,
          owner,
        } = await loadFixture(deployClassicalNFTFixture);

        await time.increaseTo(unClassicalNFTTime);

        await expect(ClassicalNFT.withdraw()).to.changeEtherBalances(
          [owner, ClassicalNFT],
          [ClassicalNFTedAmount, -ClassicalNFTedAmount]
        );
      });
    });
  });
});
