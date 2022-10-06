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
        const projectId = 1;
        let a: any = {};
        a.getTokenURI = await nft.getTokenURI(contract, projectId);
        // a.getScript = await nft.getScript(contract, projectId);
        // a.getScriptType = await nft.getScriptType(contract, projectId);
        // a.getFee = await nft.getFee(contract, projectId);
        // a.getFeeTokens = await nft.getFeeTokens(contract, projectId);
        // a.getNFTContract = await nft.getNFTContract(contract, projectId);
        // a.get_mintTotalSupply = await nft.get_mintTotalSupply(contract, projectId);
        // a.get_mintMaxSupply = await nft.get_mintMaxSupply(contract, projectId);
        // a.get_nftContracts = await nft.get_nftContracts(contract, process.env.PUBLIC_KEY, projectId);
        console.log({a});
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();