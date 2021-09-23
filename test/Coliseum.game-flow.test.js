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

    beforeEach(async () => {
        console.log("--------- NEW CONTRACT --------")
        coliseum = await JaJankenColiseum.new(Utils.finney("3"))
        const cost = await coliseum.entranceTicketFee()
        setup = GameSetup.build(coliseum, parseInt(cost.toString()))
    })

    afterEach(async () => {
    });

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

    describe('Players can Join', async () => {
            it('players join game', async () => {
                await PlayerAction.joinGame(setup, player1Address, 1)
                await PlayerAction.joinGame(setup, player2Address, 2)
            })
            it('players join match', async () => {
                await PlayerAction.joinGame(setup, player1Address, 1)
                await PlayerAction.joinGame(setup, player2Address, 2)
                await PlayerAction.joinMatch(setup, player1Address, 1)
                await PlayerAction.joinMatch(setup, player2Address, 2)
                const match = await coliseum.matches(player1Address)
                assert.equal(match.p2, player2Address)
            })
        }
    )

    describe('Players can Play', async () => {
        beforeEach(async () => {
            console.log("--# new Game #--")
            await PlayerAction.joinGame(setup, player1Address, 1)
            await PlayerAction.joinGame(setup, player2Address, 2)
            await PlayerAction.joinMatch(setup, player1Address, 1)
            await PlayerAction.joinMatch(setup, player2Address, 2)
            const match = await coliseum.matches(player1Address)
            assert.equal(match.p2, player2Address)
        })

        it('players play first turn', async () => {
            const matchId = player1Address
            /** Commit Play **/
            await PlayerAction.commitPlay(setup, 1, player1Address, matchId, true)
            await PlayerAction.commitPlay(setup, 2, player2Address, matchId, false)
            const match1b = await coliseum.matches(matchId)
            assert.equal(match1b.p2, player2Address)

            /** Reveal Play **/
            await PlayerAction.revealPlay(setup, 1, player1Address, matchId, true)
            await PlayerAction.revealPlay(setup, 2, player2Address, matchId, false)

            await TestVerify.verifyPlayerState(setup, player1Address, 2, 11)
            await TestVerify.verifyPlayerState(setup, player2Address, 4, 11)
        })
    })
})