import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import * as fs from "fs";
import {keccak256} from "ethers/lib/utils";
import {CONFETTI} from "./confetti";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0x1F0A3f7209967D18f12e1CA396D75A7caa8a68b1';
        const nft = new CONFETTI(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tokenGatedIds: any = [];
        for (let i = 0; i < tokenGatedIds.length; i++) {
            const tx = await nft.mintByToken(contract, tokenGatedIds[i], 0);
            console.log("Mint - tokenID:", tokenGatedIds[i], "- tx:", tx?.transactionHash);
        }
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();