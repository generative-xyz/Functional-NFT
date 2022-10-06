import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }
        const contract = '0x19cbe1721a63dd4f391fc6f0a75596fe98c2301a';
        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tokenId = 1;
        // const val: any = await nft.getTokenURI(contract, tokenId);
        // const val: any = await nft.getScript(contract, tokenId);
        // const val: any = await nft.getScriptType(contract, tokenId);
        // const val: any = await nft.getFee(contract, tokenId);
        // const val: any = await nft.getFeeTokens(contract, tokenId);
        // const val: any = await nft.getNFTContract(contract, tokenId);
        const val: any = await nft.get_mintTotalSupply(contract, tokenId);
        console.log({val});
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();