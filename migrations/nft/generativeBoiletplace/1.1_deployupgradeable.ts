import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";

const {ethers} = require("hardhat");
const {getContractAddress} = require('@ethersproject/address');

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }

        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const [owner] = await ethers.getSigners()
        const transactionCount = await owner.getTransactionCount()

        const futureAddress = getContractAddress({
            from: owner.address,
            nonce: transactionCount
        })
        console.log({futureAddress});
        const chainID = "5";
        const baseUrl = "";
        const address = await nft.deployUpgradeable(
            "Generative Design",
            "GenDe",
            baseUrl,
            process.env.PUBLIC_KEY,
            "0x46C02B9113DcA70a8C2e878Df0B24Dc895836b75");
        console.log("GeneretiveBoilerplateNFT deployed address: ", address);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();