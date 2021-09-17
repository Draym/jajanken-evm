pragma solidity ^0.7.4;

import "./JaJanken.sol";

// SPDX-License-Identifier: GLWTPL
contract JaJankenGame is JaJanken {
    string constant public name = "JaJanken Restricted Manager";
    address immutable public owner;

    uint32 immutable public nenCost;
    uint8 immutable public maxNbGames;
    uint32 immutable public maxNbPlayerPerGame;

    struct Game {
        Player[] players;
    }

    struct Turn {
        uint dummy;
    }

    struct Player {
        address playerId;
        uint8 nen;
        uint8[3] cards;
    }

    event StartGame(
        uint _gameId
    );

    Game[] games;
    uint public lastGameId;

    receive() external payable {}

    constructor(uint32 _nenCost, uint8 _maxNbGames, uint32 _maxNbPlayerPerGame) {
        owner = msg.sender;
        nenCost = _nenCost;
        maxNbGames = _maxNbGames;
        maxNbPlayerPerGame = _maxNbPlayerPerGame;
        games.push();
    }

    function joinGame() external returns (uint) {
        if (games.length == lastGameId) {
            games.push();
        }
        games[lastGameId].players.push();

        if (games[lastGameId].players.length == maxNbPlayerPerGame) {
            lastGameId += 1;
            emit StartGame(lastGameId);
        }
        return lastGameId;
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

    function isGameFull(uint _gameId) private view returns (bool success, bool isFull) {
        if (games.length <= _gameId) {
            return (false, false);
        }
        return (true, games[_gameId].players.length <= maxNbPlayerPerGame);
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

}