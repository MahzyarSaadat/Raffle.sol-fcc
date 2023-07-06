const { network, ethers } = require("hardhat")
const { deploymentChains } = require("../helper-hardhat-config")

const BASE_FEE = ethers.utils.parseEther("0.25")
const GAS_PRICE_LINK = 1e9

module.exports = async ({ deployments, getNamedAccounts }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()

    const args = [BASE_FEE, GAS_PRICE_LINK]

    if (deploymentChains.includes(network.name)) {
        log("Local network detected!deploying mock ...")
        await deploy("VRFCoordinatorV2Mock", {
            contract: "VRFCoordinatorV2Mock",
            from: deployer,
            log: true,
            args: args,
        })
        log("mock deploying !")
        log("-------------------------------------------")
    }
}

module.exports.tags = ["all", "mock"]
