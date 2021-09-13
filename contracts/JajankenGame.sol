pragma solidity ^0.5.16;

contract JajankenGame {
    string constant public name = "Jajanken Game Manager";
    address public owner;

    uint32 constant public nenCost = 1;
    mapping(address => uint32) public userNenBalance;
    mapping(address => uint32) public userAuth;


    constructor() public {
        owner = msg.sender;
    }
}