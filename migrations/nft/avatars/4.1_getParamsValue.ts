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
        const contract = '0xdfa0d7551c9553d52296781fc2c0b74065af2390';
        const nft = new AVATARS(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);

        const a = await nft.getParamValues(contract, 4501);
        console.log(a);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();