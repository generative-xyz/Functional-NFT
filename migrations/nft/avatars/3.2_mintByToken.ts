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
        const contract = '0x9e339b1b85b00feffa44b1a120702c5a40935391';
        const nft = new AVATARS(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tokenGatedIds: any = [];
        for (let i = 0; i < tokenGatedIds.length; i++) {
            await nft.setApproveSweet("0x432390f5DFF811f826A0E0Ab912cb93eb704a9c8", contract, tokenGatedIds[i], 0);
            const tx = await nft.mintByToken(contract, tokenGatedIds[i], 0);
            console.log("Mint - tokenID:", tokenGatedIds[i], "- tx:", tx?.transactionHash);
        }
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();