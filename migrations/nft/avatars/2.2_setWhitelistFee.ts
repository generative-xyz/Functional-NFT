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
        const contract = '0xdFa0D7551C9553D52296781fc2C0B74065af2390';
        const nft = new AVATARS(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);

        const tx = await nft.setWhitelistFee(contract, ethers.utils.parseEther("0.001"), 0);
        console.log("tx:", tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();