import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GeneretiveNFT} from "./GeneretiveNFT";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0xA2c2Bd206cf554DA3F8e8992B8128A6F90cfa1f3';
        const nft = new GeneretiveNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tokenId = 1;
        let a: any = {};
        // a.getTokenURI = await nft.getTokenURI(contract, tokenId);
        // a.get_boilerplateAdd = await nft.get_boilerplateAddr(contract);
        // a.get_boilerplateId = await nft.get_boilerplateId(contract);
        // a.get_paramsValues = await nft.get_paramsValues(contract, tokenId);
        // a.getTraits = await nft.getTraits(contract);
        a.getTokenTraits = await nft.getTokenTraits(contract, tokenId);
        console.log(a);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();