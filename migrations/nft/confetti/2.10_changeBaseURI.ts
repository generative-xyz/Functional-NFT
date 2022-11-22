import {CONFETTI} from "./confetti";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0x1F0A3f7209967D18f12e1CA396D75A7caa8a68b1';
        const nft = new CONFETTI(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tx = await nft.changeBaseURI(contract, 'https://rove-rendering-dev.moshwithme.io/v1/rendered-nft/80001/0x1F0A3f7209967D18f12e1CA396D75A7caa8a68b1/metadata/', 0);
        console.log("tx:", tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();