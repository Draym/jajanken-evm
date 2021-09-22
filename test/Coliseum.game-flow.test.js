const TestVerify = require("./TestVerify.js");
const PlayerAction = require("./PlayerAction.js");
const GameSetup = require("./GameSetup.js");
const Utils = require("./Utils.js");
const JaJankenColiseum = artifacts.require('JaJankenColiseum')

require('chai')
    .use(require('chai-as-promised'))
    .should()


contract('JaJankenColiseum', ([owner, player1Address, player2Address]) => {
    let coliseum
    let setup


    function encodePlay(_play, _key) {
        const encoded = web3.eth.abi.encodeParameters(['uint256', 'bytes32'], [_play, _key])
        return web3.utils.sha3(encoded, {encoding: 'hex'})
    }

    before(async () => {
        coliseum = await JaJankenColiseum.new(Utils.finney("3"))
        const cost = await coliseum.entranceTicketFee()
        setup = GameSetup.build(coliseum, parseInt(cost.toString()))
    })

    describe('JaJankenColiseum deployment', async () => {
        it('coliseum setup', async () => {
            const name = await coliseum.name()
            assert.equal(name, "The JaJanken Coliseum")

            const entrance = Utils.finneyInt("3")
            const fee = Utils.finneyInt("3") * 3 / 100
            assert.equal(setup.entranceCost.toString(), (entrance + fee).toString(), "The entrance fee is incorrect")

            const address = await coliseum.address
            console.log("address: ", address)
        })
    })

    describe('Players Join Game', async () => {
        it('players join game', async () => {
            await PlayerAction.joinGame(setup, player1Address, 1)
            await PlayerAction.joinGame(setup, player2Address, 2)
        })
    })

    describe('Players Join Match', async () => {
        it('players join game', async () => {
            await PlayerAction.joinGame(setup, player1Address, 1)
            await PlayerAction.joinGame(setup, player2Address, 2)
        })
        it('players join match', async () => {
            await PlayerAction.joinMatch(setup, player1Address, 1)
            await PlayerAction.joinMatch(setup, player2Address, 2)
            const match = await coliseum.matches(player1Address)
            assert.equal(match.p2, player2Address)
        })
    })


    describe("Players Cant Join Match", async () => {

        it("players can't join match", async () => {
        })
    })

    describe('Players Play Turns', async () => {
        it('players join game', async () => {
            await PlayerAction.joinGame(setup, player1Address, 1)
            await PlayerAction.joinGame(setup, player2Address, 2)
        })
        it('players join match', async () => {
            await PlayerAction.joinMatch(setup, player1Address, 1)
            await PlayerAction.joinMatch(setup, player2Address, 2)
            const match = await coliseum.matches(player1Address)
            assert.equal(match.p2, player2Address)
        })
        // TODO need to check how Test are executed, before is run only once per contract or not?
        it('players play first turn', async () => {

            /** Commit Play **/
            await PlayerAction.commitPlay(setup, 1, player1Address, true)
            await PlayerAction.commitPlay(setup, 2, player2Address, false)
            const match1b = await coliseum.matches(gameAddress)
            assert.equal(match1b.p2, player2Address)
            assert.equal(match1b.p1Hidden, play1)
            assert.equal(match1b.p2Hidden, play2)

            /** Reveal Play **/
            await coliseum.revealMatch(1, key, gameAddress, {from: player1Address})
            const match1c = await coliseum.matches(gameAddress)
            assert.equal(parseInt(match1c.pPlayed.toString()), 1, "P1 wrong card played")
            await coliseum.revealMatch(2, key, gameAddress, {from: player2Address})
            const match1d = await coliseum.matches(gameAddress)
            assert.equal(match1d.p2, Utils.nullAddress())
            await TestVerify.verifyPlayerState(setup, player1Address, 2, 11)
            await TestVerify.verifyPlayerState(setup, player2Address, 4, 11)
        })
    })
})