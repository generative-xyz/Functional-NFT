import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0x0bf438e43dc76fac0758764745c3153361ea484b';
        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const projectId = 2;
        let a: any = {};
        // a.getTokenURI = await nft.getTokenURI(contract, projectId);
        a.project = await nft.getProject(contract, projectId);
        console.log(a);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();