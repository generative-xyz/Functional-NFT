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

        const projectName = "Candy Algo 1";
        const uri = "data:application/json;base64," + btoa(JSON.stringify({
            name: projectName,
            description: "",
            image: "ipfs://QmRanwBkgwgmbfHfwAmkEhbZyQui8FdkYpBrJ9BWcwt7Pf"
        })) // Base64 encode the String
        const fee = "0.0";
        const feeTokenAddr = '0x0000000000000000000000000000000000000000';
        const maxMint = 0;
        let scriptContent = fs.readFileSync("/Users/autonomous/Documents/generative-objs/Functional-NFT/test_script/candy.py")
        // 1: python, 2: js, 3: ts;
        const scriptType = 1;
        const clientSeed = true;
        const tx = await nft.mintProject(
                contract, process.env.PUBLIC_KEY,
                projectName,
                maxMint,
                scriptContent.toString(),
                scriptType,
                clientSeed,
                uri,
                ethers.utils.parseEther(fee),
                feeTokenAddr,
                JSON.parse(JSON.stringify({
                    _seed: '0x0000000000000000000000000000000000000000',
                    _params: candyParamTemplates,
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