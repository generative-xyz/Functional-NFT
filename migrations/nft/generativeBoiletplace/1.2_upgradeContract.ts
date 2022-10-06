import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }

        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const address = await nft.upgradeContract("0x19CbE1721a63Dd4F391Fc6F0A75596fe98C2301a");
        console.log({address});
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();