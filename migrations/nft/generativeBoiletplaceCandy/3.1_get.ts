import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFTCandy} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "mainnet") {
            console.log("wrong network");
            return;
        }
        const contract = '0x8Fd1EF5a56b0C51bBc1d08B3D99E68E517658B24';
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