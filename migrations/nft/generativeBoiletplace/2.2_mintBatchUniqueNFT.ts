import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";
import * as fs from "fs";
import {keccak256} from "ethers/lib/utils";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }
        const contract = '0xE7e2736b8450e2D7937780232570dedceeF2229a';
        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);

        const uri = {
            name: "Test Algo NFT 2",
            description: "Test Algo NFT 2",
            image: "https://live.staticflickr.com/6076/6055860219_b5be1b6b19_z.jpg"
        }
        const encodedString = "data:application/json;base64," + btoa(JSON.stringify(uri)) // Base64 encode the String
        let uris = [];
        let paramValues = [];
        for (let i = 1; i <= 1; i++) {
            uris.push(encodedString);
            paramValues.push({
                _seedIndex: i,
                _seed: keccak256([]),
                _params: [],
            });
        }
        const tx = await nft.mintBatchUniqueNFT(
                contract,
                JSON.parse(JSON.stringify({
                    _fromProjectId: 1,
                    _mintTo: process.env.PUBLIC_KEY,
                    _uriBatch: uris,
                    _paramsBatch: paramValues,
                })),
                0
            )
        ;
        console.log("tx:", tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();