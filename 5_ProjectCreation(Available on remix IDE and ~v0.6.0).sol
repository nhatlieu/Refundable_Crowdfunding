// SPDX-FileCopyrightText: 2023 Nhat Lieu <nhatlieu@firensor.com>
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "./4_UserRegistration.sol";


// The contract that allows users to create and manage projects
contract ProjectCreation is UserRegistration {
    uint projectNum = 1; // Counter to keep track of project IDs
    mapping(address => Project[]) public projects; // Mapping from user address to array of projects
    mapping(address => uint) public activeProjectCounts;

    // Events that get emitted on various actions
    event ProjectCreated(uint projectId, address owner, string projectName, uint fundingGoal, uint deadline);
    event ProjectEdited(uint projectId);
    event ProjectDeleted(uint projectId);
    event MilestoneCreated(uint projectId, string description, uint targetDate, uint releasedAmount);
    event MilestoneEdited(uint projectId, string description, uint targetDate, uint releasedAmount);
    event MilestoneProposed(address from, address to, uint projectid, uint milestoneIndex, string description, uint targetDate, uint releasedAmount);

    // Structure to hold milestone data
    struct Milestone {
        string description;
        uint targetDate;
        uint releasedAmount;
    }

    // Structure to hold project data
    struct Project {
        address owner;
        uint projectId;
        string projectName;
        uint fundingGoal;
        uint deadline;
        bool isDeleted; // Marks if a project has been deleted
        uint totalContribution; // Total amount of money contributed
        Milestone[] milestones; // Array to hold the milestones of the project
    }

    // function to find own projects based on projectId
    function findProject(uint _projectId) internal view returns (Project storage) {
        Project[] storage userProjects = projects[msg.sender];
        for (uint i = 0; i < userProjects.length; i++) {
            if (userProjects[i].projectId == _projectId) {
                return (userProjects[i]);
            }
        }
        revert("Project not found");
    }

    // function to find other person's projects based on address and projectId
    function findOtherProject (address _address, uint _projectId) internal view returns (Project storage) {
        Project[] storage userProjects = projects[_address];
        for (uint i = 0; i < userProjects.length; i++) {
            if (userProjects[i].projectId == _projectId) {
                return (userProjects[i]);
            }
        }
        revert("Project not found");        
    }

    // Function to create a new project
    function createProject(string memory _name, uint _amount, uint _numberOfDays) public {
        Project storage newProject = projects[msg.sender].push();
        newProject.owner = msg.sender;
        newProject.projectId = projectNum++;
        newProject.projectName = _name;
        newProject.fundingGoal = _amount;
        newProject.deadline = block.timestamp + (_numberOfDays * 1 days);
        activeProjectCounts[msg.sender] += 1; // Increment active project counter


        emit ProjectCreated(projectNum, msg.sender, _name, _amount, newProject.deadline); // Emit the ProjectCreated event
    }

    // Function to edit an existing project
    function editProject(uint _projectId, string memory _name, uint _amount, uint _deadline) public {
        Project storage projectToEdit = findProject(_projectId);
        require(!projectToEdit.isDeleted, "Project has been deleted");
        require(msg.sender == projectToEdit.owner, "Not the project owner");

        // Update the project details
        projectToEdit.projectName = _name;
        projectToEdit.fundingGoal = _amount;
        projectToEdit.deadline = _deadline;

        emit ProjectEdited(_projectId); // Emit the ProjectEdited event


    }

    // Function to delete a project
    function deleteProject(uint _projectId) public {
        Project storage projectToDelete = findProject(_projectId);
        require(!projectToDelete.isDeleted, "Project has been deleted");
        require(msg.sender == projectToDelete.owner, "Not the project owner");

        // Mark the project as deleted
        projectToDelete.isDeleted = true;
        activeProjectCounts[msg.sender] -= 1; // Decrease active project count

        emit ProjectDeleted(_projectId); // Emit the ProjectDeleted event
    }

    // Function to create a new milestone
    function fillMilestone(uint _projectId, string memory _description, uint _date, uint _amount) public {
        Project storage projectToUpdate = findProject(_projectId);
        require(!projectToUpdate.isDeleted, "Project has been deleted");
        require(msg.sender == projectToUpdate.owner, "Not the project owner");

        // Create the new milestone and add it to the project
        Milestone memory newMilestone = Milestone({description: _description, targetDate: _date, releasedAmount: _amount});
        projectToUpdate.milestones.push(newMilestone);

        emit MilestoneCreated(_projectId, _description, _date, _amount); // Emit the MilestoneCreated event
    }

    // Function to edit an existing milestone
    function editMilestone(uint _projectId, uint _milestoneIndex, string memory _description, uint _date, uint _amount) public {
        Project storage projectToEdit = findProject(_projectId);
        require(!projectToEdit.isDeleted, "Project has been deleted");
        require(msg.sender == projectToEdit.owner, "Not the project owner");
        require(_milestoneIndex < projectToEdit.milestones.length, "Milestone index out of range");

        // Update the milestone details
        Milestone storage milestoneToEdit = projectToEdit.milestones[_milestoneIndex];
        milestoneToEdit.description = _description;
        milestoneToEdit.targetDate = _date;
        milestoneToEdit.releasedAmount = _amount;

        emit MilestoneEdited(_projectId, _description, _date, _amount); // Emit the MilestoneEdited event
    }

    // Function to propose a milestone to another user
    function proposeMilestone(address _address, uint _projectId, uint _milestoneIndex, string memory _description, uint _date, uint _amount) public {
        Project storage projectToPropose = findOtherProject(_address, _projectId);(_projectId);
        require(!projectToPropose.isDeleted, "Project has been deleted");
        require(_milestoneIndex < projectToPropose.milestones.length, "Milestone index out of range");

        // Update the proposed milestone details
        Milestone storage newProposingMilestone = projectToPropose.milestones[_milestoneIndex];
        newProposingMilestone.description = _description;
        newProposingMilestone.targetDate = _date;
        newProposingMilestone.releasedAmount = _amount;

        emit MilestoneProposed(msg.sender, _address, _projectId, _milestoneIndex, _description, _date, _amount); // Emit the MilestoneProposed event
    }    
    
    // Function to get the basic information of a project
    function getProjectBasicInfo(address _owner, uint _projectIndex) public view returns(address, uint, string memory, uint, uint) {
        Project storage project = projects[_owner][_projectIndex];
        require(!project.isDeleted, "Project has been deleted"); // Check that the project isn't deleted
        return (project.owner, project.projectId, project.projectName, project.fundingGoal, project.deadline); // Return the basic project details
    }

    // Function to get the details of a milestone
    function getProjectMilestone(address _owner, uint _projectIndex, uint _milestoneIndex) public view returns(string memory, uint, uint) {
        require(!projects[_owner][_projectIndex].isDeleted, "Project has been deleted"); // Check that the project isn't deleted
        Milestone storage milestone = projects[_owner][_projectIndex].milestones[_milestoneIndex]; // Get the milestone
        return (milestone.description, milestone.targetDate, milestone.releasedAmount); // Return the milestone details
    }
    
    // Function to get the number of active projects of a user
    function retrieveActiveProjects(address _address) public view returns(uint) {
        return activeProjectCounts[_address]; // Return the number of active projects
    }
}
