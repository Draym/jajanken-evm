const TestVerify = require("./utils/verify/TestVerify.js");
const PlayerAction = require("./utils/actions/PlayerAction.js");
const GameSetup = require("./data/GameSetup.js");
const Utils = require("./utils/Utils.js");
const GameAction = require("./utils/actions/GameAction");
const JaJankenColiseum = artifacts.require('JaJankenColiseum')

require('chai')
    .use(require('chai-as-promised'))
    .should()

const truffleAssert = require('truffle-assertions');
const {ethers} = require("hardhat");

describe("JaJankenGame", function () {
    async function deployGame() {
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners()

        const Lock = await ethers.getContractFactory("Lock")
        const lock = await Lock.deploy(
            '0x5d097492e2FB156696Ad1f16cB5C478cFcAEBAEB',
            3000000000000000,
            10,
            3,
            3,
            3
        )

        return {lock, unlockTime, lockedAmount, owner, otherAccount}
    }

    it("playTurn", async function () {

    })
})

contract('JaJankenColiseum', ([owner, player1Address, player2Address]) => {
    let coliseum
    let setup


    function encodePlay(_play, _key) {
        const encoded = web3.eth.abi.encodeParameters(['uint256', 'bytes32'], [_play, _key])
        return web3.utils.sha3(encoded, {encoding: 'hex'})
    }

    beforeEach(async () => {
        console.log("- NEW CONTRACT -")
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
                await TestVerify.verifyPlayerProfile(setup, player1Address, 3, 4, 4, 4)
                await TestVerify.verifyPlayerProfile(setup, player2Address, 3, 4, 4, 4)
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

    describe('2 Players can Play', async () => {
        beforeEach(async () => {
            console.log("--# new Game #--")
            await PlayerAction.joinGame(setup, player1Address, 1)
            await PlayerAction.joinGame(setup, player2Address, 2)
        })

        it('players play first turn', async () => {
            const matchId = player1Address
            /** Join Match **/
            await PlayerAction.joinMatch(setup, player1Address, 1)
            await PlayerAction.joinMatch(setup, player2Address, 2)
            const match = await coliseum.matches(matchId)
            assert.equal(match.p2, player2Address)

            /** Commit Play **/
            await PlayerAction.commitPlay(setup, 1, player1Address, matchId, true, false)
            await PlayerAction.commitPlay(setup, 2, player2Address, matchId, false, true)

            /** Reveal Play **/
            await PlayerAction.revealPlay(setup, 2, player2Address, matchId, false, false)
            await PlayerAction.revealPlay(setup, 1, player1Address, matchId, true, true)

            await TestVerify.verifyPlayerState(setup, player1Address, 2, 11)
            await TestVerify.verifyPlayerState(setup, player2Address, 4, 11)
        })

        it('players play draw', async () => {
            const matchId = player1Address
            /** Join Match **/
            await PlayerAction.joinMatch(setup, player1Address, 1)
            await PlayerAction.joinMatch(setup, player2Address, 2)
            const match = await coliseum.matches(matchId)
            assert.equal(match.p2, player2Address)

            /** Commit Play **/
            await PlayerAction.commitPlay(setup, 1, player1Address, matchId, true, false)
            await PlayerAction.commitPlay(setup, 1, player2Address, matchId, false, true)

            /** Reveal Play **/
            await PlayerAction.revealPlay(setup, 1, player2Address, matchId, false, false)
            await PlayerAction.revealPlay(setup, 1, player1Address, matchId, true, true)

            await TestVerify.verifyPlayerState(setup, player1Address, 3, 11)
            await TestVerify.verifyPlayerState(setup, player2Address, 3, 11)
        })

        it('players play until P1 gameover', async () => {
            /** Turn 1 **/
            await GameAction.playTurn(setup, player1Address, 1, player2Address, 2)
            await TestVerify.verifyPlayerState(setup, player1Address, 2, 11)
            await TestVerify.verifyPlayerState(setup, player2Address, 4, 11)

            /** Turn 2 **/
            await GameAction.playTurn(setup, player1Address, 2, player2Address, 3)
            await TestVerify.verifyPlayerState(setup, player1Address, 1, 10)
            await TestVerify.verifyPlayerState(setup, player2Address, 5, 10)

            /** Turn 3 **/
            await GameAction.playTurn(setup, player1Address, 3, player2Address, 1)
            await TestVerify.verifyPlayerState(setup, player1Address, 0, 9)
            await TestVerify.verifyPlayerState(setup, player2Address, 6, 9)

            /** P1 GameOver **/
            await truffleAssert.reverts(PlayerAction.joinMatch(setup, player1Address, 1), "You do not have enough Nen to start a match.")
        })
    })

    describe('Player can forfeit', async () => {
        beforeEach(async () => {
            console.log("--# new Game #--")
            await PlayerAction.joinGame(setup, player1Address, 1)
            await PlayerAction.joinGame(setup, player2Address, 2)
        })

        it('forfeit directly', async () => {
            const matchId = player1Address
            /** Join Match **/
            await PlayerAction.joinMatch(setup, player1Address, 1)
            await PlayerAction.joinMatch(setup, player2Address, 2)
            const match = await coliseum.matches(matchId)
            assert.equal(match.p2, player2Address)

            /** Forfeit Play **/
            await PlayerAction.forfeit(setup, player1Address, matchId)

            await TestVerify.verifyPlayerState(setup, player1Address, 2, 12)
            await TestVerify.verifyPlayerState(setup, player2Address, 4, 12)

            const matchFinal = await coliseum.matches(matchId)
            assert.equal(matchFinal.p2, Utils.nullAddress())
        })

        it('forfeit after commit', async () => {
            const matchId = player1Address
            /** Join Match **/
            await PlayerAction.joinMatch(setup, player1Address, 1)
            await PlayerAction.joinMatch(setup, player2Address, 2)
            const match = await coliseum.matches(matchId)
            assert.equal(match.p2, player2Address)

            /** Commit Play **/
            await PlayerAction.commitPlay(setup, 1, player1Address, matchId, true)

            /** Forfeit Play **/
            await PlayerAction.forfeit(setup, player2Address, matchId)

            await TestVerify.verifyPlayerState(setup, player1Address, 4, 12)
            await TestVerify.verifyPlayerState(setup, player2Address, 2, 12)

            const matchFinal = await coliseum.matches(matchId)
            assert.equal(matchFinal.p2, Utils.nullAddress())
        })
    })

    describe('Player Withdraw condition', async () => {
        beforeEach(async () => {
            console.log("--# new Game #--")
            await PlayerAction.joinGame(setup, player1Address, 1)
            await PlayerAction.joinGame(setup, player2Address, 2)
        })
        it("can't leave if less than 3Nen", async () => {
            await GameAction.playTurn(setup, player1Address, 1, player2Address, 2)
            await truffleAssert.reverts(setup.game.withdrawGains({from: player1Address}), "You did not meet the required Nen for leaving the Coliseum.")
        })
        it("can't leave if have cards", async () => {
            await truffleAssert.reverts(setup.game.withdrawGains({from: player1Address}), "You did not play all your cards yet.")
        })
        it("can withdraw", async () => {
            await GameAction.playTurn(setup, player1Address, 1, player2Address, 2)
            await GameAction.playTurn(setup, player1Address, 1, player2Address, 2)
            await GameAction.playTurn(setup, player1Address, 2, player2Address, 1)
            await GameAction.playTurn(setup, player1Address, 2, player2Address, 1)
            await GameAction.playTurn(setup, player1Address, 3, player2Address, 1)
            await GameAction.playTurn(setup, player1Address, 3, player2Address, 1)
            await GameAction.playTurn(setup, player1Address, 1, player2Address, 3)
            await GameAction.playTurn(setup, player1Address, 1, player2Address, 3)
            await GameAction.playTurn(setup, player1Address, 2, player2Address, 3)
            await GameAction.playTurn(setup, player1Address, 2, player2Address, 3)
            await GameAction.playTurn(setup, player1Address, 3, player2Address, 2)
            await GameAction.playTurn(setup, player1Address, 3, player2Address, 2)

            await TestVerify.verifyPlayerState(setup, player1Address, 3, 0)
            await TestVerify.verifyPlayerState(setup, player2Address, 3, 0)

            const balance = await setup.game.balance();
            const fee = await setup.game.entranceTicketFee();
            console.log("game balance: ", balance.toString())
            console.log("game fee: ", fee.toString())

            let pastBalance = await web3.eth.getBalance(player1Address);
            await setup.game.withdrawGains({from: player1Address})
            let actualBalance = await web3.eth.getBalance(player1Address);
            // TODO can check exact balance by calculating gaz cost
            // TODO can check event emitted
            assert.isAbove(parseInt(actualBalance), parseInt(pastBalance), "Balance incorrect!");
        })
    })
})