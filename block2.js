const crypto = require("crypto");

class block {
  constructor() {
    this.difficulty = 4; //区块的难度 ,数字越大,消耗的时间越长
    this.data = "张继伟";
  }

  main() {
    this.getHexData(4);

  }
 generateKeyPair() {
    const { privateKey, publicKey } = crypto.generateKeyPairSync('rsa', {
        modulusLength: 2048,
        publicKeyEncoding: {
            type: 'spki',
            format: 'pem'
        },
        privateKeyEncoding: {
            type: 'pkcs8',
            format: 'pem'
        }
    });
    return { privateKey, publicKey };
}
  getHexData(difficulty) {

  // 步骤1: 生成密钥对
    const { privateKey, publicKey } = this.generateKeyPair();
    //步骤2:获取hash
    this.nonce = 0;
    let hash = this.computeHash(this.data, this.nonce);
    let timestamp = new Date().getTime();
    let timestamp2 = 0;
    while (hash.slice(0, difficulty) !== "0".repeat(difficulty)) {
      this.nonce += 1;
      hash = this.computeHash(this.data, this.nonce);
      timestamp2 = new Date().getTime();
    }
    console.log("zzjw", hash, timestamp2 - timestamp);

        // 步骤3: 使用私钥签名
    const signature = this.signData(privateKey, hash);
    console.log(`\n🔒 使用私钥对数据进行签名:`);
    console.log(`   签名 (Base64): ${signature}`);

       // 步骤4: 使用公钥验证签名
    const isValid = this.verifySignature(publicKey, hash, signature);
    console.log(`\n🔍 使用公钥验证签名...`);
    if (isValid) {
        console.log(`✅ 签名验证成功！数据完整且来自私钥持有者。`);
    } else {
        console.log(`❌ 签名验证失败！`);
    }

  }

  computeHash(data, nonce) {
    return crypto
      .createHash("sha256")
      .update(data + nonce)
      .digest("hex");
  }

  //  使用私钥对数据进行签名
 signData(privateKey, data) {
    const signer = crypto.createSign('SHA256');
    signer.update(data);
    signer.end();
    return signer.sign(privateKey, 'base64'); // 返回 base64 编码的签名
}

//使用公钥验证签名
 verifySignature(publicKey, data, signature) {
    const verifier = crypto.createVerify('SHA256');
    verifier.update(data);
    verifier.end();
    return verifier.verify(publicKey, signature, 'base64');
}


}
const block1 = new block();
block1.main();
