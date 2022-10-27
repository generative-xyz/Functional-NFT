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
        const contract = '0xA2c2Bd206cf554DA3F8e8992B8128A6F90cfa1f3';
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