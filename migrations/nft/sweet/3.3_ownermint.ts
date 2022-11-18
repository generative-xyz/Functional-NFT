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
            console.log("Minting - ", tokenIds[i], " - tx:", tx?.transactionHash);
        }
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();
/*
[
    4533, 4536, 4544, 4549, 4566, 4575, 4599, 4602,
    4613, 4614, 4616, 4630, 4632, 4639, 4641, 4646,
    4651, 4655, 4659, 4662, 4663, 4664, 4666, 4672,
    4688, 4691, 4692, 4698, 4709, 4710, 4717, 4721,
    4728, 4732, 4733, 4748, 4759, 4760, 4767, 4769,
    4770, 4776, 4778, 4808, 4811, 4812, 4820, 4821,
    4824, 4827, 4838, 4854, 4865, 4871, 4873, 4880,
    4887, 4892, 4899, 4915, 4923, 4927, 4929, 4933,
    4939, 4941, 4951, 4970, 4982, 4991, 4996, 4999
] 72
*/
