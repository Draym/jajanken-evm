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

    uint256 public alivePlayers;
    uint256 public totalGuu;
    uint256 public totalPaa;
    uint256 public totalChi;

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

    function encodeAction(address _yourAddress, Technique _action, bytes32 _revealKey) external pure override(JaJanken) returns (bytes32) {
        return keccak256(abi.encodePacked(_yourAddress, _action, _revealKey));
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

    function getTotalPlayers() external view override(JaJanken) returns (uint) {
        return alivePlayers;
    }

    function getTotalGuu() external view override(JaJanken) returns (uint) {
        return totalGuu;
    }

    function getTotalPaa() external view override(JaJanken) returns (uint) {
        return totalPaa;
    }

    function getTotalChi() external view override(JaJanken) returns (uint) {
        return totalChi;
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
        uint amount = fees;
        fees = 0;
        (bool success,) = msg.sender.call{value : amount}("withdraw fees");
        require(success, "withdraw Fees failed");
    }

    /**
     * Cleanup sink
     * only available for game owner
     */
    function cleanupSink() external onlyOwner {
        uint amount = sink;
        sink = 0;
        (bool success,) = msg.sender.call{value : amount}("cleanup sink");
        require(success, "withdraw Sink failed");
    }

    function canUseTechnique(address _p, Technique _technique) internal view returns (bool) {
        if (_technique == Technique.Guu) {
            return players[_p].guu > 0;
        }
        else if (_technique == Technique.Paa) {
            return players[_p].paa > 0;
        }
        else if (_technique == Technique.Chi) {
            return players[_p].chi > 0;
        }
        else {
            revert("Wrong technique");
        }
    }

    function useTechnique(address _p, Technique _technique) internal {
        if (_technique == Technique.Guu) {
            --players[_p].guu;
            --totalGuu;
        }
        else if (_technique == Technique.Paa) {
            --players[_p].paa;
            --totalPaa;
        }
        else if (_technique == Technique.Chi) {
            --players[_p].chi;
            --totalChi;
        }
        else {
            revert("Wrong technique");
        }
    }
}