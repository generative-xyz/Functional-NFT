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
            name: "Test Algo",
            description: "Test Algo",
            image: "https://live.staticflickr.com/6076/6055860219_b5be1b6b19_z.jpg"
        }
        const encodedString = "data:application/json;base64," + btoa(JSON.stringify(uri)) // Base64 encode the String

        let scriptContent = fs.readFileSync("/Users/autonomous/Documents/autonomous-vr/rendering-machine/rendering_scripts/blender/voronoi_sphere.py")
        // 1: python, 2: js, 3: ts;
        const scriptType = 1;
        const tx = await nft.mintProject(
                contract, process.env.PUBLIC_KEY,
                "Test Algo",
                10,
                scriptContent.toString(),
                1,
                false,
                encodedString,
                ethers.utils.parseEther("1.0"),
                "0xBA62BCfcAaFc6622853cca2BE6Ac7d845BC0f2Dc",
                JSON.parse(JSON.stringify({
                    _seedIndex: 0,
                    _seed: keccak256([]),
                    _params: [],
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