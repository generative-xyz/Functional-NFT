import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFTCandy} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0xac61b8dcf7e6fe176d02f3c4f5e951b234c349b0';
        const nft = new GenerativeBoilerplateNFTCandy(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const projectId = 1;
        let a: any = {};
        // a.getTokenURI = await nft.getTokenURI(contract, projectId);
        // a.project = await nft.getProject(contract, projectId);
        // a.getBaseUri = await nft.getBaseUri(contract);
        a.getTraits = await nft.getTraits(contract);
        console.log(a.getTraits);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();