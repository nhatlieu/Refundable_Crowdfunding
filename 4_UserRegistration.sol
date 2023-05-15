pragma solidity >=0.8.2 <0.9.0;

contract UserRegistration {
    address owner; // The owner of the contract
    mapping(address => uint) public registeredTimes; // A mapping to keep track of the number of times a user has registered
    mapping(address => string) public username; // A mapping to store the username of each registered user
    
    uint256 fee = 10000000000000000; // Fee for changing name more than 5 times

    constructor() {
        owner = msg.sender;
    }

    // Function to set or update a user's username
    // Requirements:
    // - User must not have registered or updated their username more than 4 times
    function setUser(string memory _name) public payable {
        
        if (registeredTimes[msg.sender] > 6) {
            require(msg.value >= fee, "Not enough Ether provided.");
        }

        username[msg.sender] = _name;
        registeredTimes[msg.sender]++;
    }

    // Function to get the username of the caller
    // Returns:
    // - The username of the caller
    function myUsername() public view returns(string memory) {
        return(username[msg.sender]);
    }

    // Function to get the number of times the caller has registered or updated their username
    // Returns:
    // - The number of times the caller has registered or updated their username
    function myRegisteredTimes() public view returns(uint) {
        return(registeredTimes[msg.sender]);
    }

    // Function to get the username of a specific user
    // Params:
    // - _address: The address of the user whose username we want to retrieve
    // Returns:
    // - The username of the user
    function searchUsername(address _address) public view returns(string memory) {
        return (username[_address]);
    }

    // Allows the contract owner to withdraw all Ether stored in the contract
    function withdraw() public {
        require(msg.sender == owner, "Only the contract owner can withdraw");
        address payable ownerTransfer;
        ownerTransfer.transfer(address(this).balance);
    }
}
