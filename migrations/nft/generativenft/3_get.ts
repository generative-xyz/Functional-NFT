import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GeneretiveNFT} from "./GeneretiveNFT";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }
        const contract = '0xBb96facC454257B320e9a70Fd7905bb159FC9981';
        const nft = new GeneretiveNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tokenId = 1;
        let a: any = {};
        // a.getTokenURI = await nft.getTokenURI(contract, tokenId);
        // a.get_boilerplateAdd = await nft.get_boilerplateAddr(contract);
        // a.get_boilerplateId = await nft.get_boilerplateId(contract);
        a.get_paramsValues = await nft.get_paramsValues(contract, tokenId);
        console.log(a.get_paramsValues);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();