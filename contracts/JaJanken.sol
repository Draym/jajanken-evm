pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GLWTPL
interface JaJanken {

    enum Technique {
        None,
        Guu,
        Paa,
        Chi
    }

    struct Player {
        uint8 guu;
        uint8 paa;
        uint8 chi;
        uint32 nen;
        address inMatch;
    }

    struct Opponent {
        uint32 nen;
        uint8 techniques;
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

    event MatchStart(
        address matchId,
        address indexed p1,
        address indexed p2
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
     * Join a queue in order to find an opponent to fight against
     * -> Should emit a StartMatch event when an opponent is found
     */
    function joinMatch() external;

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
    function playMatch(bytes32 _commitment, address _matchId) external;

    /**
     * Reveal the player's action for his current match
     * It is required to send the player's action with the key used to hash it previously for platMatch method
     * -> Should emit a MatchEnd event when the last player of the Match reveal his play
     */
    function revealMatch(Technique _action, bytes32 _revealKey, address _matchId) external;

    /**
     * The player decide to forfeit and quit the specified match
     * No card will be used from either players
     * -> Should emit a MatchEnd event
     */
    function forfeitMatch(address _matchId) external;


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
    function getPlayer(address _player) external view returns (Opponent memory);

    /**
     * Get the number of player alive in the game
     */
    function getTotalPlayers() external view returns (uint);
    /**
     * Get the number of Guu from alive players
     */
    function getTotalGuu() external view returns (uint);
    /**
     * Get the number of Paa from alive players
     */
    function getTotalPaa() external view returns (uint);
    /**
     * Get the number of Chi from alive players
     */
    function getTotalChi() external view returns (uint);
}