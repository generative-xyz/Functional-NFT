import * as dotenv from 'dotenv';

import {BigNumber, ethers} from "ethers";
import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";
import * as fs from "fs";
import {keccak256} from "ethers/lib/utils";
import Web3 from "web3";
import {createAlchemyWeb3} from "@alch/alchemy-web3";
import {json} from "hardhat/internal/core/params/argumentTypes";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }
        const hardhatConfig = require("../../../hardhat.config");
        const web3 = createAlchemyWeb3(hardhatConfig.networks[hardhatConfig.defaultNetwork].url);

        const contract = '0x0bf438e43dc76fac0758764745c3153361ea484b';
        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);

        const fromProjectId = 2;
        let paramValues = [];
        const seed = web3.utils.leftPad(web3.utils.asciiToHex(""), 64) // no seed
        paramValues = JSON.parse(JSON.stringify({
            _seed: seed,
            _value: [0, Math.floor(Math.random() * 7), 0, 0],
        }));
        const tx = await nft.mintNFT(
                contract,
                fromProjectId,
                paramValues, 0
            )
        ;
        console.log("tx:", tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();