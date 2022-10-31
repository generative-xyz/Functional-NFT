import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFTCandy} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0x924dF058388cCA4a1eb55A21ae3c5C564E629821';
        const nft = new GenerativeBoilerplateNFTCandy(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tokenId = 3;
        let a: any = {};
        a.getTokenURI = await nft.getTokenURI(contract, tokenId);
        // a.get_paramsValues = await nft.get_paramsValues(contract, tokenId);
        // a.getTokenTraits = await nft.getTokenTraits(contract, tokenId);
        console.log(a.getTokenURI);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();