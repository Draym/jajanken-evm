const JaJankenGame = artifacts.require('JaJankenGame')

module.exports = async function (deployer, network, accounts) {
    // Deploy Mock JaJankenColiseum
    await deployer.deploy(JaJankenGame,
        '0x5d097492e2FB156696Ad1f16cB5C478cFcAEBAEB',
        3000000000000000,
        10,
        3,
        3,
        3
    )
};
