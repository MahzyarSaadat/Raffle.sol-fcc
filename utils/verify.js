const { run } = require("hardhat")

const verify = async ({ contractAddress, args }) => {
    try {
        run("verify:verify", {
            address: contractAddress,
            constructorArguments: args,
        })
    } catch (error) {
        if (error.message.toLowerCase().includes("already verified")) {
            console.log("already verified")
        } else {
            console.log(error)
        }
    }
}

module.exports = { verify }
