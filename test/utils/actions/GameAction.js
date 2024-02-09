import {expect} from "chai"
import Utils from "../Utils"
import PlayerAction from "./PlayerAction"

const playTurn = async (setup, _p1Address, _p1Action, _p2Address, _p2Action, _matchSig) => {
    const _matchId = _p1Address
    await PlayerAction.commitPlay(setup, _p1Action, _p1Address, _p2Address, _matchSig, true)
    await PlayerAction.commitPlay(setup, _p2Action, _p2Address,  _p2Address, _matchSig, false)
    await PlayerAction.revealPlay(setup, _p1Action, _p1Address,  _p2Address, _matchSig, true, false)
    await PlayerAction.revealPlay(setup, _p2Action, _p2Address,  _p2Address, _matchSig, false, true)
    const match = await setup.game.matches(_matchId)
    expect(match.p2).equal(Utils.nullAddress())
}

export default {playTurn}