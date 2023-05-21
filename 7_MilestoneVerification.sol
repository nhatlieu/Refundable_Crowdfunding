// SPDX-FileCopyrightText: 2023 Nhat Lieu <nhatlieu@firensor.com>
// SPDX-License-Identifier: GPL-3.0

// Specify the version of solidity that the contract can be compiled with
pragma solidity >= 0.8.2 <=0.9.0;

// Import the contract which MilestoneVerification contract will inherit from
import "./6_Funding with Milestone-based Escrow.sol";

// Create a contract named MilestoneVerification that inherits from the Funding contract
contract MilestoneVerification is Funding {

    // Define events to log certain state changes on the blockchain
    event MilestoneMarkedAsCompleted(address, uint, uint, uint);
    event MilestoneConfirmed(string, address, uint, uint);
    event MilestoneMarkedAsConfirmed(address, uint, uint);
    event MilestoneMarkedAsNotConfirmed(address, uint, uint);
    event FundReleased(address, uint, uint);
    event RefundIssued(address indexed backer, address indexed projectAddress, uint projectId, uint milestoneIndex, uint refundAmount);

    // Define a modifier to check if the caller has backed the project
    modifier onlyBacker(address _address, uint _projectId) {
        require(myContribution(_address, _projectId) > 0, "The caller has not backed this project");
        _; // continue execution
    }

    // Function to mark a project's milestone as complete
    function markMilestoneComplete(address _address, uint _projectId, uint _milestoneIndex) public {
        // Retrieve project and check the owner is the sender
        Project storage projectToMarkMilestoneComplete = findOtherProject(_address, _projectId);
        require(projectToMarkMilestoneComplete.owner == msg.sender);
        
        // Retrieve milestone and mark it as completed
        Milestone storage milestoneToComplete = projectToMarkMilestoneComplete.milestones[_milestoneIndex];
        milestoneToComplete.isCompleted = true;
        milestoneToComplete.completionTime = block.timestamp; // Record when the milestone was marked complete

        emit MilestoneMarkedAsCompleted(_address, _projectId, _milestoneIndex, milestoneToComplete.completionTime);
    }

    // Function to confirm a project's milestone
    function confirmMilestone(address _address, uint _projectId, uint _milestoneIndex) external onlyBacker(_address, _projectId) {
        // Retrieve project and milestone
        Project storage projectToConfirm = findOtherProject(_address, _projectId);
        require(!projectToConfirm.isDeleted, "Project has been deleted");
        Milestone storage milestoneToConfirm = projectToConfirm.milestones[_milestoneIndex];
        require(milestoneToConfirm.isCompleted == true, "The milestone hasn't completed");
        require (milestoneToConfirm.confirmationNum < 1);
        
        // Increase the confirmation count
        milestoneToConfirm.confirmationNum ++;
        emit MilestoneConfirmed(username[msg.sender], _address, _projectId, _milestoneIndex);

        // Calculate the percentage of confirmation
        uint percentageOfConfirmation = (milestoneToConfirm.confirmationNum * 100) / totalFunder[_address][_projectId];

        // If confirmed by 70% or more backers and not yet confirmed, mark it as confirmed
        if (percentageOfConfirmation >= 70 && !milestoneToConfirm.isConfirmed) {
            milestoneToConfirm.isConfirmed = true;
            emit MilestoneMarkedAsConfirmed(_address, _projectId, _milestoneIndex);
        }
    }

    // Function to cancel a confirmation of a project's milestone
    function cancelConfirmation(address _address, uint _projectId, uint _milestoneIndex) external onlyBacker(_address, _projectId) {
        // Retrieve project and milestone
        Project storage projectToConfirm = findOtherProject(_address, _projectId);
        require(!projectToConfirm.isDeleted, "Project has been deleted");
        Milestone storage milestoneToConfirm = projectToConfirm.milestones[_milestoneIndex];
        require(milestoneToConfirm.isCompleted == true, "The milestone hasn't completed");
        require (milestoneToConfirm.confirmationNum == 1);
        
        // Decrease the confirmation count
        milestoneToConfirm.confirmationNum --;
        emit MilestoneConfirmed(username[msg.sender], _address, _projectId, _milestoneIndex);

        // Calculate the percentage of confirmation
        uint percentageOfConfirmation = (milestoneToConfirm.confirmationNum * 100) / totalFunder[_address][_projectId];

        // If confirmed by 70% or less backers and still marked as confirmed, mark it as not confirmed
        if (percentageOfConfirmation <= 70 && !milestoneToConfirm.isConfirmed) {
            milestoneToConfirm.isConfirmed = false;
            emit MilestoneMarkedAsNotConfirmed(_address, _projectId, _milestoneIndex);
        }
    }

    // Function to release funds for a project's milestone
    function releaseFund(address _address, uint _projectId, uint _milestoneIndex) internal {
        // Retrieve project and milestone
        Project storage projectToReleaseFund = findOtherProject(_address, _projectId); 
        require(projectToReleaseFund.owner == msg.sender, "You are not the project owner");
        require(!projectToReleaseFund.isDeleted, "Project has been deleted");
        Milestone storage milestoneToReleaseFund = projectToReleaseFund.milestones[_milestoneIndex];
        require(milestoneToReleaseFund.isConfirmed, "Milestone not confirmed");
        
        // Check there are enough funds to release
        require(totalContribution[_address][_projectId] >= milestoneToReleaseFund.releasedAmount, "Not enough funds to release");
        totalContribution[_address][_projectId] -= milestoneToReleaseFund.releasedAmount;

        // Transfer the funds to the project owner
        address payable projectOwner = payable(projectToReleaseFund.owner);
        projectOwner.transfer(milestoneToReleaseFund.releasedAmount);

        emit FundReleased(_address, _projectId, milestoneToReleaseFund.releasedAmount);
    }

    // Function to refund a backer
    function refundBacker(address _address, uint _projectId, uint _milestoneIndex) public onlyBacker(_address, _projectId) {
        // Retrieve project and milestone
        Project storage projectToRefund = findOtherProject(_address, _projectId);
        require(!projectToRefund.isDeleted, "Project has been deleted");
        Milestone storage milestoneToRefund = projectToRefund.milestones[_milestoneIndex];
        require(block.timestamp > milestoneToRefund.deadline, "Deadline has not been passed");
        require(!milestoneToRefund.isConfirmed, "Project has been confirmed with backers");
        
        // Calculate refund amount
        totalContribution[_address][_projectId] -= contribution[msg.sender][_address][_projectId];
        
        // Transfer the funds back to the backer
        address payable projectBacker = payable(msg.sender);
        projectBacker.transfer(contribution[msg.sender][_address][_projectId]);
        contribution[msg.sender][_address][_projectId] = 0;            
    }
}
