pragma solidity >=0.8.2 <=0.9.0;

import "./5_ProjectCreation.sol";

contract Funding is ProjectCreation {
    event Funded(uint projectId, address contributor, uint amount);

    mapping(address => mapping(uint => uint)) public balances; // Stores the balances of contributors for each project
    mapping(address => mapping(uint => mapping(address => uint))) public contribution; // Stores the contribution amount of each contributor for each project

    function fundProject(address _owner, uint _projectId, uint _amount) public payable {
        require(msg.value == _amount, "Sent value does not match the input amount");

        // Retrieve the projects owned by the given owner
        Project[] storage userProjects = projects[_owner];

        for(uint i = 0; i < userProjects.length; i++) {
            // Check if the project matches the provided project ID and has not been deleted
            if(userProjects[i].projectId == _projectId && !userProjects[i].isDeleted) {
                // Increase the total contribution of the project
                userProjects[i].totalContribution += _amount;

                // Update the balance of the contributor
                balances[_owner][_projectId] += _amount;

                // Update the contribution amount of the specific contributor for the project
                contribution[_owner][_projectId][msg.sender] += _amount;

                // Emit an event to indicate that the project has been funded
                emit Funded(_projectId, msg.sender, _amount);

                return;
            }
        }

        // Revert the transaction if the project is not found or has been deleted
        revert("Project not found or has been deleted");
    }
}