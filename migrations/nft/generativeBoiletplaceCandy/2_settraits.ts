import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFTCandy} from "./GenerativeBoilerplateNFT";
import {candyTraits} from "../generativenft/projectTraits";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0x62825f15315807bACcdD1a9c8416e27d3cC7Aa1a';
        const nft = new GenerativeBoilerplateNFTCandy(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const traits = candyTraits;
        const tx = await nft.updateTraits(contract, JSON.parse(JSON.stringify({
            _traits: traits,
        })), 0);
        console.log(tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();