import * as dotenv from 'dotenv';

import {BigNumber, ethers} from "ethers";
import {GenerativeBoilerplateNFTCandy} from "./GenerativeBoilerplateNFT";
import * as fs from "fs";
import {keccak256} from "ethers/lib/utils";
import Web3 from "web3";
import {createAlchemyWeb3} from "@alch/alchemy-web3";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const hardhatConfig = require("../../../hardhat.config");
        const web3 = createAlchemyWeb3(hardhatConfig.networks[hardhatConfig.defaultNetwork].url);

        const contract = '0x460Eb61D1Dc4FAc8B6cAF60f28a7624Cc2c1167B';
        const nft = new GenerativeBoilerplateNFTCandy(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);

        const encodedString = "";
        const fromProjectId = 1;
        let uris = [];
        let paramValues = [];
        const seeds: any[] = [
            web3.utils.leftPad(web3.utils.asciiToHex(""), 64), // no seed
        ];

        for (let i = 0; i < 1; i++) {
            uris.push(encodedString);

            paramValues.push({
                _seed: seeds[i],
                _value: [0, Math.floor(Math.random() * 7), 0, 0],
            });
        }
        const mintBatch = JSON.parse(JSON.stringify({
            _fromProjectId: fromProjectId,
            _mintTo: process.env.PUBLIC_KEY,
            _uriBatch: uris,
            _paramsBatch: paramValues,
        }));
        const tx = await nft.mintBatchUniqueNFT(
                contract,
                mintBatch,
                0
            )
        ;
        console.log("tx:", tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();