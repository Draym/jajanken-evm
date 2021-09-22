module.exports = class TestVerify {
    static async verifyBalance(setup, _balance, _sink, _fees) {
        const balance = await setup.game.balance();
        const sink = await setup.game.sink();
        const fees = await setup.game.fees();
        console.log("balance: ", balance);
        assert.equal(balance.toString(), _balance.toString(), "incorrect balance");
        assert.equal(sink.toString(), _sink.toString(), "incorrect sing");
        assert.equal(fees.toString(), _fees.toString(), "incorrect fees");
        console.log("ok: ");
    }

    static async verifyPlayerState(setup, _address, _nen, _cards) {
        const player = await setup.game.getPlayer(_address);
        assert.equal(player[0].toString(), _nen.toString(), "incorrect nen");
        assert.equal(player[1].toString(), _cards.toString(), "incorrect cards");
    }
}