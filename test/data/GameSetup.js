const Utils = require("../utils/Utils.js");

module.exports = class GameSetup {
    static build(_game, _entranceCost) {
        return {
            game : _game,
            entranceCost : _entranceCost,
            ticketEntrance : Utils.finneyInt("3"),
            ticketFee : (Utils.finneyInt("3") * 3 / 100),
            key : web3.utils.fromAscii("abcd")
        }
    }
}