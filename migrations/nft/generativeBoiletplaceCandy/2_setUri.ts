import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFTCandy} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0x924df058388cca4a1eb55a21ae3c5c564e629821';
        const nft = new GenerativeBoilerplateNFTCandy(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tokenId = 4502;
        const tx = await nft.setCustomURI(contract, tokenId, "https://rove-rendering-dev.moshwithme.io/v1/rendered-nft/80001/0x924df058388cca4a1eb55a21ae3c5c564e629821/1/" + tokenId, 0);
        console.log(tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();