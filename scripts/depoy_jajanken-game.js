// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat")

async function main() {
    const game = await hre.ethers.deployContract("JaJankenGame", [
        '0x5d097492e2FB156696Ad1f16cB5C478cFcAEBAEB',
        3000000000000000,
        10,
        3,
        3,
        3]
    )
    await game.waitForDeployment()
    console.log(`JaJankenGame with deployed to ${game.target}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
