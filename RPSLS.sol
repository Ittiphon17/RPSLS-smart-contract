// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./TimeUnit.sol";
import "./CommitReveal.sol";

contract RPSLS {
    CommitReveal private immutable commitReveal;
    TimeUnit private immutable timeUnit;

    uint public reward;
    uint8 public numPlayer;
    mapping(address => bytes32) public commits;
    mapping(address => uint8) public revealedChoice;
    address[2] public players;
    address constant player1 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address constant player2 = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address constant player3 = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address constant player4 = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;

    constructor() {
        timeUnit = new TimeUnit(); 
        commitReveal = new CommitReveal();
    }

    modifier onlyAllowedPlayers() {
        require(msg.sender == player1 || msg.sender == player2 || msg.sender == player3 || msg.sender == player4, "You Not allowed");
        _; // Executes the main function after this point
    }

    modifier onlyInGame() {
        require(numPlayer == 2, "Game not started");
        _; // Executes the main function after this point
    }

    function addPlayer() external payable onlyAllowedPlayers {
        require(numPlayer < 2, "Game full");
        require(msg.value == 1 ether, "Must send 1 ETH");
        if (numPlayer == 1) require(msg.sender != players[0], "Same player");
        
        players[numPlayer] = msg.sender;
        numPlayer++;
        reward += msg.value;

        if (numPlayer == 1) {
            timeUnit.setStartTime();
        } else {
            timeUnit.resetTime();
            timeUnit.setStartTime();
        }
    }

    function _checkWinnerAndPay() private {
        uint8 p0Choice = revealedChoice[players[0]];
        uint8 p1Choice = revealedChoice[players[1]];

        address payable winner;
        if (_winsAgainst(p0Choice, p1Choice)) {
            winner = payable(players[0]);
        } else if (_winsAgainst(p1Choice, p0Choice)) {
            winner = payable(players[1]);
        } else {
            payable(players[0]).transfer(reward / 2);
            payable(players[1]).transfer(reward / 2);
            _resetGame();
            return;
        }

        winner.transfer(reward);
        _resetGame();
    }

    function _winsAgainst(uint8 choice1, uint8 choice2) private pure returns (bool) {
        return (choice1 == 0 && (choice2 == 2 || choice2 == 3)) || 
               (choice1 == 1 && (choice2 == 0 || choice2 == 4)) || 
               (choice1 == 2 && (choice2 == 1 || choice2 == 3)) || 
               (choice1 == 3 && (choice2 == 1 || choice2 == 4)) || 
               (choice1 == 4 && (choice2 == 0 || choice2 == 2));
    }

    function checkTimeout() external {
        require(numPlayer == 1, "Game not in timeout state");
        if (timeUnit.elapsedSeconds() >= 120) {
            payable(players[0]).transfer(1 ether);
            _resetGame();
        } 
    }

    function checkTimeoutTwoPlayers() external onlyInGame {
        require(msg.sender == players[0] || msg.sender == players[1], "Invalid player");
        if (timeUnit.elapsedSeconds() >= 120) {
            payable(players[0]).transfer(1 ether);
            payable(players[1]).transfer(1 ether);
            _resetGame();
        }
    }

    function getElapsedTime() external view returns (uint256) {
        return timeUnit.elapsedSeconds();
    }

    function commitChoice(bytes32 commitHash) external onlyInGame {
        require(commits[msg.sender] == 0, "Already committed");
        commitReveal.commit(commitHash);
        commits[msg.sender] = commitHash;
    }

    function revealChoice(uint8 choice, bytes32 nonce) external onlyInGame {
        require(commits[msg.sender] != 0, "No commit found");
        require(revealedChoice[msg.sender] == 0, "Already revealed");

        bytes32 revealHash = keccak256(abi.encodePacked(choice, nonce));
        commitReveal.reveal(revealHash);
        revealedChoice[msg.sender] = choice;

        if (revealedChoice[players[0]] != 0 && revealedChoice[players[1]] != 0) {
            _checkWinnerAndPay();
        }
    }

    function _resetGame() private {
        delete players;
        delete commits[players[0]];
        delete commits[players[1]];
        delete revealedChoice[players[0]];
        delete revealedChoice[players[1]];
        numPlayer = 0;
        reward = 0;
    }
}
