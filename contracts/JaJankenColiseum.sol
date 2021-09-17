pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./JaJanken.sol";
import "./JaJankenGame.sol";

// SPDX-License-Identifier: GLWTPL
contract JaJankenColiseum is JaJankenGame {
    /**
     * nenCost in wei
     */
    constructor(uint256 _nenCost) JaJankenGame("The JaJanken Coliseum", _nenCost, 3, 3, 3, 4) {}

    address queued;

    receive() external payable {
        if (msg.value >= ((startNen * nenCost) + (startNen * nenCost * entranceFee / 100))) {
            players[msg.sender].nen += startNen;
            players[msg.sender].guu = startTechniques;
            players[msg.sender].paa = startTechniques;
            players[msg.sender].chi = startTechniques;
            balance += (startNen * nenCost);
            fees += (startNen * nenCost * entranceFee / 100);
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
        if (matches[_matchId].pTime != 0) {
            emit MatchPlayed(_matchId);
        }
        matches[_matchId].pTime = block.timestamp;
    }

    function revealMatch(Technique _action, bytes32 _revealKey, address _matchId) external override(JaJanken) {
        Match memory _match = matches[_matchId];

        if (msg.sender == _matchId)
        {
            require(keccak256(abi.encodePacked(msg.sender, _action, _revealKey)) == _match.p1Hidden, "invalid action");
            if (_match.pPlayed != Technique.None) {
                playMatch(_matchId, _match.p2, _action, _match.pPlayed);
            } else {
                _match.pPlayed = _action;
            }
        } else if (msg.sender == _match.p2) {
            require(keccak256(abi.encodePacked(msg.sender, _action, _revealKey)) == _match.p2Hidden, "invalid action");
            if (_match.pPlayed != Technique.None) {
                playMatch(_matchId, _match.p2, _match.pPlayed, _action);
            } else {
                _match.pPlayed = _action;
            }
        } else {
            revert("You do not belong to this match.");
        }
    }

    function playMatch(address _p1, address _p2, Technique _p1t, Technique _p2t) private {
        if (!canUseTechnique(_p1, _p1t)) {
            endMatch(_p2, _p1);
        }
        if (!canUseTechnique(_p2, _p2t)) {
            endMatch(_p1, _p1);
        }
        useTechnique(_p1, _p1t);
        useTechnique(_p2, _p2t);
        if (_p1t == _p2t) {
            //draw
            Match memory newMatch;
            matches[_p1] = newMatch;
        } else if (techniques[_p1t] == _p2t) {
            endMatch(_p1, _p1);
        } else {
            endMatch(_p2, _p1);
        }
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

    function endMatch(address winner, address matchId) private {
        ++players[winner].nen;
        if (winner != matchId) {
            --players[matchId].nen;
        } else {
            address p2 = matches[matchId].p2;
            --players[p2].nen;
        }
        Match memory newMatch;
        matches[matchId] = newMatch;
    }

    function waitingForOpponentToPlay(address _matchId) external view override(JaJanken) returns (bool) {
        Match memory _match = matches[_matchId];

        if (msg.sender != _matchId || msg.sender != _match.p2) {
            revert("You do not belong to this match.");
        }
        if (_match.p1Hidden != 0 && _match.p2Hidden != 0) {
            revert("Both players already played.");
        }
        return (block.timestamp - _match.pTime) / 60 > 2;
    }

    function waitingForOpponentToReveal(address _matchId) external view override(JaJanken) returns (bool) {
        Match memory _match = matches[_matchId];

        if (msg.sender != _matchId || msg.sender != _match.p2) {
            revert("You do not belong to this match.");
        }
        if (_match.p1Hidden == 0 || _match.p2Hidden == 0) {
            revert("One player didn't play yet.");
        }
        return (block.timestamp - _match.pReveal) / 60 > 2;
    }

    function skipAfkDuringPlay(address _matchId) external override(JaJanken) {
        if (this.waitingForOpponentToPlay(_matchId)) {
            endMatch(msg.sender, _matchId);
        }
    }

    function skipAfkDuringReveal(address _matchId) external override(JaJanken) {
        if (this.waitingForOpponentToReveal(_matchId)) {
            endMatch(msg.sender, _matchId);
        }
    }


    /**
     * Withdraw gains from the Game
     * only available at the end of the Game, do nothing otherwise
     */
    function withdrawGains() external override(JaJanken) {
        require(players[msg.sender].nen >= minimumNenToEarn, "You did not meet the required Nen for leaving the Coliseum.");
        require(balance >= players[msg.sender].nen * nenCost, "The Coliseum is out of money for now.");
        (bool success,) = msg.sender.call{value : players[msg.sender].nen * nenCost}("Enjoy your rewards!");
        require(success, "withdraw failed");
    }

}