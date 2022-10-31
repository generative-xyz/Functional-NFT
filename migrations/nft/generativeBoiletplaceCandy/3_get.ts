import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFTCandy} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0x62825f15315807baccdd1a9c8416e27d3cc7aa1a';
        const nft = new GenerativeBoilerplateNFTCandy(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tokenId = 2;
        let a: any = {};
        // a.getTokenURI = await nft.getTokenURI(contract, tokenId);
        // a.get_boilerplateAdd = await nft.get_boilerplateAddr(contract);
        // a.get_boilerplateId = await nft.get_boilerplateId(contract);
        a.get_paramsValues = await nft.get_paramsValues(contract, tokenId);
        // a.getTraits = await nft.getTraits(contract);
        // a.getTokenTraits = await nft.getTokenTraits(contract, tokenId);
        console.log(a.get_paramsValues);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();