import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }
        const contract = '0x58603fce93009536D4267bAd9A55f5fdB54aCD24';
        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const projectId = 1;
        let a: any = {};
        // a.getTokenURI = await nft.getTokenURI(contract, projectId);
        a.project = await nft.getProject(contract, projectId);
        a.get_minterNFTInfos = await nft.get_minterNFTInfos(contract, process.env.PUBLIC_KEY, projectId);
        console.log(a.project._mintTotalSupply);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();