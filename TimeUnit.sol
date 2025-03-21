// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0; 

// https://www.geeksforgeeks.org/time-units-in-solidity/
contract TimeUnit { 
      
    // Declaring a state variable that will store the current block timestamp
    // as seconds since Unix epoch (January 1, 1970)
    uint256 public startTime; 
    
    // Setting the startTime variable
    // Ensure that this is only called when the contract is ready to start timing
    function setStartTime() public { 
        startTime = block.timestamp; 
    } 
    
    // Calculates the number of seconds elapsed since the startTime was set
    function elapsedSeconds() public view returns (uint256) { 
        require(startTime != 0, "Start time not set");
        return (block.timestamp - startTime); 
    } 
    
    // Resets the start time to 0
    function resetTime() public {
        startTime = 0;
    }
    
    // Calculates the number of minutes elapsed since the startTime was set
    function elapsedMinutes() public view returns (uint256) { 
        require(startTime != 0, "Start time not set");
        return (block.timestamp - startTime) / 1 minutes; 
    } 
}