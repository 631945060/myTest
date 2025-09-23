const crypto = require("crypto");

class block {
  constructor() {
    this.difficulty = 4; //区块的难度 ,数字越大,消耗的时间越长
    this.data = "张继伟";
  }

  main() {
    this.getHexData(4);
    this.getHexData(5);

  }

  getHexData(difficulty) {
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
  }

  computeHash(data, nonce) {
    return crypto
      .createHash("sha256")
      .update(data + nonce)
      .digest("hex");
  }

}
const block1 = new block();
block1.main();
