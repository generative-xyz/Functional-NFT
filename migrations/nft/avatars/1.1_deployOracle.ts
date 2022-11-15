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
            "0x514910771af9ca656af840dff83e8264ecf986ca",
            "0x262aBFeD55b03A41451e16E4591837E7A7af04d3");
        console.log("%s AVATARS address: %s", process.env.NETWORK, address);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();