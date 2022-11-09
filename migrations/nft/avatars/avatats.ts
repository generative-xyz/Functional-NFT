import {createAlchemyWeb3} from "@alch/alchemy-web3";
import * as path from "path";

const {ethers, upgrades} = require("hardhat");
const hardhatConfig = require("../../../hardhat.config");

class AVATARS {

    network: string;
    senderPublicKey: string;
    senderPrivateKey: string;

    constructor(network: any, senderPrivateKey: any, senderPublicKey: any) {
        this.network = network;
        this.senderPrivateKey = senderPrivateKey;
        this.senderPublicKey = senderPublicKey;
    }

    async deployUpgradeable(name: string, symbol: string, adminAddress: any, paramAdd: any, link: any, oracle: any) {
        if (this.network == "local") {
            console.log("not run local");
            return;
        }

        const contract = await ethers.getContractFactory("AVATARS");
        console.log("AVATARS.deploying ...")
        const proxy = await upgrades.deployProxy(contract, [name, symbol, adminAddress, paramAdd, link, oracle], {
            initializer: 'initialize(string, string, address, address, address, address)',
        });
        await proxy.deployed();
        console.log("AVATARS deployed at proxy:", proxy.address);
        return proxy.address;
    }

    getContract(contractAddress: any) {
        console.log("Network run", this.network, hardhatConfig.networks[this.network].url);
        if (this.network == "local") {
            console.log("not run local");
            return;
        }
        let API_URL: any;
        API_URL = hardhatConfig.networks[hardhatConfig.defaultNetwork].url;

        // load contract
        let contract = require(path.resolve("./artifacts/contracts/nft/AVATARS.sol/AVATARS.json"));
        const web3 = createAlchemyWeb3(API_URL)
        const nftContract = new web3.eth.Contract(contract.abi, contractAddress)
        return {web3, nftContract};
    }

    async upgradeContract(proxyAddress: any) {
        const contractUpdated = await ethers.getContractFactory("AVATARS");
        console.log('Upgrading AVATARS... by proxy ' + proxyAddress);
        const tx = await upgrades.upgradeProxy(proxyAddress, contractUpdated);
        console.log('AVATARS upgraded on tx address ' + tx.address);
        return tx;
    }
}

export {AVATARS}