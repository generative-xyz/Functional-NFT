import * as dotenv from 'dotenv';
import {AVATARS} from "./avatars";
import {AvatarsOracle} from "./avatarsOracle";


(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const nft = new AvatarsOracle(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const address = await nft.deploy(
            process.env.PUBLIC_KEY,
            "0xe7b336ca34b2ed9e52460ab7ec5e0b8562d61510",
            "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
            "0xbE7eBA96CFdaB4C721637056cb116837FB1f766A");
        console.log("%s AVATARS address: %s", process.env.NETWORK, address);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();