import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFTCandy} from "./GenerativeBoilerplateNFT";
import * as fs from "fs";
import {candyProject2} from "./projectTemplates";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const contract = '0x924dF058388cCA4a1eb55A21ae3c5C564E629821';
        const nft = new GenerativeBoilerplateNFTCandy(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);
        const projectId = 1;
        // const tx = await nft.setCustomURI(contract, projectId, 'data:application/json;base64,eyJuYW1lIjoiVGVzdCBBbGdvIiwiZGVzY3JpcHRpb24iOiJUZXN0IEFsZ28iLCJpbWFnZSI6Imh0dHBzOi8vbGl2ZS5zdGF0aWNmbGlja3IuY29tLzYwNzYvNjA1NTg2MDIxOV9iNWJlMWI2YjE5X3ouanBnIn0=', 0);

        let scriptContent = fs.readFileSync(candyProject2.script)
        const tx = await nft.storeScript(contract, projectId, scriptContent.toString(), 0);
        console.log(tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();