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
        const contract = '0xb1F4fb76648D77D4c3F69253e1fAE812178747b2';
        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);

        const uri = {
            name: "Test Algo",
            description: "Test Algo",
            image: "https://live.staticflickr.com/6076/6055860219_b5be1b6b19_z.jpg"
        }
        const encodedString = "data:application/json;base64," + btoa(JSON.stringify(uri)) // Base64 encode the String

        let scriptContent = fs.readFileSync("/Users/autonomous/Documents/rendering-machine/demo/rendering_scripts/blender/voronoi_sphere.py")
        // 1: python, 2: js, 3: ts;
        const scriptType = 1;
        const tx = await nft.mintProject(
                contract, process.env.PUBLIC_KEY,
                "Test Algo",
                100,
                scriptContent.toString(),
                1,
                false,
                encodedString,
                ethers.utils.parseEther("0.0"),
                "0x0000000000000000000000000000000000000000",
                JSON.parse(JSON.stringify({
                    _seedIndex: 0,
                    _seed: keccak256([0]),
                    _params: [{
                        _typeValue: 0,
                        _max: 5,
                        _min: 1,
                        _decimal: 0,
                        _availableValues: [],
                        _value: 0,
                        _editable: 0
                    }, {
                        _typeValue: 1,
                        _max: 65535,
                        _min: 100,
                        _decimal: 0,
                        _availableValues: [],
                        _value: 0,
                        _editable: 0
                    }],
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