pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./JaJanken.sol";
import "./JaJankenGame.sol";

// SPDX-License-Identifier: GLWTPL
contract JaJankenColiseum is JaJankenGame {
    /**
     * _ticketCost in wei
     */
    constructor(uint256 _ticketCost) JaJankenGame("The JaJanken Coliseum", _ticketCost, 3, 3, 3, 4) {}

    address public queued;

    event PlayerJoin(
        address indexed p
    );

    receive() external payable {
    }

    function joinGame() external payable override(JaJanken) {
        if (msg.value >= (ticketCost + (ticketCost * entranceFee / 100))) {
            if (players[msg.sender].nen == 0) {
                ++alivePlayers;
            }
            players[msg.sender].nen += startNen;
            totalGuu += (startTechniques - players[msg.sender].guu);
            totalPaa += (startTechniques - players[msg.sender].paa);
            totalChi += (startTechniques - players[msg.sender].chi);
            players[msg.sender].guu = startTechniques;
            players[msg.sender].paa = startTechniques;
            players[msg.sender].chi = startTechniques;
            balance += ticketCost;
            fees += ticketCost * entranceFee / 100;
            emit PlayerJoin({p : msg.sender});
        } else {
            sink += msg.value;
        }
    }

    function joinMatch() external override(JaJanken) {
        require(queued != msg.sender, "You are already in the queue.");
        require(players[msg.sender].inMatch == address(0), "You are already in a match.");
        require(players[msg.sender].nen > 0, "You do not have enough Nen to start a match.");
        if (queued == address(0)) {
            queued = msg.sender;
        } else {
            matches[queued].p2 = msg.sender;
            players[queued].inMatch = queued;
            players[msg.sender].inMatch = queued;
            emit MatchStart({matchId : queued, p1 : queued, p2 : msg.sender});
            queued = address(0);
        }
    }

    function playMatch(bytes32 _commitment, address _matchId) external override(JaJanken) {
        if (msg.sender == _matchId) {
            matches[_matchId].p1Hidden = _commitment;
        } else if (msg.sender == matches[_matchId].p2) {
            matches[_matchId].p2Hidden = _commitment;
        } else {
            revert("You do not belong to this match.");
        }
        if (matches[_matchId].playTime != 0) {
            emit MatchPlayed(_matchId);
        }
        matches[_matchId].playTime = block.timestamp;
    }

    function forfeitMatch(address _matchId) external override(JaJanken) {
        address _p2;

        if (msg.sender == _matchId) {
            _p2 = matches[_matchId].p2;
        } else if (msg.sender == matches[_matchId].p2) {
            _p2 = _matchId;
        } else {
            revert("You do not belong to this match.");
        }

        --players[msg.sender].nen;
        ++players[_p2].nen;
        players[msg.sender].inMatch = address(0);
        players[_p2].inMatch = address(0);
        Match memory newMatch;
        matches[_matchId] = newMatch;
        emit MatchEnd({p1 : msg.sender, p2 : _p2, p1Played : Technique.None, p2Played : Technique.None, winner : _p2});
    }

    function revealMatch(Technique _action, bytes32 _revealKey, address _matchId) external override(JaJanken) {
        Match memory _match = matches[_matchId];

        if (msg.sender == _matchId) {
            require(this.encodeAction(msg.sender, _action, _revealKey) == _match.p1Hidden, "invalid action");
            matches[_matchId].p1Revealed = _action;
            matches[_matchId].revealTime = block.timestamp;
            if (_match.p2Revealed != Technique.None) {
                executeMatch(_matchId, _match.p2, _action, _match.p2Revealed);
            }
        } else if (msg.sender == _match.p2) {
            require(this.encodeAction(msg.sender, _action, _revealKey) == _match.p2Hidden, "invalid action");
            matches[_matchId].p2Revealed = _action;
            matches[_matchId].revealTime = block.timestamp;
            if (_match.p1Revealed != Technique.None) {
                executeMatch(_matchId, _match.p2, _match.p1Revealed, _action);
            }
        } else {
            revert("You do not belong to this match.");
        }
    }

    function executeMatch(address _p1, address _p2, Technique _p1t, Technique _p2t) internal {
        if (!canUseTechnique(_p1, _p1t)) {
            ++players[_p2].nen;
            --players[_p1].nen;
            useTechnique(_p2, _p2t);
            emit MatchEnd({p1 : _p1, p2 : _p2, p1Played : _p1t, p2Played : _p2t, winner : _p2});
        }
        else if (!canUseTechnique(_p2, _p2t)) {
            ++players[_p1].nen;
            --players[_p2].nen;
            useTechnique(_p1, _p1t);
            emit MatchEnd({p1 : _p1, p2 : _p2, p1Played : _p1t, p2Played : _p2t, winner : _p1});
        } else {
            if (_p1t == _p2t) {
                //draw
                emit MatchEnd({p1 : _p1, p2 : _p2, p1Played : _p1t, p2Played : _p2t, winner : address(0)});
            } else if (techniques[_p1t] == _p2t) {
                ++players[_p1].nen;
                --players[_p2].nen;
                emit MatchEnd({p1 : _p1, p2 : _p2, p1Played : _p1t, p2Played : _p2t, winner : _p1});
            } else {
                ++players[_p2].nen;
                --players[_p1].nen;
                emit MatchEnd({p1 : _p1, p2 : _p2, p1Played : _p1t, p2Played : _p2t, winner : _p2});
            }
            useTechnique(_p1, _p1t);
            useTechnique(_p2, _p2t);
        }
        if (players[_p1].nen == 0 || players[_p2].nen == 0) {
            --alivePlayers;
        }
        players[_p1].inMatch = address(0);
        players[_p2].inMatch = address(0);
        Match memory newMatch;
        matches[_p1] = newMatch;
    }

    function waitingForOpponentToPlay(address _matchId) external view override(JaJanken) returns (bool) {
        Match memory _match = matches[_matchId];

        if (msg.sender != _matchId || msg.sender != _match.p2) {
            revert("You do not belong to this match.");
        }
        if (_match.p1Hidden != 0 && _match.p2Hidden != 0) {
            revert("Both players already played.");
        }
        return (block.timestamp - _match.playTime) / 60 > 2;
    }

    function waitingForOpponentToReveal(address _matchId) external view override(JaJanken) returns (bool) {
        Match memory _match = matches[_matchId];

        if (msg.sender != _matchId || msg.sender != _match.p2) {
            revert("You do not belong to this match.");
        }
        if (_match.p1Hidden == 0 || _match.p2Hidden == 0) {
            revert("One player didn't play yet.");
        }
        return (block.timestamp - _match.revealTime) / 60 > 2;
    }

    function skipAfkDuringPlay(address _matchId) external override(JaJanken) {
        if (this.waitingForOpponentToPlay(_matchId)) {
            if (msg.sender == _matchId) {
                ++players[msg.sender].nen;
                --players[matches[_matchId].p2].nen;
                emit MatchEnd({p1 : msg.sender, p2 : matches[_matchId].p2, p1Played : Technique.None, p2Played : Technique.None, winner : msg.sender});
            } else {
                ++players[msg.sender].nen;
                --players[_matchId].nen;
                emit MatchEnd({p1 : msg.sender, p2 : _matchId, p1Played : Technique.None, p2Played : Technique.None, winner : msg.sender});
            }
        }
    }

    function skipAfkDuringReveal(address _matchId) external override(JaJanken) {
        if (this.waitingForOpponentToReveal(_matchId)) {
            if (msg.sender == _matchId) {
                ++players[msg.sender].nen;
                --players[matches[_matchId].p2].nen;
                emit MatchEnd({p1 : msg.sender, p2 : matches[_matchId].p2, p1Played : Technique.None, p2Played : Technique.None, winner : msg.sender});
            } else {
                ++players[msg.sender].nen;
                --players[_matchId].nen;
                emit MatchEnd({p1 : msg.sender, p2 : _matchId, p1Played : Technique.None, p2Played : Technique.None, winner : msg.sender});
            }
        }
    }


    /**
     * Withdraw gains from the Game
     * only available at the end of the Game, do nothing otherwise
     */
    function withdrawGains() external override(JaJanken) {
        require(players[msg.sender].nen >= minimumNenToEarn, "You did not meet the required Nen for leaving the Coliseum.");
        require(players[msg.sender].paa == 0 && players[msg.sender].chi == 0 && players[msg.sender].guu == 0, "You did not play all your cards yet.");
        require(balance >= players[msg.sender].nen * (ticketCost / startNen), "The Coliseum is out of money for now.");
        (bool success,) = msg.sender.call{value : players[msg.sender].nen * (ticketCost / startNen)}("Enjoy your rewards!");
        require(success, "withdraw failed");
        emit WithdrawRewards({player : msg.sender, amount : players[msg.sender].nen * (ticketCost / startNen)});
    }

}