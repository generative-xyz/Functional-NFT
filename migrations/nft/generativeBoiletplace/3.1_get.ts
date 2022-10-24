import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }
        const contract = '0x95056d48b6DC390304e6d5c4638A413E7Bd931ce';
        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const projectId = 1;
        let a: any = {};
        // a.getTokenURI = await nft.getTokenURI(contract, projectId);
        a.project = await nft.getProject(contract, projectId);
        console.log(a);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();