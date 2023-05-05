// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Lottery {
    address payable public owner;
    uint256 public numUsers;
    uint256 public winningNumber;
    mapping(uint256 => address) public userAddresses;
    mapping(address => uint256) public commitments;

    constructor() {
        owner = payable(msg.sender);
    }

    function enter(uint256 commitment) external payable {
        require(msg.value >= 0.1 ether, "Entry fee is 0.1 ETH");
        require(commitments[msg.sender] == uint256(0), "Already entered");
        require(numUsers < 100, "Maximum number of users reached");
        commitments[msg.sender] = commitment;
        userAddresses[numUsers] = msg.sender;
        numUsers++;
    }

    function selectWinner() external {
        require(msg.sender == owner, "Only owner can select winner");
        require(numUsers > 0, "No users entered");
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.basefee, numUsers)));
        winningNumber = seed % 1000;
        uint256 winningIndex = 0;
        for (uint256 i = 0; i < numUsers; i++) {
            uint256 commitment = commitments[userAddresses[i]];
            uint256 number = uint256(keccak256(abi.encodePacked(commitment, seed))) % 1000;
            if (number == winningNumber) {
                winningIndex = i;
                break;
            }
        }
        address payable winner = payable(userAddresses[winningIndex]);
        uint256 prize = numUsers * 0.1 ether * 98 / 100;
        winner.transfer(prize);
        owner.transfer(numUsers * 0.1 ether * 2 / 100);
        reset();
    }


    function reset() private {
        numUsers = 0;
        winningNumber = 0;
        for (uint256 i = 0; i < numUsers; i++) {
            commitments[userAddresses[i]] = uint256(0);
        }
    }
}