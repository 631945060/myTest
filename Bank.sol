// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    // 管理员地址
    address public owner;

    // 存款映射：记录每个地址的存款金额
    mapping(address => uint256) public deposits;

    // 存储前3名存款用户的地址
    address[3] public topDepositors;

    // 事件：记录存款和取款
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed owner, uint256 amount);

    // 构造函数：部署时设置管理员
    constructor() {
        owner = msg.sender;
    }

    // 接收存款：支持直接转账
    receive() external payable {
        _deposit();
    }

    fallback() external payable {
        _deposit();
    }

    // 内部存款处理函数
    function _deposit()  internal {
        require(msg.value > 0, "Deposit amount must be greater than 0");

        uint256 newDeposit = deposits[msg.sender] + msg.value;
        deposits[msg.sender] = newDeposit;

        // 更新前3名
        _updateTopDepositors(msg.sender);

        emit Deposit(msg.sender, msg.value);
    }

    // 更新前3名存款用户
    function _updateTopDepositors(address depositor) private {
        // 将当前用户的地址插入到前3名中（按存款金额排序）
        address[3] memory oldTop = topDepositors; // 临时保存

        // 把当前 depositor 加入候选列表
        address[4] memory candidates = [oldTop[0], oldTop[1], oldTop[2], depositor];

        // 简单排序：冒泡排序（因为只有4个元素）
        for (uint256 i = 0; i < 4; i++) {
            for (uint256 j = i + 1; j < 4; j++) {
                if (deposits[candidates[i]] < deposits[candidates[j]]) {
                    address temp = candidates[i];
                    candidates[i] = candidates[j];
                    candidates[j] = temp;
                }
            }
        }

        // 取前3名，去重（避免同一个地址重复）
        uint256 count = 0;
        for (uint256 i = 0; i < 4; i++) {
            if (count >= 3) break;
            // 避免重复添加同一地址
            bool exists = false;
            for (uint256 k = 0; k < count; k++) {
                if (topDepositors[k] == candidates[i]) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                topDepositors[count] = candidates[i];
                count++;
            }
        }
        // 剩余位置清空（可选，也可以保留旧值）
        while (count < 3) {
            topDepositors[count] = address(0);
            count++;
        }
    }

    // 提款函数：仅管理员可调用
    function withdraw() external {
        require(msg.sender == owner, "Not the owner");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        // 安全转账
        (bool success,) = owner.call{value: balance}("");
        require(success, "Transfer failed");

        emit Withdraw(owner, balance);
    }

    // 查询合约余额（只读）
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // 查询某个地址的存款
    function getDepositOf(address user) external view returns (uint256) {
        return deposits[user];
    }
}