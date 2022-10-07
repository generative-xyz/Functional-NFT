import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";

const {ethers} = require("hardhat");
const {getContractAddress} = require('@ethersproject/address');

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
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
            "Boiler NFT",
            "Boiler NFT",
            baseUrl,
            process.env.PUBLIC_KEY,
            "0x9a63ff46dfa34296a2cbd5a0f0a3ab28d27ebc07");
        console.log("GeneretiveBoilerplateNFT deployed address: ", address);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();