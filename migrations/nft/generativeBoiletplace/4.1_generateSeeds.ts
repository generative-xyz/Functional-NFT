import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";
import * as fs from "fs";
import {keccak256} from "ethers/lib/utils";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }
        const contract = '0x95056d48b6DC390304e6d5c4638A413E7Bd931ce';
        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);

        const tx = await nft.generateSeeds(
                contract,
                1,
                20,
                0
            )
        ;
        console.log("tx:", tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();