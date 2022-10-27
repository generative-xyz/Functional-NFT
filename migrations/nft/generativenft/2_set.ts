import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GeneretiveNFT} from "./GeneretiveNFT";
import {candyTraits} from "./projectTraits";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }
        const contract = '0xc8CB5439c767A63aca1c01862252B2F3495fDcFE';
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