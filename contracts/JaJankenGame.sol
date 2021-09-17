pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./JaJanken.sol";

// SPDX-License-Identifier: GLWTPL
abstract contract JaJankenGame is JaJanken {
    enum GameState {
        None,
        PlayMatch,
        RevealMatch,
        GameEnded
    }

    string public name;
    address public immutable owner;

    mapping(address => Player) internal players;
    mapping(address => Match) public matches;
    mapping(Technique => Technique) internal techniques;
    GameState internal gameState;

    uint256 public balance;
    uint256 public sink;
    uint256 public fees;

    uint256 internal immutable ticketCost;
    uint8 internal immutable minimumNenToEarn;
    uint8 internal immutable entranceFee;
    uint8 internal immutable startNen;
    uint8 internal immutable startTechniques;

    constructor(
        string memory _name,
        uint256 _ticketCost,
        uint8 _minimumNenToEarn,
        uint8 _entranceFee,
        uint8 _startNen,
        uint8 _startTechniques
    ) {
        name = _name;
        owner = msg.sender;
        techniques[Technique.Guu] = Technique.Chi;
        techniques[Technique.Paa] = Technique.Guu;
        techniques[Technique.Chi] = Technique.Paa;
        entranceFee = _entranceFee;
        startNen = _startNen;
        startTechniques = _startTechniques;
        minimumNenToEarn = _minimumNenToEarn;
        ticketCost = _ticketCost;
    }


    function entranceTicketFee() external view override(JaJanken) returns (uint256) {
        return ticketCost + (ticketCost * entranceFee / 100);
    }

    function getProfile() external view override(JaJanken) returns (Player memory) {
        return players[msg.sender];
    }

    function getPlayer(address _player) external view override(JaJanken) returns (Opponent memory) {
        return Opponent({
        nen : players[_player].nen,
        techniques : players[_player].guu + players[_player].paa + players[_player].chi
        });
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    /**
     * Withdraw fees earning from the Game
     * only available for game owner
     */
    function withdrawFees() external onlyOwner {
        (bool success,) = msg.sender.call{value : fees}("withdraw fees");
        require(success, "withdraw failed");
    }

    /**
     * Cleanup sink
     * only available for game owner
     */
    function cleanupSink() external onlyOwner {
        (bool success,) = msg.sender.call{value : sink}("cleanup sink");
        require(success, "withdraw failed");
    }
}