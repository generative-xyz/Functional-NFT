import * as dotenv from 'dotenv';
import {AVATARS} from "./avatats";


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
            "0xFD8500cf6B98F37Bc1a287195d2537b72945a1e8",
            "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
            "0x40193c8518BB267228Fc409a613bDbD8eC5a97b3");
        console.log("%s AVATARS address: %s", process.env.NETWORK, address);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();