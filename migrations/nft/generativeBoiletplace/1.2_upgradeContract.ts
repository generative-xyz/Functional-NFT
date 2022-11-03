import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }

        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const address = await nft.upgradeContract("0x0bf438e43dc76fac0758764745c3153361ea484b");
        console.log({address});
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();