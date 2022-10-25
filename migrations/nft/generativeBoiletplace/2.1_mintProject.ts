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

        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);


        const contract = '0xb1F4fb76648D77D4c3F69253e1fAE812178747b2';
        const candy = candyProject;
        const uri = "data:application/json;base64," + btoa(JSON.stringify({
            name: candy.name,
            description: candy.description,
            image: candy.image,
        })) // Base64 encode the String
        let scriptContent = fs.readFileSync(candyProject.script)
        const tx = await nft.mintProject(
                contract, process.env.PUBLIC_KEY,
                candy.name,
                candy.maxMint,
                scriptContent.toString(),
                candy.scriptType,
                candy.clientSeed,
                uri,
                ethers.utils.parseEther(candy.fee),
                candy.feeTokenAddr,
                JSON.parse(JSON.stringify({
                    _seed: '0x0000000000000000000000000000000000000000',
                    _params: candy.params,
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