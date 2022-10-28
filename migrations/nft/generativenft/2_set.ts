import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GeneretiveNFT} from "./GeneretiveNFT";
import {candyTraits} from "./projectTraits";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0x2C81F8C1210418813f8ae6d770Ba90C138a351c7';
        const nft = new GeneretiveNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
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