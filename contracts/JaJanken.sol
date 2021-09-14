pragma solidity ^0.7.4;

interface JaJanken {

    function joinGame() external returns (uint);

    function playTurn() external returns ();

    function revealTurn() external returns ();

    /**
     * Withdraw gains from the Game
     * only available at the end of the Game, do nothing otherwise
     */
    function withdrawGains() external returns ();

    /**
     *
     */
    function waitingForPlayers() external view returns (bool);

    function skipAfkPlayers() external;

    // game state
    function getOpponent() external view returns (uint8 nen, uint8 totalCards);
}