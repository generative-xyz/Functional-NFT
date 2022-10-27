import * as dotenv from 'dotenv';

import {BigNumber, ethers} from "ethers";
import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";
import * as fs from "fs";
import {keccak256} from "ethers/lib/utils";
import Web3 from "web3";
import {createAlchemyWeb3} from "@alch/alchemy-web3";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }
        const contract = '0xb1F4fb76648D77D4c3F69253e1fAE812178747b2';
        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);

        const uri = {
            name: "Test Algo NFT",
            description: "Test Algo NFT",
            image: "https://live.staticflickr.com/6076/6055860219_b5be1b6b19_z.jpg"
        }
        const encodedString = "data:application/json;base64," + btoa(JSON.stringify(uri)) // Base64 encode the String
        const fromProjectId = 14;
        let uris = [];
        let paramValues = [];
        const seeds: any[] = [
            '0x6a7e30f668ecfc39d20462f7e02a0f9aa52caeed064474ca6763fbf28ee41e03',
        ];

        for (let i = 0; i < 1; i++) {
            uris.push(encodedString);
            let params = [
                {
                    _typeValue: 3,
                    _max: 209,
                    _min: 0,
                    _decimal: 0,
                    _availableValues: [],
                    _value: 0,
                    _editable: false
                },
                {
                    _typeValue: 1,
                    _max: 5,
                    _min: 1,
                    _decimal: 0,
                    _availableValues: [
                        "1",
                        "2",
                        "3",
                        "4",
                        "5",
                        "6",
                        "7"
                    ],
                    _value: 0,
                    _editable: true
                },
                {
                    _typeValue: 1,
                    _max: 5,
                    _min: 1,
                    _decimal: 0,
                    _availableValues: [
                        "1",
                        "2",
                        "3"
                    ],
                    _value: 0,
                    _editable: false
                },
                {
                    _typeValue: 2,
                    _max: 5,
                    _min: 1,
                    _decimal: 0,
                    _availableValues: [
                        "0",
                        "0.5",
                        "1"
                    ],
                    _value: 0,
                    _editable: false
                }];
            const hardhatConfig = require("../../../hardhat.config");
            const web3 = createAlchemyWeb3(hardhatConfig.networks[hardhatConfig.defaultNetwork].url);
            let tempSeed = seeds[i];
            for (let j = 0; j < params.length; j++) {
                for (let k = 0; k < params[j]._availableValues.length; k++) {
                    params[j]._availableValues[k] = "";
                }
                if (!params[j]._editable) {
                    // random from seed
                    const seedInBN = web3.utils.toBN(tempSeed);
                    console.log("seed", seedInBN.toString());
                    if (params[j]._availableValues.length == 0) {
                        // [min, max]
                        const a = web3.utils.toBN(params[j]._max - params[j]._min + 1);
                        const mod = seedInBN.mod(a);
                        let val = (web3.utils.toBN(params[j]._min)).add(mod);
                        params[j]._value = val.toNumber();
                    } else {
                        // index of array
                        console.log(web3.utils.toBN(params[j]._availableValues.length).toString());
                        const val = seedInBN.mod(web3.utils.toBN(params[j]._availableValues.length));
                        console.log(val.toString());
                        params[j]._value = val.toNumber();
                    }
                }
                // console.log(tempSeed, params[j]._value);
                const t = web3.utils.encodePacked(tempSeed, params[j]._value);
                // console.log(t);
                if (t != null) {
                    tempSeed = web3.utils.keccak256(t);
                }
            }

            paramValues.push({
                _seed: seeds[i],
                _params: params,
            });
            console.log({params});
        }
        const tx = await nft.mintBatchUniqueNFT(
                contract,
                JSON.parse(JSON.stringify({
                    _fromProjectId: fromProjectId,
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