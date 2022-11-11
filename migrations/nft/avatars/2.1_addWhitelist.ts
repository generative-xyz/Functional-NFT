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
        const contract = '0x0248cCc4Efcd59763D8d760e8eA7903c15EFFbB5';
        const nft = new AVATARS(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);

        const tx = await nft.addWhitelist(contract, ["0xF61234046A18b07Bf1486823369B22eFd2C4507F"], 1, 0);
        console.log("tx:", tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();