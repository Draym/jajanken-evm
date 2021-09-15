pragma solidity ^0.7.4;

import "./JaJanken.sol";

contract JaJankenColiseum is JaJanken {
    string constant public name = "The JaJanken Coliseum";
    address public owner;

    function() public payable {}

    constructor() public {
        owner = msg.sender;
    }

    struct Player {
        uint8 nen;
        uint8 guu;
        uint8 paa;
        uint8 chi;
    }

    mapping(address => Player) public players;

function receive() external payable {

}

function playTurn() external returns () {

}

function revealTurn() external returns () {

}

}