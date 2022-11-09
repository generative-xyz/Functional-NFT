import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import * as fs from "fs";
import {keccak256} from "ethers/lib/utils";
import {AVATARS} from "./avatars";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0xFc522A802eBC021449b268f5cF0B52C73276d0CB';
        const nft = new AVATARS(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);

        const tx = await nft.setBE(contract, "0xe7B336ca34B2eD9e52460AB7eC5e0b8562D61510", 0);
        console.log("tx:", tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();