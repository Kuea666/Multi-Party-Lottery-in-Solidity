// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Lottery {
    address payable public owner;
    uint256 public numUsers;
    uint256 public maxUsers;
    uint256 public endTime;
    uint256 public winningNumber;
    mapping(uint256 => address) public userAddresses;
    mapping(address => uint256) public commitments;
    uint256 public startTime;
    uint256 public revealTime;
    uint256 public numRevealed;
    uint256 public maxCommitment;
    mapping(address => uint256) public revealedValues;
    bool public killed;

    constructor(uint256 _maxUsers, uint256 _maxCommitment, uint256 _startTime, uint256 _endTime, uint256 _revealTime) {
        owner = payable(msg.sender);
        maxUsers = _maxUsers;
        maxCommitment = _maxCommitment;
        startTime = _startTime;
        endTime = _endTime;
        revealTime = _revealTime;
    }

    function enter(uint256 commitment) external payable {
        require(block.timestamp >= startTime, "Lottery has not started yet");
        require(block.timestamp < endTime, "Lottery has ended");
        require(!killed, "Lottery has been killed by the owner");
        require(msg.value == 0.1 ether, "Entry fee is 0.1 ETH");
        require(commitment <= maxCommitment, "Invalid commitment value");
        require(commitments[msg.sender] == 0, "Already entered");
        require(numUsers < maxUsers, "Maximum number of users reached");
        commitments[msg.sender] = commitment;
        userAddresses[numUsers] = msg.sender;
        numUsers++;
    }
    function reveal(uint256 value) external {
        require(block.timestamp >= endTime, "Lottery has not ended yet");
        require(block.timestamp < revealTime, "Reveal period has ended");
        require(!killed, "Lottery has been killed by the owner");
        require(commitments[msg.sender] != 0, "User did not enter the lottery");
        require(revealedValues[msg.sender] == 0, "User already revealed value");
        require(value <= maxCommitment, "Invalid value");
        revealedValues[msg.sender] = value;
        numRevealed++;
    }

    function selectWinner() external {
        require(block.timestamp >= revealTime, "Reveal period has not ended yet");
        require(!killed, "Lottery has been killed by the owner");
        require(numRevealed > 0, "No users revealed value");
        winningNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, numUsers)));
        uint256 winningIndex = 0;
        for (uint256 i = 0; i < numUsers; i++) {
            if (revealedValues[userAddresses[i]] == 0) {
                continue;
            }
            uint256 commitment = commitments[userAddresses[i]];
            uint256 number = uint256(keccak256(abi.encodePacked(commitment, winningNumber))) % maxCommitment;
            if (number == revealedValues[userAddresses[i]]) {
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

    function kill() external {
    require(msg.sender == owner, "Only owner can kill the lottery");
    if (stage == LotteryStage.Stage1) {
        require(block.timestamp >= startTime.add(stage1Duration), "Stage 1 is still ongoing");
        require(numUsers > 0, "No users entered");
        stage = LotteryStage.Stage2;
        startTime = block.timestamp;
    } else if (stage == LotteryStage.Stage2) {
        require(block.timestamp >= startTime.add(stage2Duration), "Stage 2 is still ongoing");
        stage = LotteryStage.Stage3;
        startTime = block.timestamp;
        if (numUsers == 0) {
            selfdestruct(owner);
        }
    }
    }
  
    function reset() private {
        numUsers = 0;
        winningNumber = 0;
        for (uint256 i = 0; i < maxUsers; i++) {
            commitments[userAddresses[i]] = uint256(0);
        }
    }
}
