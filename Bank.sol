// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
// 导入 Hardhat 的 console.log

interface IBank {
    struct TopThreeUser {
        address addr;
        uint amount;
    }

    function withDraw() external payable;

    function setAdmin(address newAdmin) external;
}
contract Bank is IBank {
    mapping(address => uint) public balances;
    address ownerAddr;
    address contractAddr;
    TopThreeUser[4] topusers;

    constructor() payable {
        ownerAddr = msg.sender;
        contractAddr = address(this);
        for (uint i = 0; i < 4; i++) {
            topusers[i] = TopThreeUser(address(0), 0);
        }
    }

    modifier onlyOwner() {
    
        // console.log("origin:", tx.origin);
        require(msg.sender == ownerAddr, unicode"仅钱包管理员可以操作");
        _;
    }
    modifier onlyContractAddrOwner() {
       
        // console.log("origin:", tx.origin);
        require(address(this) == contractAddr, unicode"仅部署初始合约地址可以操作");
        _;
    }
    function withDraw() external payable onlyContractAddrOwner {
        payable(ownerAddr).transfer(address(this).balance);
    }

    function gettop3() public view returns (TopThreeUser[] memory) {
        TopThreeUser[] memory top3users = new TopThreeUser[](3);
        for (uint i = 0; i < 3; i++) {
            top3users[i] = TopThreeUser(topusers[i].addr, topusers[i].amount);
        }

        return top3users;
    }
    function deposit() public payable virtual {
        balances[msg.sender] += msg.value;

        // 将新用户存入第3个位置（索引3），然后排序前4个
        topusers[3] = TopThreeUser(msg.sender, msg.value);

        TopThreeUser memory temp;
        bool swapped;
        uint length = 4;

        for (uint i = 0; i < length; i++) {
            swapped = false;
            // ✅ 修正：j < length - i - 1，避免访问 j+1 越界
            for (uint j = 0; j < length - i - 1; j++) {
                if (topusers[j].amount < topusers[j + 1].amount) {
                    // 降序排列（从高到低）
                    temp = topusers[j];
                    topusers[j] = topusers[j + 1];
                    topusers[j + 1] = temp;
                    swapped = true;
                }
            }
            if (!swapped) break;
        }
    }
    function setAdmin(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "Cannot transfer ownership to zero address"
        );
        ownerAddr = newOwner;
    }
    receive() external payable {}
}

contract BigBank is Bank {
    modifier minBigDeposit() {
        require(
            msg.value > 0.001 ether,
            "Deposit must be greater than 0.001 ether"
        );
        _;
    }

    function deposit() public payable override minBigDeposit {
        // 调用父类的 deposit 逻辑
        super.deposit();
    }

    function getOwner() external view returns (address) {
        return ownerAddr;
    }
}
// ✅ 新增：Admin 合约
contract Admin {
    address public owner;
    IBank public bank; // Bank 合约
    constructor(address bankAddress) {
        owner = msg.sender;
        bank = IBank(bankAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    function adminWithdraw() external onlyOwner {
        bank.withDraw();
    }

    // Admin 合约也能接收 ETH
    receive() external payable {}
}
