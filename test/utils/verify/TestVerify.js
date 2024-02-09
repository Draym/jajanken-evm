import {assert} from "chai";

const verifyGameBalance = async (setup, _balance, _sink, _fees) => {
    const balance = await setup.game.balance();
    const sink = await setup.game.sink();
    const fees = await setup.game.fees();
    assert.equal(balance.toString(), _balance.toString(), "incorrect balance");
    assert.equal(sink.toString(), _sink.toString(), "incorrect sing");
    assert.equal(fees.toString(), _fees.toString(), "incorrect fees");
}

const verifyPlayerState = async (setup, _address, _soul, _cards) => {
    const player = await setup.game.getPlayer(_address);
    assert.equal(player[0].toString(), _soul.toString(), "incorrect soul");
    assert.equal(player[1].toString(), _cards.toString(), "incorrect cards");
}

const verifyPlayerProfile = async (setup, _address, _soul, _red, _green, _blue) => {
    const player = await setup.game.getProfile({from: _address});
    assert.equal(player[0].toString(), _red.toString(), "incorrect red");
    assert.equal(player[1].toString(), _green.toString(), "incorrect green");
    assert.equal(player[2].toString(), _blue.toString(), "incorrect blue");
    assert.equal(player[3].toString(), _soul.toString(), "incorrect soul");
}

export default {verifyGameBalance, verifyPlayerProfile, verifyPlayerState}