const Utils = require("../Utils.js");
const PlayerAction = require("./PlayerAction.js");

module.exports = class GameAction {

    static async playTurn(setup, _p1Address, _p1Action, _p2Address, _p2Action) {
        const _matchId = _p1Address
        await PlayerAction.joinMatch(setup, _p1Address, 1)
        await PlayerAction.joinMatch(setup, _p2Address, 2)
        await PlayerAction.commitPlay(setup, _p1Action, _p1Address, _matchId, true)
        await PlayerAction.commitPlay(setup, _p2Action, _p2Address, _matchId, false)
        await PlayerAction.revealPlay(setup, _p1Action, _p1Address, _matchId, true)
        await PlayerAction.revealPlay(setup, _p2Action, _p2Address, _matchId, false)
        const match = await setup.game.matches(_matchId)
        assert.equal(match.p2, Utils.nullAddress())
    }
}