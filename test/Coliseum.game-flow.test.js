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

contract('JaJankenColiseum', ([owner, player1, player2]) => {
    let coliseum

    before(async () => {
        coliseum = await JaJankenColiseum.new(finney(1))
    })

    describe('Player Join Game', async () => {
    })
})