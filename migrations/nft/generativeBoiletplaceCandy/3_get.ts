import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFTCandy} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0x77e6E4dd3cE2d2Ae15F12B1F19bcf1Fe65dF2DB6';
        const nft = new GenerativeBoilerplateNFTCandy(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tokenId = 1;
        let a: any = {};
        a.getTokenURI = await nft.getTokenURI(contract, tokenId);
        a.get_paramsValues = await nft.get_paramsValues(contract, tokenId);
        a.getTokenTraits = await nft.getTokenTraits(contract, tokenId);
        console.log(a.get_paramsValues);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();