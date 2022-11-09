import {AVATARS} from "./avatars";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }

        const nft = new AVATARS(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const address = await nft.upgradeContract("0xFc522A802eBC021449b268f5cF0B52C73276d0CB");
        console.log({address});
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();