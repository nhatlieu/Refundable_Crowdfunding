pragma solidity >=0.8.2 <0.9.0;

contract userRegistration {

    address owner;
    mapping(address => uint) public registeredTimes;    
    mapping(address => string) public username;
    
    constructor() {
         owner = msg.sender;
         }
    
    function Registered() internal {
        registeredTimes[msg.sender] ++;
        }

    function setUser(string memory _name) public {
        require(registeredTimes[msg.sender] < 1);
        username[msg.sender] = _name;
        Registered();
    }

    function myUsername() public view returns(string memory) {
        return(username[msg.sender]);
    }

    function myRegisteredTimes() public view returns(uint) {
        return(registeredTimes[msg.sender]);
    }
}