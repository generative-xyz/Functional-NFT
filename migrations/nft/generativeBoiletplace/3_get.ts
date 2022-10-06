import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }
        const contract = '0x19cbe1721a63dd4f391fc6f0a75596fe98c2301a';
        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tokenId = 1;
        let a: any = {};
        a.getTokenURI = await nft.getTokenURI(contract, tokenId);
        a.getScript = await nft.getScript(contract, tokenId);
        a.getScriptType = await nft.getScriptType(contract, tokenId);
        a.getFee = await nft.getFee(contract, tokenId);
        a.getFeeTokens = await nft.getFeeTokens(contract, tokenId);
        a.getNFTContract = await nft.getNFTContract(contract, tokenId);
        a.get_mintTotalSupply = await nft.get_mintTotalSupply(contract, tokenId);
        console.log({a});
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();