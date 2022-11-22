import {HORNS} from "./horns";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0x29324bb75158f0C0089E465257b81805280744e5';
        const nft = new HORNS(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const tx = await nft.changeBaseURI(contract, 'https://rove-rendering-dev.moshwithme.io/v1/rendered-nft/80001/0x29324bb75158f0C0089E465257b81805280744e5/metadata/', 0);
        console.log("tx:", tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();