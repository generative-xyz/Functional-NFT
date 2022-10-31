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
        const contract = '0x924dF058388cCA4a1eb55A21ae3c5C564E629821';
        const nft = new GenerativeBoilerplateNFTCandy(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);

        const tx = await nft.mintUniqueNFT(
                contract,
                process.env.PUBLIC_KEY,
                [0, Math.floor(Math.random() * 7), 0, 0],
                5001, 0
            )
        ;
        console.log("tx:", tx);
    } catch (e) {
        // Deal with the fact the chain failed
        console.log(e);
    }
})();