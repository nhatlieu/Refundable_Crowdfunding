// SPDX-FileCopyrightText: 2023 Nhat Lieu <nhatlieu@firensor.com>
// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.2 <=0.9.0;

import "./6_Funding with Milestone-based Escrow.sol";

contract MilestoneVerification is Funding {

    event MilestoneMarkedAsCompleted(address, uint, uint, uint);
    event MilestoneConfirmed(string, address, uint, uint);
    event MilestoneMarkedAsConfirmed(address, uint, uint);
    event FundReleased(address, uint, uint);

    function markMilestoneComplete(address _address, uint _projectId, uint _milestoneIndex) public {
        Project storage projectToMarkMilestoneComplete = findOtherProject(_address, _projectId);
        require(projectToMarkMilestoneComplete.owner == msg.sender);
        Milestone storage milestoneToComplete = projectToMarkMilestoneComplete.milestones[_milestoneIndex];
        milestoneToComplete.isCompleted = true;
        milestoneToComplete.completionTime = block.timestamp; // Record when the milestone was marked complete

        emit MilestoneMarkedAsCompleted(_address, _projectId, _milestoneIndex, milestoneToComplete.completionTime);
    }

    function confirmMilestone(address _address, uint _projectId, uint _milestoneIndex) external {
        require(myContribution(_address, _projectId) > 0, "The caller has not backed this project"); // Validate whether caller is the backer of the project
        Project storage projectToConfirm = findOtherProject(_address, _projectId);
        require(!projectToConfirm.isDeleted, "Project has been deleted");
        Milestone storage milestoneToConfirm = projectToConfirm.milestones[_milestoneIndex];
        require(milestoneToConfirm.isCompleted == true, "The milestone hasn't completed");
        milestoneToConfirm.confirmationNum ++;
        emit MilestoneConfirmed(username[msg.sender], _address, _projectId, _milestoneIndex);
        uint percentageOfConfirmation = (milestoneToConfirm.confirmationNum * 100) / totalFunder[_address][_projectId];

        if (percentageOfConfirmation >= 70 && !milestoneToConfirm.isConfirmed) {
            milestoneToConfirm.isConfirmed = true;
            emit MilestoneMarkedAsConfirmed(_address, _projectId, _milestoneIndex);
        }
    }

    function releaseFund(address _address, uint _projectId, uint _milestoneIndex) internal {
        Project storage projectToReleaseFund = findOtherProject(_address, _projectId); 
        require(!projectToReleaseFund.isDeleted, "Project has been deleted");
        Milestone storage milestoneToReleaseFund = projectToReleaseFund.milestones[_milestoneIndex];
        require(milestoneToReleaseFund.isConfirmed, "Milestone not confirmed");
        require(totalContribution[_address][_projectId] >= milestoneToReleaseFund.releasedAmount, "Not enough funds to release");
        totalContribution[_address][_projectId] -= milestoneToReleaseFund.releasedAmount;
        address payable projectOwner = payable(projectToReleaseFund.owner);
        projectOwner.transfer(milestoneToReleaseFund.releasedAmount);

        emit FundReleased(_address, _projectId, milestoneToReleaseFund.releasedAmount);
    }
}