pragma solidity ^0.7.4;

import "./JaJanken.sol";

contract JaJankenGame is JaJanken {
    string immutable public name;
    address public owner;

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

    receive() public payable {}

    constructor(string memory _name, uint32 _nenCost, uint8 _maxNbGames, uint32 _maxNbPlayerPerGame) public {
        owner = msg.sender;
        name = name;
        nenCost = _nenCost;
        maxNbGames = _maxNbGames;
        maxNbPlayerPerGame = _maxNbPlayerPerGame;
        games.push(Game);
    }

    function joinGame() external returns (uint) {
        if (games.length == lastGameId) {
            games.push(Game);
        }
        games[lastGameId].players.push(Player);

        if (games[lastGameId].players.length == maxNbPlayerPerGame) {
            lastGameId += 1;
            emit StartGame(lastGameId);
        }
        return lastGameId;
    }

    function playTurn() external{

    }

    function revealTurn() external {

    }


    function isGameFull(uint _gameId) private view returns (bool success, bool isFull) {
        if (games.length <= _gameId) {
            return (false, false);
        }
        return (true, games[_gameId].players.length <= maxNbPlayerPerGame);
    }



}