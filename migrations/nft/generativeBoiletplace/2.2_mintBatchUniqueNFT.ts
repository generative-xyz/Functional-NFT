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
        const contract = '0x58603fce93009536D4267bAd9A55f5fdB54aCD24';
        const nft = new GenerativeBoilerplateNFT(process.env.NETWORK, process.env.PRIVATE_KEY, process.env.PUBLIC_KEY);

        const uri = {
            name: "Test Algo NFT 2",
            description: "Test Algo NFT 2",
            image: "https://live.staticflickr.com/6076/6055860219_b5be1b6b19_z.jpg"
        }
        const encodedString = "data:application/json;base64," + btoa(JSON.stringify(uri)) // Base64 encode the String
        const fromProjectId = 1;
        let uris = [];
        let paramValues = [];
        const seeds = [
            // '0x5bd7a6ab661be303dd7a826e8f1dd61e5aa5c33cb7efea07f296a18276ba2348',
            // '0x001901d635a0d9f53d177257e8bfacbe42b3d8cfb0ab0050d90df1938815a376',
            // '0x71d9a1a92c95654d839c25fda2561cb76b7abdb08acb30191229d7a3824c7cd0',
            // '0xfc137f62771f2faffb1f1b7c983c04478827b7dfe5a4421500cfa09e093f982a',
            // '0xb869539e0a9d752c4e33cdf795a5f4c221d811b81af4924f6c51176a8e7f5700',
            // '0xc9cb1ac7165272a17eec97f6a43ff49c0837fa7bd839410049c25eabbc15288f',
            // '0x9de8d57aede21ac888c03c7b550012435769d13b6cf0de07a3c548e99d6bad81',
            // '0xdef9ed9fba9c492fb4077922210bc8c1a6794b3e3d540c4d701a386f1a7e8e21',
            // '0x05264ffdf15648aabb99fabafc792f9fc17a409685669ae7d2cfb7eba9c46216',
            // '0xccb0f7656dae70f5346913af7d508f67f34d16b7373feb8bcfaaf5f81a95fe90',
            // '0x490bc53d295fff686207558e212afb0d8c3ea5d9ab9362229ee5ead1a193467e',
            // '0xf8e5db67b510d927f7f246a4296cd27eaf0d49a21c231fe7a549418bf76eee00',
            // '0x0b2434e60345fffd4b56be484921c653cdaeb89f20bbb58ea4708faf48d7cc39',
            // '0x781cabe3006c34a77135fe88a493c642df3f7738709dea7a6c037e0b2219f18c',
            // '0x24a13c56d7280b6fb3c224feb3400bf978752455e7d6795a1df4f26938fb8056',
            // '0x96bb7a1882340786ed6ecb6203b7e10d447086409a85d91d8e82e80649fd3af6',
            // '0xf7ba02c1090e030aab7f1829d3531d6f58e8eb93363172bc61989c0d96f563c2',
            // '0x24dd5272da263005280cf94d87e72bbdb4d8a9ee5377232397960b225bb24e63',

            '0xb69941cd31f02726a177e2055e2f2ae045aaf8ad3c84d5496c7cebcc2bf974a3',
            '0xd8549953af61850d8f1902574b7697945069d66d4380295fdace876ece687d91',
            '0xb1e83599b8ac667cc14a2d6ab86457aee7897b6903e67edab98a33e90ca5ffd2',
            '0xcab266bfe1438a2f13fd64411e67ff716ce01aa6eee2e97cebbcbb9542f4859a',
            '0x83ee29cb2b249cbdf97bc14c0cbe1a5e4787289302c7ad532fe5452a1ab07cf1',
            '0x82648a806d6d4a3fcfec7b9b7530a4a236fa003b16e75d111927958a74bfd691',
            '0xd2c78eab9a3dc92d5b4f111a42fe7d1b5631533a997a0a650bcc9e01653fac1f',
            '0x0c86912145dcf7bb93893711ef35c7a7ea98a20ac257ad9936535b3313aec71f',
            '0xaf4d0212c4f7ab53be0572639d79cfeba269348c0589984dbd5d6d0c36f7eb76',
            // '0x2d5d61d05e241e52168e54330cc98f04f51fe0f361fbdc926d74737c80b74427',
            // '0xdf55936dcdef6acacecdb6fa19e2e98e24f38f07f7725aab6ca904ede387c329',
            // '0xa469c3815db003a2a99db6634f0d4e7fb027b91a6d971c79718c635ffaeb80a2',
            // '0x33ff9a0bb71157f1c2d495dccbbe9f721c16c0c31d0b84d9701afacc3c044c06',
            // '0xf39f4f07cf61fcfd804098d30f82b12ec658b93eec414ea77a6977e2ddafa4fd',
            // '0x09aa0a0bddab0773c7c3c02dea09e79bcff3e7445941e09dc3b00a490e104a4f',
            // '0xf8e7e575f71a19b2f2755f4937fb19499b124e8f439912ac19a92b61b6de188d',
            // '0xbf421a67628faef5c6772682df5fbd2f44ac65de4b098c1c5405ed6616fd88ca',
            // '0x79342d0e14f95c3d6013aab066253bd704a40101e6c630f07ee3abaeaaa4050c',
            // '0xeb8ea6e7fbba0f7a9801a5e642e6c02a7781dcead1b108586c4202230fc1a75b',
            // '0xf153f99e38249da869e4f1aa11859025b1680bacb38ff48fd448753817d4bb1a'

        ];

        for (let i = 0; i < 8; i++) {
            uris.push(encodedString);
            paramValues.push({
                _seed: seeds[i],
                _params: [],
            });
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