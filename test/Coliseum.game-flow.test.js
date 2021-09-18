const JaJankenColiseum = artifacts.require('JaJankenColiseum')

require('chai')
    .use(require('chai-as-promised'))
    .should()

function eth(n) {
    return web3.utils.toWei(n, 'ether');
}

function finney(n) {
    return web3.utils.toWei(n, 'finney');
}

function finneyInt(n) {
    return parseInt(web3.utils.toWei(n, 'finney'));
}

contract('JaJankenColiseum', ([owner, player1Address, player2Address]) => {
    let coliseum
    let entranceCost
    let ticketEntrance = finneyInt("3")
    let ticketFee = (finneyInt("3") * 3 / 100)

    async function verifyBalance(_balance, _sink, _fees) {
        const balance = await coliseum.balance()
        const sink = await coliseum.sink()
        const fees = await coliseum.fees()
        console.log("balance: ", balance)
        assert.equal(balance.toString(), _balance.toString())
        assert.equal(sink.toString(), _sink.toString())
        assert.equal(fees.toString(), _fees.toString())
        console.log("ok: ")
    }

    async function verifyPlayerState(_address, _nen, _cards) {
        const player = await coliseum.getPlayer(_address)
        assert.equal(player[0].toString(), _nen.toString())
        assert.equal(player[1].toString(), _cards.toString())
    }

    function encodePlay(_play, _key) {
        const encoded = web3.eth.abi.encodeParameters(['uint256', 'bytes32'],[_play, _key])
        return web3.utils.sha3(encoded, {encoding: 'hex'})
    }

    before(async () => {
        coliseum = await JaJankenColiseum.new(finney("3"))
        const cost = await coliseum.entranceTicketFee()
        entranceCost = parseInt(cost.toString())
    })

    describe('JaJankenColiseum deployment', async () => {
        it('coliseum setup', async () => {
            const name = await coliseum.name()
            assert.equal(name, "The JaJanken Coliseum")

            const entrance = finneyInt("3")
            const fee = finneyInt("3") * 3 / 100
            assert.equal(entranceCost.toString(), (entrance + fee).toString())

            const address = await coliseum.address
            console.log("address: ", address)
        })
    })

    describe('Players Play Game', async () => {
        it('players join game', async () => {
            console.log("player1:", player1Address)
            console.log("player2:", player2Address)

            let send = await coliseum.joinGame({from: player1Address, value: web3.utils.toWei(entranceCost.toString(), "wei")})
            await verifyBalance(ticketEntrance, 0, ticketFee)

            let send2 = await coliseum.joinGame({from: player2Address, value: web3.utils.toWei(entranceCost.toString(), "wei")})
            await verifyBalance(ticketEntrance * 2, 0, ticketFee * 2)

            await verifyPlayerState(player1Address, 3, 12)
            await verifyPlayerState(player2Address, 3, 12)

            /** Join Match **/
            await coliseum.joinMatch({from: player1Address})
            await coliseum.joinMatch({from: player2Address})
            let gameAddress = player1Address
            const match1a = await coliseum.matches(gameAddress)
            assert.equal(match1a.p2, player2Address)

            /** Commit Play **/
            let key = web3.utils.fromAscii("abcd")
            let play1 = await coliseum.encodeAction(player1Address, 1, key)
            await coliseum.playMatch(play1, gameAddress, {from: player1Address})
            let play2 = await coliseum.encodeAction(player2Address, 2, key)
            await coliseum.playMatch(play2, gameAddress, {from: player2Address})
            const match1b = await coliseum.matches(gameAddress)
            assert.equal(match1b.p2, player2Address)
            assert.equal(match1b.p1Hidden, play1)
            assert.equal(match1b.p2Hidden, play2)

            /** Reveal Play **/
            await coliseum.revealMatch(1, key, gameAddress, {from: player1Address})
            await coliseum.revealMatch(2, key, gameAddress, {from: player2Address})
            const match1c = await coliseum.matches(gameAddress)
            assert.equal(parseInt(match1c.pPlayed.toString()), 2)
            await verifyPlayerState(player1Address, 2, 11)
            await verifyPlayerState(player2Address, 4, 11)
        })
    })
})