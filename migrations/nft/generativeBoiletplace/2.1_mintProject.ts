import * as dotenv from 'dotenv';

import {ethers} from "ethers";
import {GenerativeBoilerplateNFT} from "./GenerativeBoilerplateNFT";
import * as fs from "fs";
import {keccak256} from "ethers/lib/utils";
import {candyProject, candyProject2} from "./projectTemplates";

(async () => {
    try {
        if (process.env.NETWORK != "goerli") {
            console.log("wrong network");
            return;
        }

        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);


        const contract = '0xb1F4fb76648D77D4c3F69253e1fAE812178747b2';
        const projectTemplate = candyProject2;
        const uri = "data:application/json;base64," + btoa(JSON.stringify({
            name: projectTemplate.name,
            description: projectTemplate.description,
            image: projectTemplate.image,
            animation_url: projectTemplate.animation_url,
        })) // Base64 encode the String
        let scriptContent = fs.readFileSync(projectTemplate.script)
        const tx = await nft.mintProject(
                contract, process.env.PUBLIC_KEY,
                projectTemplate.name,
                projectTemplate.maxMint,
                projectTemplate.notOwnerLimit,
                scriptContent.toString(),
                projectTemplate.scriptType,
                projectTemplate.clientSeed,
                uri,
                ethers.utils.parseEther(projectTemplate.fee),
                projectTemplate.feeTokenAddr,
                JSON.parse(JSON.stringify({
                    _seed: keccak256('0x00000000000000000000000000000000'),
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