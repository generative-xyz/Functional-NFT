import {AVATARS} from "./avatars";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0x0248cCc4Efcd59763D8d760e8eA7903c15EFFbB5';
        const nft = new AVATARS(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tx = await nft.changeBaseURI(contract, 'https://rove-rendering-dev.moshwithme.io/v1/rendered-nft/80001/0x0248cCc4Efcd59763D8d760e8eA7903c15EFFbB5/metadata/', 0);
        console.log("tx:", tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();