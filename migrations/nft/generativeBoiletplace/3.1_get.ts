import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }
        const contract = '0xae0C96BBD7733a1C7843af27e0683c74E182A3a7';
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