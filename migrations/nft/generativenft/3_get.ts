import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GeneretiveNFT} from "./GeneretiveNFT";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }
        const contract = '0x32bdc06d8a5de3ade19359c1e768f2b1839aab27';
        const nft = new GeneretiveNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tokenId = 1;
        // const val: any = await nft.get_boilerplateAdd(contract);
        // const val: any = await nft.getTokenURI(contract, tokenId);
        const get_boilerplateAdd: any = await nft.get_boilerplateAdd(contract);
        const get_boilerplateId: any = await nft.get_boilerplateId(contract);
        console.log({get_boilerplateAdd}, {get_boilerplateId});
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();