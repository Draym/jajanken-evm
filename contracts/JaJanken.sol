pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GLWTPL
interface JaJanken {

    enum Technique {
        None,
        Red,
        Green,
        Blue
    }

    struct Player {
        uint8 red;
        uint8 green;
        uint8 blue;
        uint32 soul;
    }

    struct Match {
        address p2;
        bytes32 p1Hidden;
        bytes32 p2Hidden;
        Technique p1Revealed;
        Technique p2Revealed;
        uint256 playTime;
        uint256 revealTime;
    }

    event PlayerJoin(
        address indexed p
    );

    event MatchPlayed(
        address indexed matchId // p1
    );

    event MatchEnd(
        address indexed p1,
        address indexed p2,
        Technique p1Played,
        Technique p2Played,
        address winner
    );

    event WithdrawRewards(
        address indexed player,
        uint256 amount
    );

    /**
     * Update the entrance fee for the game
     */
    function updateEntranceFee(uint8 _entranceFee) external;

    /*
     * Return the required fee in Wei to pay to receive the game starter pack
     * /!\ depending on implementation, the pack may be given only if the value is enough to buy the entrance ticket
     */
    function entranceTicketFee() external view returns (uint256);

    /**
     * Join a game, the caller must pay the required entrance ticket amount in ETH
     */
    function joinGame() external payable;

    /**
     * Encode the specified technique
     * Should be used to generate a hashed value in order to commit secretly the player action for playMatch
     */
    function encodeAction(address _yourAddress, Technique _action, bytes32 _revealKey) external pure returns (bytes32);

    /**
     * Commit the player's action for his current match
     * The action(Technique) must be hashed with a bytes32 key. so it can be saved with his hidden form.
     * -> Should emit a MatchPlayed event when the last player of the Match commit his play
     */
    function playMatch(bytes32 _commitment, address _p1, address _p2, bytes memory _matchSig) external;

    /**
     * Reveal the player's action for his current match
     * It is required to send the player's action with the key used to hash it previously for playMatch method
     * -> Should emit a MatchEnd event when the last player of the Match reveal his play
     */
    function revealMatch(Technique _action, bytes32 _revealKey, address _p1, address _p2, bytes memory _matchSig) external;

    /**
     * Withdraw gains from the Game
     * send rewards to the the players if he meets the withdrawal conditions, do nothing otherwise
     */
    function withdrawGains() external;

    /**
     * This method will check if your opponent didn't play yet
     * If this method return true, you will be allowed to call skipAfkDuringPlay to pass the turn of your opponent and win the match
     */
    function waitingForOpponentToPlay(address _matchId) external view returns (bool);

    /**
     * This method will check if your opponent didn't reveal his play yet
     * If this method return true, you will be allowed to call skipAfkDuringReveal to pass the turn of your opponent and win the match
     */
    function waitingForOpponentToReveal(address _matchId) external view returns (bool);

    /**
     * Kick your opponent from the match if conditions are met. You will win this match by default
     */
    function skipAfkDuringPlay(address _matchId) external;

    /**
     * Kick your opponent from the match if conditions are met. You will win this match by default
     */
    function skipAfkDuringReveal(address _matchId) external;

    /**
     * Get your profile stat for the current Game
     */
    function getProfile() external view returns (Player memory);

    /**
     * Get the player profile stat for the current Game
     */
    function getPlayer(address _player) external view returns (Player memory);

    /**
     * Get the number of Red from alive players
     */
    function getTotalRed() external view returns (uint);
    /**
     * Get the number of Green from alive players
     */
    function getTotalGreen() external view returns (uint);
    /**
     * Get the number of Blue from alive players
     */
    function getTotalBlue() external view returns (uint);
}