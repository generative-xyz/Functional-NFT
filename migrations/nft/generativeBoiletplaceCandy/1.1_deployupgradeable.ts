import {GenerativeBoilerplateNFTCandy} from "./GenerativeBoilerplateNFT";

const {ethers} = require("hardhat");
const {getContractAddress} = require('@ethersproject/address');

(async () => {
    try {
        if (process.env.NETWORK != "mainnet") {
            console.log("wrong network");
            return;
        }

        const nft = new GenerativeBoilerplateNFTCandy(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const [owner] = await ethers.getSigners()
        const transactionCount = await owner.getTransactionCount()

        const futureAddress = getContractAddress({
            from: owner.address,
            nonce: transactionCount
        })
        console.log({futureAddress});
        const chainID = "5";
        const baseUrl = "https://rendering.rove.to/v1/rendered-nft/1/";
        const address = await nft.deployUpgradeable(
            "SWEETS: On-chain Candies",
            "SWEETS",
            baseUrl,
            process.env.PUBLIC_KEY,
            "0xEc9e6E328Acf73cd2b1775070275A75Efc078383");
        console.log("GeneretiveBoilerplateNFTCandy deployed address: ", address);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();