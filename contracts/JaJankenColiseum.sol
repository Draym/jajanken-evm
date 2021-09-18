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

    address queued;

    receive() external payable {
    }

    function joinGame() external payable override(JaJanken) {
        if (msg.value >= (ticketCost + (ticketCost * entranceFee / 100))) {
            players[msg.sender].nen += startNen;
            players[msg.sender].guu = startTechniques;
            players[msg.sender].paa = startTechniques;
            players[msg.sender].chi = startTechniques;
            balance += ticketCost;
            fees += ticketCost * entranceFee / 100;
        } else {
            sink += msg.value;
        }
    }

    function joinMatch() external override(JaJanken) {
        require(players[msg.sender].nen > 0, "You do not have enough Nen to start a match.");
        if (queued == address(0)) {
            queued = msg.sender;
        } else {
            matches[queued].p2 = msg.sender;
            emit MatchStart(queued, queued, msg.sender);
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

    function encodeAction(address _yourAddress, Technique _action, bytes32 _revealKey) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_yourAddress, _action, _revealKey));
    }

    function revealMatch(Technique _action, bytes32 _revealKey, address _matchId) external override(JaJanken) {
        Match memory _match = matches[_matchId];

        if (msg.sender == _matchId)
        {
            require(this.encodeAction(msg.sender, _action, _revealKey) == _match.p1Hidden, "invalid action");
            if (_match.pPlayed != Technique.None) {
                playMatch(_matchId, _match.p2, _action, _match.pPlayed);
            } else {
                matches[_matchId].pPlayed = _action;
            }
        } else if (msg.sender == _match.p2) {
            require(this.encodeAction(msg.sender, _action, _revealKey) == _match.p2Hidden, "invalid action");
            if (_match.pPlayed != Technique.None) {
                playMatch(_matchId, _match.p2, _match.pPlayed, _action);
            } else {
                matches[_matchId].pPlayed = _action;
            }
        } else {
            revert("You do not belong to this match.");
        }
        matches[_matchId].revealTime = block.timestamp;
    }

    function playMatch(address _p1, address _p2, Technique _p1t, Technique _p2t) private {
        if (!canUseTechnique(_p1, _p1t)) {
            ++players[_p2].nen;
            --players[_p1].nen;
            emit MatchEnd(_p1, _p2, _p2);
        }
        if (!canUseTechnique(_p2, _p2t)) {
            ++players[_p1].nen;
            --players[_p2].nen;
            emit MatchEnd(_p1, _p2, _p1);
        }
        useTechnique(_p1, _p1t);
        useTechnique(_p2, _p2t);
        if (_p1t == _p2t) {
            //draw
            emit MatchEnd(_p1, _p2, _p1);
        } else if (techniques[_p1t] == _p2t) {
            ++players[_p1].nen;
            --players[_p2].nen;
            emit MatchEnd(_p1, _p2, _p1);
        } else {
            ++players[_p2].nen;
            --players[_p1].nen;
            emit MatchEnd(_p1, _p2, _p2);
        }
        Match memory newMatch;
        matches[_p1] = newMatch;
    }

    function canUseTechnique(address _p, Technique _technique) private view returns (bool) {
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

    function useTechnique(address _p, Technique _technique) private {
        if (_technique == Technique.Guu) {
            --players[_p].guu;
        }
        else if (_technique == Technique.Paa) {
            --players[_p].paa;
        }
        else if (_technique == Technique.Chi) {
            --players[_p].chi;
        }
        else {
            revert("Wrong technique");
        }
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
                emit MatchEnd(msg.sender, matches[_matchId].p2, msg.sender);
            } else {
                ++players[msg.sender].nen;
                --players[_matchId].nen;
                emit MatchEnd(msg.sender, _matchId, msg.sender);
            }
        }
    }

    function skipAfkDuringReveal(address _matchId) external override(JaJanken) {
        if (this.waitingForOpponentToReveal(_matchId)) {
            if (msg.sender == _matchId) {
                ++players[msg.sender].nen;
                --players[matches[_matchId].p2].nen;
                emit MatchEnd(msg.sender, matches[_matchId].p2, msg.sender);
            } else {
                ++players[msg.sender].nen;
                --players[_matchId].nen;
                emit MatchEnd(msg.sender, _matchId, msg.sender);
            }
        }
    }


    /**
     * Withdraw gains from the Game
     * only available at the end of the Game, do nothing otherwise
     */
    function withdrawGains() external override(JaJanken) {
        require(players[msg.sender].nen >= minimumNenToEarn, "You did not meet the required Nen for leaving the Coliseum.");
        require(players[msg.sender].paa != 0 || players[msg.sender].chi != 0 || players[msg.sender].guu != 0, "You did not play all your cards yet.");
        require(balance >= players[msg.sender].nen * ticketCost, "The Coliseum is out of money for now.");
        (bool success,) = msg.sender.call{value : players[msg.sender].nen * ticketCost}("Enjoy your rewards!");
        require(success, "withdraw failed");
    }

}