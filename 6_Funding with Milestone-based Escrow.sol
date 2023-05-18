pragma solidity >=0.8.2 <=0.9.0;

import "./5_ProjectCreation.sol";

contract Funding is ProjectCreation {
    event Funded(uint projectId, address contributor, uint amount);

    mapping(address => mapping(uint => uint)) public totalContribution;
    mapping(address => mapping(address => mapping(uint => uint))) public contribution;

    function fundProject(address _owner, uint _projectId, uint _amount) public payable {
        require(msg.value == _amount, "Sent value does not match the input amount");

        Project[] storage userProjects = projects[_owner];

        for(uint i = 0; i < userProjects.length; i++) {
            if(userProjects[i].projectId == _projectId && !userProjects[i].isDeleted) {
                userProjects[i].totalContribution += _amount;
                totalContribution[_owner][_projectId] += _amount;
                contribution[msg.sender][_owner][_projectId] += _amount;
                emit Funded(_projectId, msg.sender, _amount);
                return;
            }
        }

        revert("Project not found or has been deleted");
    }

    function refund(address _owner, uint _projectId) public {
        Project[] storage userProject = projects[_owner];
        uint projectIndex;
        bool projectFound = false;

        for(uint i = 0; i < userProject.length; i++) {
            if(userProject[i].projectId == _projectId) {
                projectIndex = i;
                projectFound = true;
                break;
            }
        }

        require(projectFound, "Project not found");
        require(!userProject[projectIndex].isDeleted, "Project has been deleted");

        if(block.timestamp > userProject[projectIndex].deadline && userProject[projectIndex].totalContribution < userProject[projectIndex].fundingGoal) {
            uint refundAmount = contribution[msg.sender][_owner][_projectId];
            require(refundAmount > 0, "No contribution or refund already claimed");

            totalContribution[_owner][_projectId] -= refundAmount;
            contribution[msg.sender][_owner][_projectId] = 0;
            
            payable(msg.sender).transfer(refundAmount);
        }
        else {
            revert("Refund not possible");
        }
    }

    function release(uint _projectId) public {
        Project[] storage userProject = projects[msg.sender];
        uint projectIndex;
        bool projectFound = false;

        for(uint i = 0; i < userProject.length; i++) {
            if(userProject[i].projectId == _projectId) {
                projectIndex = i;
                projectFound = true;
                break;
            }
        }

        require(projectFound, "Project not found");
        require(!userProject[projectIndex].isDeleted, "Project has been deleted");
        require(block.timestamp > userProject[projectIndex].deadline, "Project deadline has not passed");

        if (userProject[projectIndex].totalContribution >= userProject[projectIndex].fundingGoal) {
        payable(msg.sender).transfer(userProject[projectIndex].totalContribution);
        userProject[projectIndex].totalContribution = 0;
        }
        else {
            revert("Funding goal not met, funds cannot be released");
        }
    }
}
