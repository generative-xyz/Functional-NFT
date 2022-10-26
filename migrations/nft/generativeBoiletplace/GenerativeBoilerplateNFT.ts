import {createAlchemyWeb3} from "@alch/alchemy-web3";
import * as path from "path";

const {ethers, upgrades} = require("hardhat");
const hardhatConfig = require("../../../hardhat.config");

class GenerativeBoilerplateNFT {
    network: string;
    senderPublicKey: string;
    senderPrivateKey: string;

    constructor(network: any, senderPrivateKey: any, senderPublicKey: any) {
        this.network = network;
        this.senderPrivateKey = senderPrivateKey;
        this.senderPublicKey = senderPublicKey;
    }

    async upgradeContract(proxyAddress: any) {
        const contractUpdated = await ethers.getContractFactory("GenerativeBoilerplateNFT");
        console.log('Upgrading GenerativeBoilerplateNFT... by proxy ' + proxyAddress);
        const tx = await upgrades.upgradeProxy(proxyAddress, contractUpdated);
        console.log('GenerativeBoilerplateNFT upgraded on tx address ' + tx.address);
        return tx;
    }

    async deployUpgradeable(name: string, symbol: string, baseUri: string, adminAddress: any, paramAdd: any) {
        if (this.network == "local") {
            console.log("not run local");
            return;
        }

        const contract = await ethers.getContractFactory("GenerativeBoilerplateNFT");
        console.log("GenerativeBoilerplateNFT.deploying ...")
        const proxy = await upgrades.deployProxy(contract, [name, symbol, baseUri, adminAddress, paramAdd], {
            initializer: 'initialize(string, string, string, address, address)',
        });
        await proxy.deployed();
        console.log("GenerativeBoilerplateNFT deployed at proxy:", proxy.address);
        return proxy.address;
    }

    async signedAndSendTx(web3: any, tx: any) {
        const signedTx = await web3.eth.accounts.signTransaction(tx, this.senderPrivateKey)
        if (signedTx.rawTransaction != null) {
            let sentTx = await web3.eth.sendSignedTransaction(
                signedTx.rawTransaction,
                function (err: any, hash: any) {
                    if (!err) {
                        console.log(
                            "The hash of your transaction is: ",
                            hash,
                            "\nCheck Alchemy's Mempool to view the status of your transaction!"
                        )
                    } else {
                        console.log(
                            "Something went wrong when submitting your transaction:",
                            err
                        )
                    }
                }
            )
            return sentTx;
        }
        return null;
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
        let contract = require(path.resolve("./artifacts/contracts/nft/GenerativeBoilerplateNFT.sol/GenerativeBoilerplateNFT.json"));
        const web3 = createAlchemyWeb3(API_URL)
        const nftContract = new web3.eth.Contract(contract.abi, contractAddress)
        return {web3, nftContract};
    }

    async getTokenURI(contractAddress: any, tokenID: number) {
        let temp = this.getContract(contractAddress);
        const nonce = await temp?.web3.eth.getTransactionCount(this.senderPublicKey, "latest") //get latest nonce

        //the transaction
        const tx = {
            from: this.senderPublicKey,
            to: contractAddress,
            nonce: nonce,
        }

        const val: any = await temp?.nftContract.methods.tokenURI(tokenID).call(tx);
        return val;
    }

    async getProject(contractAddress: any, tokenID: number) {
        let temp = this.getContract(contractAddress);
        const nonce = await temp?.web3.eth.getTransactionCount(this.senderPublicKey, "latest") //get latest nonce

        //the transaction
        const tx = {
            from: this.senderPublicKey,
            to: contractAddress,
            nonce: nonce,
        }

        return await temp?.nftContract.methods._projects(tokenID).call(tx);
    }

    async setCustomURI(contractAddress: any, tokenId: number, uri: string, gas: number) {
        let temp = this.getContract(contractAddress);
        const nonce = await temp?.web3.eth.getTransactionCount(this.senderPublicKey, "latest") //get latest nonce

        const fun = temp?.nftContract.methods.setCustomURI(tokenId, uri);
        //the transaction
        const tx = {
            from: this.senderPublicKey,
            to: contractAddress,
            nonce: nonce,
            gas: gas,
            data: fun.encodeABI(),
        }

        if (tx.gas == 0) {
            tx.gas = await fun.estimateGas(tx);
        }

        return await this.signedAndSendTx(temp?.web3, tx);
    }

