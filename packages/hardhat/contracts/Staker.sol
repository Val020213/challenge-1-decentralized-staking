// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

error ExternalContractCompleted();
error TransactionFailed(string reason);
error DeadlineNotPassed();
error StakeTimePassed();

contract Staker {
    event Stake(address indexed staker, uint256 amount);
    ExampleExternalContract public exampleExternalContract;
    uint256 public deadline = block.timestamp + 30 seconds;

    mapping(address => uint256) public balances;

    uint256 public constant THRESHOLD = 1 ether;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    modifier notCompletedModifier() {
        if (exampleExternalContract.completed()) {
            revert ExternalContractCompleted();
        }
        _;
    }

    modifier deadlineNotPassedModifier() {
        if (timeLeft() > 0) {
            revert DeadlineNotPassed();
        }
        _;
    }

    modifier stackerTimeModifier() {
        if (timeLeft() < 0) {
            revert StakeTimePassed();
        }
        _;
    }

    function stake() public payable notCompletedModifier stackerTimeModifier {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    receive() external payable {
        stake();
    }

    function execute() external notCompletedModifier deadlineNotPassedModifier {
        uint256 totalBalance = address(this).balance;
        if (address(this).balance >= THRESHOLD) {
            exampleExternalContract.complete{ value: totalBalance }();
        }
    }

    function withdraw() external notCompletedModifier deadlineNotPassedModifier {
        uint256 amount = balances[msg.sender];

        balances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{ value: amount }("");

        if (!success) {
            revert TransactionFailed("Transfer failed");
        }
        emit Stake(msg.sender, amount);
    }
}
