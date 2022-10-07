import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }
        const contract = '0x54532D116f126690913da39dEa2DFD608a6f2D92';
        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const projectId = 1;
        let a: any = {};
        // a.getTokenURI = await nft.getTokenURI(contract, projectId);
        a.project = await nft.getProject(contract, projectId);
        // a.get_nftContracts = await nft.get_nftContracts(contract, process.env.PUBLIC_KEY, projectId);
        console.log({a});
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();