import * as dotenv from 'dotenv';
import {AVATARS} from "./avatars";


(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const nft = new AVATARS(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const address = await nft.deployUpgradeable(
            "AVATARS",
            "AVATARS",
            process.env.PUBLIC_KEY,
            "0x46C02B9113DcA70a8C2e878Df0B24Dc895836b75",
            "0xd0479b5a804C654C39B766d8FaD2CeD907F5c83a",
            "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
            "0x40193c8518BB267228Fc409a613bDbD8eC5a97b3");
        console.log("%s AVATARS address: %s", process.env.NETWORK, address);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();