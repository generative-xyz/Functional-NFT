import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFTCandy} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0x62825f15315807baccdd1a9c8416e27d3cc7aa1a';
        const nft = new GenerativeBoilerplateNFTCandy(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tx = await nft.setCustomURI(contract, 2, "https://rove-rendering-dev.moshwithme.io/v1/rendered-nft/80001/0x62825f15315807bACcdD1a9c8416e27d3cC7Aa1a/1/2", 0);
        console.log(tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();