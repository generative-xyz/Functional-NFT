import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import * as fs from "fs";
import {keccak256} from "ethers/lib/utils";
import {SWEETS} from "./sweets";

(async () => {
    try {
        if (process.env.NETWORK != "mainnet") {
            console.log("wrong network");
            return;
        }
        const contract = '0x57425e74a8d9b09a4e1a713d727b05084fddef12';
        const nft = new SWEETS(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        let count = 0;
        let tokenIds = [];
        for (let i = 4526; i <= 5000; i++) {
            const a = await nft.getParamValues(contract, i);
            if (a.shape == "Pillhead") {
                console.log(i, a);
                tokenIds.push(i);
                count++;
            }
        }
        console.log(tokenIds, count);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();