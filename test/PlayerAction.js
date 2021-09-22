const TestVerify = require("./TestVerify.js");
const Utils = require("./Utils.js");

module.exports = class PlayerAction {

    static async joinGame(setup, _playerAddress, _nbPlayers) {
        await setup.game.joinGame({from: _playerAddress, value: web3.utils.toWei(setup.entranceCost.toString(), "wei")})
        await TestVerify.verifyBalance(setup, setup.ticketEntrance * _nbPlayers, 0, setup.ticketFee * _nbPlayers)
        await TestVerify.verifyPlayerState(setup, _playerAddress, 3, 12)
        const nbPlayers = await setup.game.getTotalPlayers();
        assert.equal(nbPlayers, _nbPlayers)
    }

    static async joinMatch(setup, _playerAddress, _nbPlayers) {
        await setup.game.joinMatch({from: _playerAddress})
        const queue = await setup.game.queued();
        if (_nbPlayers === 1) {
            assert.equal(queue, _playerAddress)
        } else {
            assert.equal(queue, Utils.nullAddress())
        }
    }

    static async commitPlay(setup, action, _playerAddress, isFirst) {
        let play = await setup.game.encodeAction(_playerAddress, action, setup.key)
        await setup.game.playMatch(play, setup.game.address, {from: _playerAddress})
        const match = await setup.game.matches(setup.game.address)
        if (isFirst) {
            assert.equal(match.p1Hidden, play)
        } else {
            assert.equal(match.p2Hidden, play)
            assert.equal(match.p2, _playerAddress)
        }
    }

    static async revealPlay(setup, _playerAddress) {
        await setup.game.joinMatch({from: _playerAddress})
    }
}