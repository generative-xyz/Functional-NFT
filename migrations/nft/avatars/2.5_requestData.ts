import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import * as fs from "fs";
import {keccak256} from "ethers/lib/utils";
import {AVATARS} from "./avatars";
import {AvatarsOracle} from "./avatarsOracle";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0xDCbBca88D27B6A8379e76d99aa8AcB8031cB6760';
        const nft = new AvatarsOracle(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        // const data = await nft.requestIdGamesData(contract, "0x0fcc52054138e1cf21ade0a081a5926c25a92538ca7c3a5e93d820bfdca726fd");
        // console.log(data);
        // return
        const tx = await nft.requestData(contract, 0);
        console.log("tx:", tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();