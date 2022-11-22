import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import * as fs from "fs";
import {keccak256} from "ethers/lib/utils";
import {CONFETTI} from "./confetti";

(async () => {
    try {
        if (process.env.NETWORK != "mainnet") {
            console.log("wrong network");
            return;
        }
        const contract = '0x29324bb75158f0C0089E465257b81805280744e5';
        const nft = new CONFETTI(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
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