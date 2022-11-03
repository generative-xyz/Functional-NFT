import * as dotenv from 'dotenv';

import {GenerativeNFT} from "./GenerativeNFT";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const nft = new GenerativeNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const address = await nft.deploy(process.env.PUBLIC_KEY);
        console.log("%s Param control deployed address: %s", process.env.NETWORK, address);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();