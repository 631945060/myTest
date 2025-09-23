const { log } = require('console')
const crypto = require('crypto')
const initBlock = { //初始区块
    index:1,
    data:'Hello,word',
    previous_hash:'xxxx',
    timestamp:1506057125,
    transactions: [
    { 'sender': "xxx", 
    'recipient': "xxx", 
    'amount': 5, } ], 
    nonce:50466,
    proof:324984774000,
    hashdata:'0051a288901fdaec6e27cb433fefbf89a4dcb8d82cc306f5b3a228544a1e072b'
}
class Blockchain{
    constructor(){
        this.blockchain = []//空的创世区块
         this.blockchain.push(initBlock)
        this.data = []       //存储区块所有的信息(交易信息)
        this.difficulty = 2    //区块的难度 ,数字越大,消耗的时间越长
    //   const hashData =   this.computeHash(0,'0',new Date().getTime,'Hello Word',2)
    //     console.log(hashData);
    }
    //获取最新的区块
    getLastBlock(){
        return this.blockchain[this.blockchain.length-1]
    }
    //挖矿
    mine(){

        let  newBlock = this.generateNewBlock()
       if(this.isValidaBlock(newBlock) && this.isValidaChain){
            this.blockchain.push(newBlock)
            console.log('恭喜你,挖到一枚比特币');
       }else {
        console.log('error,Invalid Block')
       }
        
    }
    //生成新区块
    generateNewBlock(){
 //生成新区块
        //不停的算hash 直到符合难度条件 新增区块
        let nonce = 0
        const index = this.blockchain.length
        const data = this.data
        const previous_hash = this.blockchain[this.blockchain.length-1].hashdata

        let timestamp = new Date().getTime()
       let hashdata =  this.computeHash(index,previous_hash,timestamp,data,nonce)
        while(hashdata.slice(0,this.difficulty) !== '0'.repeat(this.difficulty)){
            nonce+=1
            hashdata = this.computeHash(index,previous_hash,timestamp,data,nonce)
            console.log(hashdata);
        }
        return {
            index,
            data,
            previous_hash,
            timestamp,
            nonce,
            hashdata
        }
    }
        //计算哈希
    computeHashForBlock({index,previous_hash,timestamp,data,nonce}){
      return  this.computeHash(index,previous_hash,timestamp,data,nonce)
    }
    //计算哈希
    computeHash(index,previous_hash,timestamp,data,nonce){
      return  crypto.createHash('sha256')
      .update(index+previous_hash+timestamp+data+nonce)
      .digest('hex')
    }
    //校验区块
    isValidaBlock(newBlock,lastBlock = this.getLastBlock()){
        if(newBlock.index !== lastBlock.index+1){ //1.区块的index等于最新区块的index+1
            return false
        }else if(newBlock.timestamp <= lastBlock.timestamp){//2.区块的time大于最新区块
            return false
        }else if(newBlock.previous_hash !== lastBlock.hashdata){ //最新区块的previous_hash 等于最新区块的hash
            return false
        }else if(newBlock.hashdata.slice(0,this.difficulty)!=='0'.repeat(this.difficulty)){ //hash值符合难度要求
            return false
        }else if(newBlock.hashdata!== this.computeHashForBlock(newBlock)){ //校验hash值是否正确
            return false
        }else {
            return true
        }
    }
    isValidaChain(chain = this.blockchain){
        for(let i=chain.length -1 ;i>=1;i-1){
            if(!this.isValidaBlock(chain[i],chain[i-1])){
                return false
            }
        }
        if(JSON.stringify(chain[0]) !== JSON.stringify(initBlock)){
                return false
        }
        return true
    }
}
let bc = new Blockchain()
bc.mine()//挖一次矿
bc.mine()//挖一次矿
bc.mine()//挖一次矿
bc.mine()//挖一次矿
bc.mine()//挖一次矿