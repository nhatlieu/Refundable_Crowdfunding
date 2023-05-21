// SPDX-FileCopyrightText: 2023 Nhat Lieu <nhatlieu@firensor.com>
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

// Importing the Ownable contract from the OpenZeppelin library
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

// The UserRegistration contract inherits from the Ownable contract, and provides functionality for registering users
contract UserRegistration is Ownable {
    // Mapping of addresses to the number of times they have registered
    mapping(address => uint) public registeredTimes;
    // Mapping of addresses to usernames
    mapping(address => string) public username;
    // The fee required for registration after the 5th time
    uint256 fee = 10000000000000000;

    // Event that is emitted when a user registers
    event UserRegistered(address _address, string _name);

    // Function to register a user
    function setUser(string memory _name) public payable {
        // If the user has registered more than 5 times, require the registration fee
        if (registeredTimes[msg.sender] > 5) {
            require(msg.value >= fee, "Not enough Ether provided.");
        }
        // Increment the registration count for the user and set their username
        registeredTimes[msg.sender] += 1;
        username[msg.sender] = _name;
        emit UserRegistered(msg.sender, _name);
    }

    // Function to get the username of the caller
    function myUsername() public view returns(string memory) {
        return(username[msg.sender]);
    }

    // Function to get the registration count of the caller
    function myRegisteredTimes() public view returns(uint) {
        return(registeredTimes[msg.sender]);
    }

    // Function to get the username of a given address
    function searchUsername(address _address) public view returns(string memory) {
        return (username[_address]);
    }

    // Function to withdraw the funds of the contract, only callable by the owner
    function withdraw() onlyOwner public {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }
}
