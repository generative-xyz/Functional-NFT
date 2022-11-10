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
        // const args = process.argv.slice(2)
        // const a = await nft.getParamValues(contract, args[0]);
        for (var i = 1; i < 100; i++) {
            const a = await nft.getParamValues(contract, i);
            if (a._nation == "USA") {
                console.log(a);
                return;
            }
        }
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();