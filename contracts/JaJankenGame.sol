pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./JaJanken.sol";
import "./SignerGuardian.sol";

// SPDX-License-Identifier: GLWTPL
contract JaJankenGame is JaJanken, SignerGuardian {
    string public name;
    address public immutable owner;

    mapping(address => Player) internal players;
    mapping(address => Match) public matches;
    mapping(Technique => Technique) internal techniques;

    uint256 public balance;
    uint256 public sink;
    uint256 public fees;

    uint256 public totalRed;
    uint256 public totalGreen;
    uint256 public totalBlue;

    uint256 internal immutable ticketCost;
    uint256 internal ticketFee;
    uint8 internal entranceFee;
    uint8 internal immutable minimumSoulToEarn;
    uint8 internal immutable startSoul;
    uint8 internal immutable startTechniques;

    constructor(
        string memory _name,
        address _signer,
        uint256 _ticketCost,
        uint8 _entranceFee,
        uint8 _minimumSoulToEarn,
        uint8 _startSoul,
        uint8 _startTechniques
    ) SignerGuardian(_signer) {
        name = _name;
        owner = msg.sender;
        techniques[Technique.Red] = Technique.Blue;
        techniques[Technique.Green] = Technique.Red;
        techniques[Technique.Blue] = Technique.Green;
        entranceFee = _entranceFee;
        startSoul = _startSoul;
        startTechniques = _startTechniques;
        minimumSoulToEarn = _minimumSoulToEarn;
        ticketCost = _ticketCost;
        ticketFee = _ticketCost * _entranceFee / 100;
    }

    receive() external payable {
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function updateEntranceFee(uint8 _entranceFee) external override(JaJanken) onlyOwner {
        entranceFee = _entranceFee;
        ticketFee = ticketCost * entranceFee / 100;
    }

    function entranceTicketFee() external view override(JaJanken) returns (uint256) {
        return ticketCost + ticketFee;
    }

    function encodeAction(address _yourAddress, Technique _action, bytes32 _revealKey) external pure override(JaJanken) returns (bytes32) {
        return keccak256(abi.encodePacked(_yourAddress, _action, _revealKey));
    }

    function _verifyMatchAccess(address _p1, address _p2, bytes memory _matchSig) internal view {
        require(msg.sender == _p1 || msg.sender == _p2, "You do not belong to this match.");
        require(_verifyMessage(keccak256(abi.encodePacked(_p1, 'vs', _p2)), _matchSig), "This match is invalid.");
    }

    function getProfile() external view override(JaJanken) returns (Player memory) {
        return players[msg.sender];
    }

    function getPlayer(address _player) external view override(JaJanken) returns (Player memory) {
        return players[_player];
    }

    function getTotalRed() external view override(JaJanken) returns (uint) {
        return totalRed;
    }

    function getTotalGreen() external view override(JaJanken) returns (uint) {
        return totalGreen;
    }

    function getTotalBlue() external view override(JaJanken) returns (uint) {
        return totalBlue;
    }

    /**
     * Withdraw fees earning from the Game
     * only available for game owner
     */
    function withdrawFees() external onlyOwner {
        uint amount = fees;
        fees = 0;
        (bool success,) = msg.sender.call{value: amount}("withdraw fees");
        require(success, "withdraw Fees failed");
    }

    /**
     * Cleanup sink
     * only available for game owner
     */
    function cleanupSink() external onlyOwner {
        uint amount = sink;
        sink = 0;
        (bool success,) = msg.sender.call{value: amount}("cleanup sink");
        require(success, "withdraw Sink failed");
    }

    function canUseTechnique(address _p, Technique _technique) internal view returns (bool) {
        if (_technique == Technique.Red) {
            return players[_p].red > 0;
        }
        else if (_technique == Technique.Green) {
            return players[_p].green > 0;
        }
        else if (_technique == Technique.Blue) {
            return players[_p].blue > 0;
        }
        else {
            revert("Wrong technique");
        }
    }

    function useTechnique(address _p, Technique _technique) internal {
        if (_technique == Technique.Red) {
            --players[_p].red;
            --totalRed;
        }
        else if (_technique == Technique.Green) {
            --players[_p].green;
            --totalGreen;
        }
        else if (_technique == Technique.Blue) {
            --players[_p].blue;
            --totalBlue;
        }
        else {
            revert("Wrong technique");
        }
    }

    function joinGame() external payable override(JaJanken) {
        uint256 payment = msg.value;
        if (payment >= (ticketCost + ticketFee)) {
            Player memory currentPlayer = players[msg.sender];
            Player memory newPlayer = Player({
                soul: startSoul + currentPlayer.soul,
                red: startTechniques,
                green: startTechniques,
                blue: startTechniques
            });

            if (startTechniques - currentPlayer.red > 0)
                totalRed += (startTechniques - currentPlayer.red);
            if (startTechniques - currentPlayer.green > 0)
                totalGreen += (startTechniques - currentPlayer.green);
            if (startTechniques - currentPlayer.blue > 0)
                totalBlue += (startTechniques - currentPlayer.blue);

            players[msg.sender] = newPlayer;
            balance += ticketCost;
            fees += payment - ticketCost;
            emit PlayerJoin({p: msg.sender});
        } else {
            sink += payment;
        }
    }

    function playMatch(bytes32 _commitment, address _p1, address _p2, bytes memory _matchSig) external override(JaJanken) {
        _verifyMatchAccess(_p1, _p2, _matchSig);
        if (msg.sender == _p1) {
            matches[_p1].p1Hidden = _commitment;
        } else {
            matches[_p1].p2Hidden = _commitment;
        }
        if (matches[_p1].playTime != 0) {
            emit MatchPlayed(_p1);
        }
        matches[_p1].playTime = block.timestamp;
    }

    function revealMatch(Technique _action, bytes32 _revealKey, address _p1, address _p2, bytes memory _matchSig) external override(JaJanken) {
        _verifyMatchAccess(_p1, _p2, _matchSig);

        Match memory _match = matches[_p1];
        if (msg.sender == _p1) {
            require(this.encodeAction(msg.sender, _action, _revealKey) == _match.p1Hidden, "invalid action");
            matches[_p1].p1Revealed = _action;
            matches[_p1].revealTime = block.timestamp;
            if (_match.p2Revealed != Technique.None) {
                executeMatch(_p1, _match.p2, _action, _match.p2Revealed);
            }
        } else {
            require(this.encodeAction(msg.sender, _action, _revealKey) == _match.p2Hidden, "invalid action");
            matches[_p1].p2Revealed = _action;
            matches[_p1].revealTime = block.timestamp;
            if (_match.p1Revealed != Technique.None) {
                executeMatch(_p1, _match.p2, _match.p1Revealed, _action);
            }
        }
    }

    function executeMatch(address _p1, address _p2, Technique _p1t, Technique _p2t) internal {
        if (!canUseTechnique(_p1, _p1t)) {
            ++players[_p2].soul;
            --players[_p1].soul;
            useTechnique(_p2, _p2t);
            emit MatchEnd({p1: _p1, p2: _p2, p1Played: _p1t, p2Played: _p2t, winner: _p2});
        }
        else if (!canUseTechnique(_p2, _p2t)) {
            ++players[_p1].soul;
            --players[_p2].soul;
            useTechnique(_p1, _p1t);
            emit MatchEnd({p1: _p1, p2: _p2, p1Played: _p1t, p2Played: _p2t, winner: _p1});
        } else {
            if (_p1t == _p2t) { //draw
                emit MatchEnd({p1: _p1, p2: _p2, p1Played: _p1t, p2Played: _p2t, winner: address(0)});
            } else if (techniques[_p1t] == _p2t) {
                ++players[_p1].soul;
                --players[_p2].soul;
                emit MatchEnd({p1: _p1, p2: _p2, p1Played: _p1t, p2Played: _p2t, winner: _p1});
            } else {
                ++players[_p2].soul;
                --players[_p1].soul;
                emit MatchEnd({p1: _p1, p2: _p2, p1Played: _p1t, p2Played: _p2t, winner: _p2});
            }
            useTechnique(_p1, _p1t);
            useTechnique(_p2, _p2t);
        }
        Match memory newMatch;
        matches[_p1] = newMatch;
    }

    function _waitingForOpponentToPlay(address _matchId) internal view returns (bool) {
        Match memory _match = matches[_matchId];

        if (msg.sender != _matchId || msg.sender != _match.p2) {
            revert("You do not belong to this match.");
        }
        if ((msg.sender == _matchId && _match.p2Hidden != 0) || _match.p1Hidden != 0) {
            return false;
        }
        return (block.timestamp - _match.playTime) / 60 > 2;
    }

    function _waitingForOpponentToReveal(address _matchId) internal view returns (bool) {
        Match memory _match = matches[_matchId];

        if (msg.sender != _matchId || msg.sender != _match.p2) {
            revert("You do not belong to this match.");
        }
        if (_match.p1Hidden == 0 || _match.p2Hidden == 0) {
            return false;
        }
        if ((msg.sender == _matchId && _match.p2Revealed != Technique.None) || _match.p1Revealed != Technique.None) {
            return false;
        }
        return (block.timestamp - _match.revealTime) / 60 > 2;
    }

    function waitingForOpponentToPlay(address _matchId) external view override(JaJanken) returns (bool) {
        return _waitingForOpponentToPlay(_matchId);
    }

    function waitingForOpponentToReveal(address _matchId) external view override(JaJanken) returns (bool) {
        return _waitingForOpponentToReveal(_matchId);
    }

    function skipAfkDuringPlay(address _matchId) external override(JaJanken) {
        require(_waitingForOpponentToPlay(_matchId) == false, "Opponent already played.");
        if (msg.sender == _matchId) {
            ++players[msg.sender].soul;
            --players[matches[_matchId].p2].soul;
            emit MatchEnd({p1: msg.sender, p2: matches[_matchId].p2, p1Played: Technique.None, p2Played: Technique.None, winner: msg.sender});
        } else {
            ++players[msg.sender].soul;
            --players[_matchId].soul;
            emit MatchEnd({p1: msg.sender, p2: _matchId, p1Played: Technique.None, p2Played: Technique.None, winner: msg.sender});
        }
    }

    function skipAfkDuringReveal(address _matchId) external override(JaJanken) {
        require(_waitingForOpponentToReveal(_matchId) == false, "Opponent already revealed.");
        if (msg.sender == _matchId) {
            ++players[msg.sender].soul;
            --players[matches[_matchId].p2].soul;
            emit MatchEnd({p1: msg.sender, p2: matches[_matchId].p2, p1Played: Technique.None, p2Played: Technique.None, winner: msg.sender});
        } else {
            ++players[msg.sender].soul;
            --players[_matchId].soul;
            emit MatchEnd({p1: msg.sender, p2: _matchId, p1Played: Technique.None, p2Played: Technique.None, winner: msg.sender});
        }
    }

    /**
     * Withdraw gains from the Game
     * only available at the end of the Game, do nothing otherwise
     */
    function withdrawGains() external override(JaJanken) {
        require(players[msg.sender].soul >= minimumSoulToEarn, "You did not meet the required Soul for leaving the Coliseum.");
        require(players[msg.sender].green == 0 && players[msg.sender].blue == 0 && players[msg.sender].red == 0, "You did not play all your cards yet.");
        require(balance >= players[msg.sender].soul * (ticketCost / startSoul), "The Coliseum is out of money for now.");
        uint32 soul = players[msg.sender].soul;
        players[msg.sender].soul = 0;
        (bool success,) = msg.sender.call{value: soul * (ticketCost / startSoul)}("Enjoy your rewards!");
        require(success, "withdraw failed");
        emit WithdrawRewards({player: msg.sender, amount: soul * (ticketCost / startSoul)});
    }
}