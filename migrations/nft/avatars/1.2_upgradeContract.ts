import {AVATARS} from "./avatars";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }

        const nft = new AVATARS(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const address = await nft.upgradeContract("0x54a8d190d360a6AD5F806034284A1b9FcF2950b6");
        console.log({address});
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();