import TestVerify from "../verify/TestVerify";
import {assert} from "chai";
import {ethers} from "ethers";

const joinGame = async (setup, _playerAddress, _nbPlayers) => {
    await setup.game.joinGame({from: _playerAddress, value: ethers.formatUnits(setup.entranceCost.toString(), "wei")})
    await TestVerify.verifyGameBalance(setup, setup.ticketEntrance * _nbPlayers, 0, setup.ticketFee * _nbPlayers)
    await TestVerify.verifyPlayerState(setup, _playerAddress, 3, 12)
}
const commitPlay = async (setup, action, _playerAddress, _matchId, isFirst) => {
    let play = await setup.game.encodeAction(_playerAddress, action, setup.key)
    await setup.game.playMatch(play, _matchId, {from: _playerAddress})
    const match = await setup.game.matches(_matchId)
    if (isFirst) {
        assert.equal(match.p1Hidden, play)
    } else {
        assert.equal(match.p2Hidden, play)
    }
}

const revealPlay = async (setup, action, _playerAddress, _matchId, isP1, isLast) => {
    await setup.game.revealMatch(action, setup.key, _matchId, {from: _playerAddress})
    const match = await setup.game.matches(_matchId)
    if (isLast) {
        assert.equal(match.p2, Utils.nullAddress())
    } else if (isP1) {
        assert.equal(match.p1Revealed, action)
    } else {
        assert.equal(match.p2Revealed, action)
    }
}

export default {joinGame, commitPlay, revealPlay}