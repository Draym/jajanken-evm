pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./JaJanken.sol";

// SPDX-License-Identifier: GLWTPL
contract JaJankenRestricted is JaJanken {
    string constant public name = "JaJanken Restricted Game";
    address immutable public owner;

    uint32 immutable public nenCost;
    uint32 immutable public maxNbPlayerPerGame;


    event StartGame();

    event EndGame(address[] winners);

    mapping(address => Player) players;
    uint countPlayers;

    receive() external payable {}

    constructor(uint32 _nenCost, uint8 _maxNbGames, uint32 _maxNbPlayerPerGame) {
        owner = msg.sender;
        nenCost = _nenCost;
        maxNbPlayerPerGame = _maxNbPlayerPerGame;
    }

    function joinGame() external {
        if (countPlayers < maxNbPlayerPerGame) {
            ++countPlayers;
        } else if (countPlayers == maxNbPlayerPerGame) {
            emit StartGame();
        }
    }


    function joinMatch() external override(JaJanken) {
        // TODO
    }

    function playMatch(bytes32 _commitment, address _matchId) external override(JaJanken) {
        // TODO
    }

    function revealMatch(Technique _action, bytes32 _revealKey, address _matchId) external override(JaJanken) {
        // TODO
    }


    function withdrawGains() external override(JaJanken) {
        // TODO
    }

    function isGameFull() private view returns (bool isFull) {
        return countPlayers == maxNbPlayerPerGame;
    }

    function waitingForOpponentToPlay(address _matchId) external view override(JaJanken) returns (bool) {
        // TODO
        return true;
    }

    function waitingForOpponentToReveal(address _matchId) external view override(JaJanken) returns (bool){
        // TODO
        return true;
    }

    function skipAfkDuringPlay(address _matchId) external override(JaJanken) {
        // TODO
    }

    function skipAfkDuringReveal(address _matchId) external override(JaJanken) {
        // TODO
    }

    /**
     * Get your profile stat for the current Game
     */
    function getProfile() external view override(JaJanken) returns (Player memory) {
        return players[msg.sender];
    }

    /**
     * Get the player profile stat for the current Game
     */
    function getPlayer(address _player) external view override(JaJanken) returns (Opponent memory) {
        return Opponent({
        nen : players[_player].nen,
        techniques : players[_player].guu + players[_player].paa + players[_player].chi
        });
    }
}