pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./JaJanken.sol";
import "./JaJankenGame.sol";

// SPDX-License-Identifier: GLWTPL
contract JaJankenRestricted is JaJankenGame {
    uint32 immutable public maxNbPlayerPerGame;
    uint countPlayers;

    event StartGame();
    event EndGame(address[] winners);

    constructor(uint32 _nenCost, uint8 _maxNbGames, uint32 _maxNbPlayerPerGame, uint8 _minimumNenToEarn) JaJankenGame("JaJanken Restricted Game", _nenCost, 3, 3, 3, 4) {
        maxNbPlayerPerGame = _maxNbPlayerPerGame;
    }


    receive() external payable {}

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
     * Withdraw gains from the Game
     * only available at the end of the Game, do nothing otherwise
     */
    function withdrawGains() external override(JaJanken) {
        require(gameState == GameState.GameEnded, "The game didn't end yet");
        require(players[msg.sender].nen >= minimumNenToEarn, "You did not meet the required Nen amount.");
        require(balance >= players[msg.sender].nen * nenCost, "The Game is out of money.");
        (bool success,) = msg.sender.call{value : players[msg.sender].nen * nenCost}("Enjoy your rewards!");
        require(success, "withdraw failed");
    }
}