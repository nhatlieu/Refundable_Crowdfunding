// SPDX-FileCopyrightText: 2023 Nhat Lieu <nhatlieu@firensor.com>
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <=0.9.0;

// Importing the project creation contract
import "./5_ProjectCreation.sol";

// The Funding contract inherits from the ProjectCreation contract
contract Funding is ProjectCreation {

    // SafeMath library used for arithmetic operations
    using SafeMath for uint256;

    // Event emitted when a project is funded
    event Funded(uint projectId, address contributor, uint amount);

    // Mapping to store the total contribution for each project from each owner
    mapping(address => mapping(uint => uint)) public totalContribution;
    // Mapping to store the contribution made by each user to each project of each owner
    mapping(address => mapping(address => mapping(uint => uint))) public contribution;

    // Function for funding a project
    function fundProject(address _owner, uint _projectId, uint256 _amount) public payable {
        require(_amount > 0, "You need to fund more than 0"); // Ensures funding amount is more than 0
        require(msg.value == _amount, "Sent value does not match the input amount"); // Ensures sent ether matches the input amount

        // Finds the project to be funded
        Project storage projectToFund = findProject(_projectId);
        require(!projectToFund.isDeleted, "Project has been deleted"); // Checks if the project has been deleted

        // Updates the total contributions for the project
        projectToFund.totalContribution += _amount;
        totalContribution[_owner][_projectId] += _amount;
        contribution[msg.sender][_owner][_projectId] += _amount;
        emit Funded(_projectId, msg.sender, _amount);
    }

    // Function to refund a contributor if the funding goal is not reached
    function refund(address _owner, uint _projectId) public {
        // Finds the project to be refunded
        Project storage projectToRefund = findProject(_projectId);
        require(!projectToRefund.isDeleted, "Project has been deleted"); // Checks if the project has been deleted

        // Checks if the project has ended and hasn't reached its funding goal
        if(block.timestamp > projectToRefund.deadline && projectToRefund.totalContribution < projectToRefund.fundingGoal) {
            uint256 refundAmount = contribution[msg.sender][_owner][_projectId]; // Calculate the amount to be refunded
            require(refundAmount > 0, "No contribution or refund already claimed"); // Ensure the contributor has made contributions

            // Updates the total contributions
            totalContribution[_owner][_projectId] -= refundAmount;
            contribution[msg.sender][_owner][_projectId] = 0;
            
            // Transfers the refund amount back to the contributor
            payable(msg.sender).transfer(refundAmount);
        }
        else {
            revert("Refund not possible");
        }
    }

    // Function to release the funds to the project owner if the funding goal is reached
    function release(uint _projectId) public {
        // Finds the project for releasing funds
        Project storage projectToRelease = findProject(_projectId);

        // Checks the project's conditions
        require(!projectToRelease.isDeleted, "Project has been deleted"); // Check if the project has been deleted
        require(block.timestamp > projectToRelease.deadline, "Project deadline has not passed"); // Check if the project has ended
        require(projectToRelease.owner == msg.sender, "Only project owner can release funds"); // Check if the caller is the project owner

        if (projectToRelease.totalContribution >= projectToRelease.fundingGoal) {
            // Transfer the funds to the project owner and reset the total contribution
            payable(projectToRelease.owner).transfer(projectToRelease.totalContribution);
            projectToRelease.totalContribution = 0;
        } else {
            revert("Funding goal not met, funds cannot be released");
        }
    }

    // Function to check a user's contribution to a specific project
    function myContribution(address _owner, uint _projectId) public view returns(uint) {
        return (contribution[msg.sender][_owner][_projectId]);
    }

    // Function to check a project's total contribution
    function projectTotalContribution(address _owner, uint _projectId) public view returns(uint) {
        return (totalContribution[_owner][_projectId]);
    }
}
