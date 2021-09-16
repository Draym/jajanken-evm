pragma solidity ^0.7.4;

interface JaJanken {


    function joinMatch() external;

    function playMatch(bytes32 _commitment, address _matchId) external;

    function revealMatch(uint8 _action, bytes32 _revealKey, address _matchId) external;

    /**
     * Withdraw gains from the Game
     * only available at the end of the Game, do nothing otherwise
     */
    function withdrawGains() external;

    function waitingForOpponentToPlay(address _matchId) external view returns (bool);
    function waitingForOpponentToReveal(address _matchId) external view returns (bool);

    function skipAfkDuringPlay(address _matchId) external;
    function skipAfkDuringReveal(address _matchId) external;
}