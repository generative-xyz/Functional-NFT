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
        const contract = '0x58603fce93009536D4267bAd9A55f5fdB54aCD24';
        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);

        const uri = {
            name: "Test Algo NFT 2",
            description: "Test Algo NFT 2",
            image: "https://live.staticflickr.com/6076/6055860219_b5be1b6b19_z.jpg"
        }
        const encodedString = "data:application/json;base64," + btoa(JSON.stringify(uri)) // Base64 encode the String
        let uris = [];
        let paramValues = [];
        const seeds = [
            '0x5bd7a6ab661be303dd7a826e8f1dd61e5aa5c33cb7efea07f296a18276ba2348',
            '0x001901d635a0d9f53d177257e8bfacbe42b3d8cfb0ab0050d90df1938815a376',
            // '0xfc137f62771f2faffb1f1b7c983c04478827b7dfe5a4421500cfa09e093f982a',
            // '0xb869539e0a9d752c4e33cdf795a5f4c221d811b81af4924f6c51176a8e7f5700'
        ];

        for (let i = 0; i < 2; i++) {
            uris.push(encodedString);
            paramValues.push({
                _seed: seeds[i],
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