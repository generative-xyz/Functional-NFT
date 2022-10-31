import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFTCandy} from "./GenerativeBoilerplateNFT";
import * as fs from "fs";
import {candyProject2} from "./projectTemplates";
import {createAlchemyWeb3} from "@alch/alchemy-web3";

(async () => {
    try {
        if (process.env.NETWORK != "mumbai") {
            console.log("wrong network");
            return;
        }

        const nft = new GenerativeBoilerplateNFTCandy(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);


        const contract = '0x62825f15315807bACcdD1a9c8416e27d3cC7Aa1a';
        const projectTemplate = candyProject2;
        const uri = "data:application/json;base64," + btoa(JSON.stringify({
            name: projectTemplate.name,
            description: projectTemplate.description,
            image: projectTemplate.image,
            animation_url: projectTemplate.animation_url,
        })) // Base64 encode the String
        const hardhatConfig = require("../../../hardhat.config");
        const web3 = createAlchemyWeb3(hardhatConfig.networks[hardhatConfig.defaultNetwork].url);
        const seed = web3.utils.leftPad(web3.utils.asciiToHex(""), 64);
        const tx = await nft.mintProject(
                contract, process.env.PUBLIC_KEY,
                projectTemplate.maxMint,
                projectTemplate.notOwnerLimit,
                ethers.utils.parseEther(projectTemplate.fee),
                projectTemplate.feeTokenAddr,
                JSON.parse(JSON.stringify({
                    _seed: seed,
                    _params: projectTemplate.params,
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