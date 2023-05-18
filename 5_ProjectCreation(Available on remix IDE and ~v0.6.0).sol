pragma solidity >=0.8.2 <0.9.0;

import "./4_UserRegistration.sol";

// The contract that allows users to create and manage projects
contract ProjectCreation is UserRegistration {

    uint projectNum = 1; // Counter to keep track of project IDs
    mapping(address => Project[]) public projects; // Mapping from user address to array of projects

    // Events that get emitted on various actions
    event ProjectCreated(uint projectId, address owner, string projectName, uint fundingGoal, uint deadline);
    event ProjectEdited(uint projectId);
    event ProjectDeleted(uint projectId);
    event MilestoneCreated(uint projectId, string description, uint targetDate, uint releasedAmount);
    event MilestoneEdited(uint projectId);
    event MilestoneProposed(address from, address to, uint milestoneIndex);

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

    // Function to create a new project
    function createProject(string memory _name, uint _amount, uint _numberOfDays) public {
        Project storage newProject = projects[msg.sender].push();
        newProject.owner = msg.sender;
        newProject.projectId = projectNum;
        newProject.projectName = _name;
        newProject.fundingGoal = _amount;
        newProject.deadline = block.timestamp + (_numberOfDays * 1 days);
        projectNum ++; // Increment the project counter

        emit ProjectCreated(projectNum, msg.sender, _name, _amount, _numberOfDays); // Emit the ProjectCreated event
    }

    // Function to edit an existing project
    function editProject(uint _projectId, string memory _name, uint _amount, uint _deadline) public {
        Project[] storage userProjects = projects[msg.sender];
        uint projectToEditIndex;
        bool projectFound = false;

        // Loop over the projects to find the one to edit
        for (uint i = 0; i < userProjects.length; i++) {
            if (userProjects[i].projectId == _projectId) {
                projectToEditIndex = i;
                projectFound = true;
                break;
            }
        }

        // Check that the project exists and it's not deleted, and that the user is the owner
        require(projectFound, "Project not found");
        require(userProjects[projectToEditIndex].isDeleted == false, "Project has been deleted");
        require(msg.sender == userProjects[projectToEditIndex].owner, "Not the project owner");

        // Update the project details
        userProjects[projectToEditIndex].projectName = _name;
        userProjects[projectToEditIndex].fundingGoal = _amount;
        userProjects[projectToEditIndex].deadline = _deadline;

        emit ProjectEdited(_projectId); // Emit the ProjectEdited event
    }

    // Function to delete a project
    function deleteProject(uint _projectId) public {
        Project[] storage userProjects = projects[msg.sender];
        uint projectIndex;
        bool projectFound = false;

        // Loop over the projects to find the one to delete
        for(uint i = 0; i < userProjects.length; i++) {
            if(userProjects[i].projectId == _projectId) {
                projectIndex =i;
                projectFound = true;
                break;
            }
        }

        // Check that the project exists and that the user is the owner
        require(projectFound, "Project not found");
        require(msg.sender == userProjects[projectIndex].owner, "Not the project owner");

        // Mark the project as deleted
        userProjects[projectIndex].isDeleted = true;
        
        emit ProjectDeleted(_projectId); // Emit the ProjectDeleted event
    }

    // Function to create a new milestone
    function fillMilestone(uint _projectId, string memory _description, uint _date, uint _amount) public {
        Project[] storage userProjects = projects[msg.sender];
        uint projectToUpdateIndex;
        bool projectFound = false;

        // Loop over the projects to find the one to update
        for(uint i = 0; i < userProjects.length; i++) {
            if(userProjects[i].projectId == _projectId) {
                projectToUpdateIndex = i;
                projectFound = true;
                break;
            }
        }

        // Check that the project exists, it's not deleted, and that the user is the owner
        require(projectFound, "Project not found");
        require(userProjects[projectToUpdateIndex].isDeleted == false, "Project has been deleted");
        require(msg.sender == userProjects[projectToUpdateIndex].owner, "Not the project owner");

        // Create the new milestone and add it to the project
        Milestone memory newMilestone = Milestone({description: _description, targetDate: _date, releasedAmount: _amount});
        userProjects[projectToUpdateIndex].milestones.push(newMilestone);

        emit MilestoneCreated(_projectId, _description, _date, _amount); // Emit the MilestoneCreated event
    }

    // Function to edit an existing milestone
    function editMilestone(uint _projectId, uint _milestoneIndex, string memory _description, uint _date, uint _amount) public {
        Project[] storage userProjects = projects[msg.sender];
        uint projectToEditIndex;
        bool projectFound = false;

        // Loop over the projects to find the one to edit
        for(uint i = 0; i < userProjects.length; i++) {
            if(userProjects[i].projectId == _projectId) {
                projectToEditIndex = i;
                projectFound = true;
                break;
            }
        }

        // Check that the project exists, it's not deleted, that the user is the owner, and that the milestone index is valid
        require(projectFound, "Project not found");
        require(userProjects[projectToEditIndex].isDeleted == false, "Project has been deleted");
        require(msg.sender == userProjects[projectToEditIndex].owner, "Not the project owner");
        require(_milestoneIndex < userProjects[projectToEditIndex].milestones.length, "Milestone index out of range");

        // Update the milestone details
        Milestone storage milestoneToEdit = userProjects[projectToEditIndex].milestones[_milestoneIndex];
        milestoneToEdit.description = _description;
        milestoneToEdit.targetDate = _date;
        milestoneToEdit.releasedAmount = _amount;

        emit MilestoneEdited(_projectId); // Emit the MilestoneEdited event
    }

    // Function to propose a milestone to another user
    function proposeMilestone(address _address, uint _projectId, uint _milestoneIndex, string memory _description, uint _date, uint _amount) public {
        Project[] storage userProjects = projects[_address];
        uint projectToProposeIndex;
        bool projectFound = false;

        // Loop over the projects to find the one to propose the milestone for
        for (uint i = 0; i < userProjects.length; i++) {
            if (userProjects[i].projectId == _projectId) {
                projectToProposeIndex = i;
                projectFound = true;
                break;
            }
        }

        // Check that the project exists, it's not deleted, and that the milestone index is valid
        require(projectFound, "Not project found");
        require(userProjects[projectToProposeIndex].isDeleted == false, "Project has been deleted");
        require(_milestoneIndex < userProjects[projectToProposeIndex].milestones.length, "Milestone index out of range");

        // Update the proposed milestone details
        Milestone storage newProposingMilestone = userProjects[projectToProposeIndex].milestones[_milestoneIndex];
        newProposingMilestone.description = _description;
        newProposingMilestone.targetDate = _date;
        newProposingMilestone.releasedAmount = _amount;

        emit MilestoneProposed(msg.sender, _address, _milestoneIndex); // Emit the MilestoneProposed event
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
        Project[] storage userProjects = projects[_address];
        uint activeProjectsCount = 0;
        for(uint i = 0; i < userProjects.length; i++) {
            if(!userProjects[i].isDeleted) { // If the project is not deleted, count it as active
                activeProjectsCount++;
            }
        }
        return activeProjectsCount; // Return the number of active projects
    }
}
