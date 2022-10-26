import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GeneretiveNFT} from "./GeneretiveNFT";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }
        const contract = '0xc8CB5439c767A63aca1c01862252B2F3495fDcFE';
        const nft = new GeneretiveNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tokenId = 1;
        let a: any = {};
        // a.getTokenURI = await nft.getTokenURI(contract, tokenId);
        // a.get_boilerplateAdd = await nft.get_boilerplateAddr(contract);
        // a.get_boilerplateId = await nft.get_boilerplateId(contract);
        // a.get_paramsValues = await nft.get_paramsValues(contract, tokenId);
        // a.getTraits = await nft.getTraits(contract);
        a.getTokenTraits = await nft.getTokenTraits(contract, tokenId);
        console.log(a.getTokenTraits);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();