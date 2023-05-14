pragma solidity >=0.8.2 <0.9.0;

import "./4_UserRegistration.sol";

contract ProjectCreation is UserRegistration {

    event ProjectCreated(uint projectId, address owner, string projectName, uint fundingGoal, uint deadline);
    event MilestoneCreated(uint projectId, string description, uint targetDate, uint releasedAmount);
    event ProjectDeleted(uint projectId);
    event ProjectEdited(uint projectId);
    event MilestoneEdited(uint projectId);

    struct Milestone {
        string description;
        uint targetDate;
        uint releasedAmount;
    }

    struct Project {
        address owner;
        uint projectId;
        string projectName;
        uint fundingGoal;
        uint deadline;
        Milestone[] milestones;
    }

    uint projectNum;

    mapping(address => Project[]) public projects;

    function createProject(string memory _name, uint _amount, uint _deadline) public {
        Project storage newProject = projects[msg.sender].push();
        newProject.owner = msg.sender;
        newProject.projectId = projectNum;
        newProject.projectName = _name;
        newProject.fundingGoal = _amount;
        newProject.deadline = _deadline;
        
        projectNum ++;
        emit ProjectCreated(projectNum, msg.sender, _name, _amount, _deadline);
    }

    function fillMilestone(uint _projectId, string memory _description, uint _date, uint _amount) public {
        Project[] storage userProjects = projects[msg.sender];
        uint projectToUpdateIndex;
        bool projectFound = false;

        // Loop over the projects to find the one with the given projectId
        for(uint i = 0; i < userProjects.length; i++) {
            if(userProjects[i].projectId == _projectId) {
                projectToUpdateIndex = i;
                projectFound = true;
                break;
            }
        }

        require(projectFound, "Project not found");
        require(msg.sender == userProjects[projectToUpdateIndex].owner, "Not the project owner");

        Milestone memory newMilestone = Milestone({description: _description, targetDate: _date, releasedAmount: _amount});
        userProjects[projectToUpdateIndex].milestones.push(newMilestone);
        emit MilestoneCreated(_projectId, _description, _date, _amount);
    }

    function deleteProject(uint _projectId) public {
        Project[] storage userProject = projects[msg.sender];
        uint projectIndex;
        bool projectFound = false;

        for(uint i = 0; i < userProject.length; i++) {
            if(userProject[i].projectId == _projectId) {
                projectIndex =i;
                projectFound = true;
                break;
            }
        }

        require(projectFound, "Project not found");
        require(msg.sender == userProject[projectIndex].owner, "Not the project owner");

        // if the project to delete is not the last one in the list
        if (projectIndex < userProject.length - 1) {
            // Move the last project in the list into the place of the one to delete
            userProject[projectIndex] = userProject[userProject.length - 1];
        }

        // Delete the last project as it's now a duplicate
        userProject.pop();
        
        emit ProjectDeleted(_projectId);

    }

    function editProject(uint _projectId, string memory _name, uint _amount, uint _deadline) public {
        Project[] storage userProject = projects[msg.sender];
        uint projectToEditIndex;
        bool projectFound = false;

        for (uint i = 0; i < userProject.length; i++) {
            if (userProject[i].projectId == _projectId) {
                projectToEditIndex = i;
                projectFound = true;
                break;
            }
        }

    require(projectFound, "Project not found");
    require(msg.sender == userProject[projectToEditIndex].owner, "Not the project owner");

    userProject[projectToEditIndex].projectName = _name;
    userProject[projectToEditIndex].fundingGoal = _amount;
    userProject[projectToEditIndex].deadline = _deadline;

    emit ProjectEdited(_projectId);
    }

    function editMilestone(uint _projectId, uint _milestoneIndex, string memory _description, uint _date, uint _amount) public {

        Project[] storage userProjects = projects[msg.sender];
        uint projectToEditIndex;
        bool projectFound = false;

        // Loop over the projects to find the one with the given projectId
        for(uint i = 0; i < userProjects.length; i++) {
            if(userProjects[i].projectId == _projectId) {
                projectToEditIndex = i;
                projectFound = true;
                break;
            }
        }

        require(projectFound, "Project not found");
        require(msg.sender == userProjects[projectToEditIndex].owner, "Not the project owner");

        require(_milestoneIndex < userProjects[projectToEditIndex].milestones.length, "Milestone index out of range");

        Milestone storage milestoneToEdit = userProjects[projectToEditIndex].milestones[_milestoneIndex];

        milestoneToEdit.description = _description;
        milestoneToEdit.targetDate = _date;
        milestoneToEdit.releasedAmount = _amount;
        emit MilestoneEdited(_projectId);
    }
        
}