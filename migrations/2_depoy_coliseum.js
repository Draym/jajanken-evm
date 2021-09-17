const JaJankenColiseum = artifacts.require('JaJankenColiseum')

module.exports = async function (deployer,  network, accounts) {
    // Deploy Mock JaJankenColiseum
    await deployer.deploy(JaJankenColiseum, 3000000000000000)
};
