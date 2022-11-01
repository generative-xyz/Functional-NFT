import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFTCandy} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0xA1988821bb9C1B83cb6B16F2E4D4Ee7F77D99aC0';
        const nft = new GenerativeBoilerplateNFTCandy(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const projectId = 1;
        let a: any = {};
        // a.getTokenURI = await nft.getTokenURI(contract, projectId);
        a.project = await nft.getProject(contract, projectId);
        // a.getBaseUri = await nft.getBaseUri(contract);
        // a.getTraits = await nft.getTraits(contract);
        console.log(a.project);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();