    async generateSeeds(contractAddress: any, projectId: number, amount: number, gas: number) {
        let temp = this.getContract(contractAddress);
        const nonce = await temp?.web3.eth.getTransactionCount(this.senderPublicKey, "latest") //get latest nonce

        const fun = temp?.nftContract.methods.generateSeeds(projectId, amount);
        //the transaction
        const tx = {
            from: this.senderPublicKey,
            to: contractAddress,
            nonce: nonce,
            gas: gas,
            data: fun.encodeABI(),
        }

        if (tx.gas == 0) {
            tx.gas = await fun.estimateGas(tx);
        }

        const txS = await this.signedAndSendTx(temp?.web3, tx);
        const events = await temp?.nftContract.getPastEvents("GenerateSeeds");
        if (events != null) {
            console.log("seeds", events[0].returnValues.seeds);
        }
        return txS;
    }

    async cancelTx() {
        let API_URL: any;
        API_URL = hardhatConfig.networks[hardhatConfig.defaultNetwork].url;
        // load contract
        const web3 = createAlchemyWeb3(API_URL)
        var accountOneGasPrice = (await web3.eth.getTransaction("0x7ebc95e904d2c63256326086d71e6f8f688b85767478ac78bfbb4fc1d9914c52"));

        //the transaction
        const tx = {
            from: this.senderPublicKey,
            to: "0xF61234046A18b07Bf1486823369B22eFd2C4507F",
            nonce: accountOneGasPrice ? accountOneGasPrice["nonce"] : 0,
            gas: accountOneGasPrice ? accountOneGasPrice["gas"] : 0,
            value: 0,
        }

        return await this.signedAndSendTx(web3, tx);
    }

    async mintProject(contractAddress: any, to: any,
                      projectName: string, maxSupply: number, maxNotOwner: number, script: string,
                      scriptType: number, clientSeed: boolean, uri: string, fee: any, feeAdd: any, paramsTemplate: any,
                      gas: number) {
        let temp = this.getContract(contractAddress);
        const nonce = await temp?.web3.eth.getTransactionCount(this.senderPublicKey, "latest") //get latest nonce

        var accountOneGasPrice = null;
        // var accountOneGasPrice = (await temp?.web3.eth.getTransaction("0x3b6fcff318f6b7ba0b1fc2252c6e4a41092c2431b7ee0aa927e60ac93334382a"));
        // console.log({accountOneGasPrice});
        // return;

        const fun = temp?.nftContract.methods.mintProject(to, projectName, maxSupply, maxNotOwner, script, scriptType, clientSeed, uri, fee, feeAdd, paramsTemplate);
        //the transaction
        const tx = {
            from: this.senderPublicKey,
            to: contractAddress,
            nonce: accountOneGasPrice ? accountOneGasPrice["nonce"] : nonce,
            gas: accountOneGasPrice ? accountOneGasPrice["gas"] : gas,
            data: fun.encodeABI(),
        }

        if (tx.gas == 0) {
            tx.gas = await fun.estimateGas(tx);
        }

        return await this.signedAndSendTx(temp?.web3, tx);
    }

    async mintBatchUniqueNFT(contractAddress: any, mintBatch: any,
                             gas: any) {
        let temp = this.getContract(contractAddress);
        const nonce = await temp?.web3.eth.getTransactionCount(this.senderPublicKey, "latest") //get latest nonce

        const fun = temp?.nftContract.methods.mintBatchUniqueNFT(mintBatch);
        //the transaction
        const tx = {
            from: this.senderPublicKey,
            to: contractAddress,
            nonce: nonce,
            gas: gas,
            data: fun.encodeABI(),
        }

        if (tx.gas == 0) {
            tx.gas = await fun.estimateGas(tx);
        }

        return await this.signedAndSendTx(temp?.web3, tx);
    }
}

export {GenerativeBoilerplateNFT};