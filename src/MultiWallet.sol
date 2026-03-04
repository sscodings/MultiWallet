// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract MultiWallet{
    struct DepositInfo{
        uint amount;
        uint unlockTime;
    }

    mapping(address=>DepositInfo[]) public users;

    function deposit() public payable{
        require(msg.value>0,"Eth must be sent");
        users[msg.sender].push(DepositInfo({
            amount:msg.value,
            unlockTime:block.timestamp+7 days
        }));
    }

    function withdraw(uint index) public{
        require(index<users[msg.sender].length,"Invalid index");
        require(block.timestamp>=users[msg.sender][index].unlockTime,"Time not reached");
        require(users[msg.sender][index].amount>0,"Already withdrawn");

        uint _amount = users[msg.sender][index].amount;

        users[msg.sender][index].amount=0;
        (bool success,) = msg.sender.call{value:_amount}("");
        require(success,"Withdrawal failed");

    }

    function getUserDepositCounts(address user) public view returns(uint){
        return users[user].length;
    } 

    function getDeposit(address user,uint index) public view returns(uint,uint){
        require(index<users[user].length,"Invalid index");
        return(users[user][index].amount,users[user][index].unlockTime);
    }
}
