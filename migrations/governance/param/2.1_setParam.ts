import * as dotenv from 'dotenv';

import {ParamControl} from "./paramControl";
import {ethers} from "ethers";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }
        const contract = '0x9a63ff46dfa34296a2cbd5a0f0a3ab28d27ebc07';
        const key = 'GENERATIVE_NFT_TEMPLATE';
        const nft = new ParamControl(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);

        const val: any = await nft.getAddress(contract, key);
        console.log("val", val);

        let tx = await nft.setAddress(contract, key, '0xdb9DB23F58fb06ED41fa59997bAA9c50654A95BD', 0);
        console.log("%s ParamControl admin address: %s", process.env.NETWORK, tx);


    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();