import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import * as fs from "fs";
import {keccak256} from "ethers/lib/utils";
import {AvatarsOracle} from "./avatarsOracle";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0xDCbBca88D27B6A8379e76d99aa8AcB8031cB6760';
        const nft = new AvatarsOracle(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);

        const data = await nft.requestIdGamesData(contract, "0xf8aae13f31568ab7623f1a029d1a7fee9cc6c12f8ec20f3d1e60774b3dbb22cb");
        console.log(data);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();