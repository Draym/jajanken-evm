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

            const player1 = await coliseum.getPlayer(player1Address)
            const player2 = await coliseum.getPlayer(player2Address)
            console.log("player1: ", player1)
            console.log("player2: ", player2)

            assert.equal(player1[0], "3")
            assert.equal(player1[1], "12")
            assert.equal(player2[0], "3")
            assert.equal(player2[1], "12")
        })
    })
})