import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }
        const contract = '0x19cbe1721a63dd4f391fc6f0a75596fe98c2301a';
        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const projectId = 1;
        const tx = await nft.setCustomURI(contract, projectId, 'data:application/json;base64,eyJuYW1lIjoiVGVzdCBBbGdvIiwiZGVzY3JpcHRpb24iOiJUZXN0IEFsZ28iLCJpbWFnZSI6Imh0dHBzOi8vbGl2ZS5zdGF0aWNmbGlja3IuY29tLzYwNzYvNjA1NTg2MDIxOV9iNWJlMWI2YjE5X3ouanBnIn0=', 0);
        console.log(tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();