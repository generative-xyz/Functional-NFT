import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import * as fs from "fs";
import {keccak256} from "ethers/lib/utils";
import {SWEETS} from "./sweets";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0x9e339b1b85b00feffa44b1a120702c5a40935391';
        const nft = new SWEETS(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tokenIds: any = [];
        for (let i = 0; i < tokenIds.length; i++) {
            const tx = await nft.ownerMint(contract, tokenIds[i], 0);
            console.log("tx:", tx);
        }
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();