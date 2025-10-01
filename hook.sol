// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// 设置 Token 名称（name）："BaseERC20"
// 设置 Token 符号（symbol）："BERC20"
// 设置 Token 小数位decimals：18
// 设置 Token 总量（totalSupply）:100,000,000
// 允许任何人查看任何地址的 Token 余额（balanceOf）
// 允许 Token 的所有者将他们的 Token 发送给任何人（transfer）；转帐超出余额时抛出异常(require),并显示错误消息 “ERC20: transfer amount exceeds balance”。
// 允许 Token 的所有者批准某个地址消费他们的一部分Token（approve）
// 允许任何人查看一个地址可以从其它账户中转账的代币数量（allowance）
// 允许被授权的地址消费他们被授权的 Token 数量（transferFrom）；
// 转帐超出余额时抛出异常(require)，异常信息：“ERC20: transfer amount exceeds balance”
// 转帐超出授权数量时抛出异常(require)，异常消息：“ERC20: transfer amount exceeds allowance”。

contract BaseERC20 {
    string public name; 
    string public symbol; 
    uint8 public decimals; 

    uint256 public totalSupply; 

    mapping (address => uint256) balances; 

    mapping (address => mapping (address => uint256)) allowances; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        // write your code here
        // set name,symbol,decimals,totalSupply
        name = "BaseERC20";
        symbol = "BERC20";
        decimals = 18;
        totalSupply = 100000000*10**decimals;
        balances[msg.sender] = totalSupply;  
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        // write your code here
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(_value<=balances[msg.sender],"ERC20: transfer amount exceeds balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);  
        return true;   
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(_value<=balances[_from],"ERC20: transfer amount exceeds balance");
        require(_value<=allowances[_from][msg.sender],"ERC20: transfer amount exceeds allowance");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value); 
        return true; 
    }

    function approve(address _user, address _spender, uint256 _value) public returns (bool success) {
        // write your code here
        require(_value<=balances[_user],"ERC20: approve amount exceeds balance");
        allowances[_user][_spender] = _value;
        emit Approval(_user, _spender, _value); 
        return true; 
    }


    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {   
        // write your code here     
        return allowances[_owner][_spender];
    }

    function transferWithCallback(address _to, uint256 _amount) external returns(bool) {
        require(_amount <= balances[msg.sender], "ERC20: transfer amount exceeds balance");
        
        if (_to.code.length > 0) {
            (bool success, bytes memory data) = _to.call(
                abi.encodeWithSignature("tokensReceived(address,uint256)", msg.sender, _amount)
            );
            
            //require(success, "Custom callback failed"); 
            if (!success) {
                // 保留原始错误信息，便于调试
                if (data.length > 0) {
                    assembly {
                        revert(add(32, data), mload(data))
                    }
                } else {
                    revert("Custom callback failed");
                }
            }
            
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
        } else {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
        }
        
        emit Transfer(msg.sender, _to, _amount);
        return true; 
    }
}

// TokenBank 有两个方法：

// deposit() : 需要记录每个地址的存入数量；
// withdraw(): 用户可以提取自己的之前存入的 token。

contract tokenBank {
    mapping (address => mapping (address => uint256)) balances;
    event Deposit(address indexed owner, address indexed spender, uint256 value);
    // 合约所有者地址
    address public owner;
    // 重入锁：防止重入攻击
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status = _NOT_ENTERED;
    constructor()payable  {
        owner = msg.sender;
        require(owner != address(0), "Owner cannot be zero address");
    }
    function deposit(address _tokenAddress, uint256 _value) public nonReentrant{
        require(_value > 0, "Amount must be greater than 0");
        (bool success1, ) = _tokenAddress.call(abi.encodeWithSignature("approve(address,address,uint256)",msg.sender,address(this),_value));
        require(success1, "approve failed.");
        (bool success2, ) = _tokenAddress.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender,address(this),_value));
        require(success2, "transferFrom failed.");
        (bool success3, ) = _tokenAddress.call(abi.encodeWithSignature("approve(address,address,uint256)",msg.sender,address(this),0));
        require(success3, "approve failed.");
        balances[msg.sender][_tokenAddress] += _value;
        emit Deposit(msg.sender, _tokenAddress, _value); 
    }

    function withdraw(address _tokenAddress, uint256 _value) public nonReentrant{
        require(_value > 0, "Amount must be greater than 0");
        require(balances[msg.sender][_tokenAddress] >= _value, "Insufficient balance.");
        (bool success1, ) = _tokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)",msg.sender,_value));
        require(success1, "transfer failed.");
        (bool success2, ) = _tokenAddress.call(abi.encodeWithSignature("approve(address,address,uint256)",msg.sender,address(this),0));
        require(success2, "approve failed.");
        balances[msg.sender][_tokenAddress] -= _value;
        emit Deposit(msg.sender, _tokenAddress, _value); 
    }

    /**
     * @dev 重入锁修饰符，防止重入攻击
     */
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    /**
     * @dev 修饰符：限制只有合约所有者才能执行函数
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /**
     * @dev 提取所有存款的函数，只能由合约所有者调用
     */
    function withdrawAll() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
    }
}

// import "./tokenBank.sol";
contract tokenBankV2 is tokenBank {
    function tokensReceived(address _user, uint256 _value) external{
        require(_value > 0, "Amount must be greater than 0");
        balances[_user][msg.sender] += _value;
        emit Deposit(_user, msg.sender, _value); 
    }

}