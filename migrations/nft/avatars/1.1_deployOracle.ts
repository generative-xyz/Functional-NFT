import * as dotenv from 'dotenv';
import {AVATARS} from "./avatars";
import {AvatarsOracle} from "./avatarsOracle";


(async () => {
    try {
        if (process.env.NETWORK != "mainnet") {
            console.log("wrong network");
            return;
        }
        const nft = new AvatarsOracle(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const address = await nft.deploy(
            process.env.PUBLIC_KEY,
            "0xe7B336ca34B2eD9e52460AB7eC5e0b8562D61510",
            "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
            "0xeE3BC809fFa9BB32A88d39d40DF6425d5d712B16");
        console.log("%s AVATARS address: %s", process.env.NETWORK, address);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();