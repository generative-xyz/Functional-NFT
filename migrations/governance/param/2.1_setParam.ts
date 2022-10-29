import * as dotenv from 'dotenv';

import {ParamControl} from "./paramControl";
import {ethers} from "ethers";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0x46C02B9113DcA70a8C2e878Df0B24Dc895836b75';
        const key = 'GENERATIVE_NFT_TEMPLATE';
        const nft = new ParamControl(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);

        const val: any = await nft.getAddress(contract, key);
        console.log("val", val);

        let tx = await nft.setAddress(contract, key, '0xe682973D26b28643fCFbDbB192e5807a0CE85826', 0);
        console.log("%s ParamControl admin address: %s", process.env.NETWORK, tx);


    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();