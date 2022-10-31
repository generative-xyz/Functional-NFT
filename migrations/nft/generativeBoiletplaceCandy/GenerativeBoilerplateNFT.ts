import {createAlchemyWeb3} from "@alch/alchemy-web3";
import * as path from "path";

const {ethers, upgrades} = require("hardhat");
const hardhatConfig = require("../../../hardhat.config");

class GenerativeBoilerplateNFTCandy {
    network: string;
    senderPublicKey: string;
    senderPrivateKey: string;

    constructor(network: any, senderPrivateKey: any, senderPublicKey: any) {
        this.network = network;
        this.senderPrivateKey = senderPrivateKey;
        this.senderPublicKey = senderPublicKey;
    }

    async upgradeContract(proxyAddress: any) {
        const contractUpdated = await ethers.getContractFactory("GenerativeBoilerplateNFTCandy");
        console.log('Upgrading GenerativeBoilerplateNFTCandy... by proxy ' + proxyAddress);
        const tx = await upgrades.upgradeProxy(proxyAddress, contractUpdated);
        console.log('GenerativeBoilerplateNFTCandy upgraded on tx address ' + tx.address);
        return tx;
    }

    async deployUpgradeable(name: string, symbol: string, baseUri: string, adminAddress: any, paramAdd: any) {
        if (this.network == "local") {
            console.log("not run local");
            return;
        }

        const contract = await ethers.getContractFactory("GenerativeBoilerplateNFTCandy");
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
        let contract = require(path.resolve("./artifacts/contracts/nft/GenerativeBoilerplateNFTCandy.sol/GenerativeBoilerplateNFTCandy.json"));
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

    async getBaseUri(contractAddress: any) {
        let temp = this.getContract(contractAddress);
        const nonce = await temp?.web3.eth.getTransactionCount(this.senderPublicKey, "latest") //get latest nonce

        //the transaction
        const tx = {
            from: this.senderPublicKey,
            to: contractAddress,
            nonce: nonce,
        }

        return await temp?.nftContract.methods.baseTokenURI().call(tx);
    }

    async getAdmin(contractAddress: any) {
        let temp = this.getContract(contractAddress);
        const nonce = await temp?.web3.eth.getTransactionCount(this.senderPublicKey, "latest") //get latest nonce

        //the transaction
        const tx = {
            from: this.senderPublicKey,
            to: contractAddress,
            nonce: nonce,
        }

        const param = await temp?.nftContract.methods._paramsAddress().call(tx);
        const admin = await temp?.nftContract.methods._admin().call(tx);
        return {admin, param};
    }

    async mintProject(contractAddress: any, to: any,
                      maxSupply: number, maxNotOwner: number, script: string, fee: any, feeAdd: any, paramsTemplate: any,
                      gas: number) {
        let temp = this.getContract(contractAddress);
        const nonce = await temp?.web3.eth.getTransactionCount(this.senderPublicKey, "latest") //get latest nonce

        var accountOneGasPrice = null;
        // var accountOneGasPrice = (await temp?.web3.eth.getTransaction("0x3b6fcff318f6b7ba0b1fc2252c6e4a41092c2431b7ee0aa927e60ac93334382a"));
        // console.log({accountOneGasPrice});
        // return;

        const fun = temp?.nftContract.methods.mintProject(to, maxSupply, maxNotOwner, script, fee, feeAdd, paramsTemplate);
        //the transaction
        const tx = {
            from: this.senderPublicKey,
            to: contractAddress,
            nonce: accountOneGasPrice ? accountOneGasPrice["nonce"] : nonce,
            gas: accountOneGasPrice ? accountOneGasPrice["gas"] : gas,
            data: fun.encodeABI(),
        }

        if (tx.gas == 0) {
            // console.log(tx.data);
            tx.gas = await fun.estimateGas(tx);
            console.log(2222);
        }

        return await this.signedAndSendTx(temp?.web3, tx);
    }

    async mintUniqueNFT(contractAddress: any, mintTo: any, value: any, tokenId: number,
                        gas: any) {
        let temp = this.getContract(contractAddress);
        const nonce = await temp?.web3.eth.getTransactionCount(this.senderPublicKey, "latest") //get latest nonce

        const fun = temp?.nftContract.methods.mintUniqueNFT(mintTo, value, tokenId);
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

    async burn(contractAddress: any, tokenId: number,
               gas: any) {
        let temp = this.getContract(contractAddress);
        const nonce = await temp?.web3.eth.getTransactionCount(this.senderPublicKey, "latest") //get latest nonce

        const fun = temp?.nftContract.methods.burn(tokenId);
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

    async get_paramsValues(contractAddress: any, tokenId: number) {
        let temp = this.getContract(contractAddress);
        const nonce = await temp?.web3.eth.getTransactionCount(this.senderPublicKey, "latest") //get latest nonce
        console.log("asfafaf");
        //the transaction
        const tx = {
            from: this.senderPublicKey,
            to: contractAddress,
            nonce: nonce,
        }


        const val: any = await temp?.nftContract.methods.getParamValues(tokenId).call(tx);
        return val;
    }

    async getTraits(contractAddress: any) {
        let temp = this.getContract(contractAddress);
        const nonce = await temp?.web3.eth.getTransactionCount(this.senderPublicKey, "latest") //get latest nonce
        // console.log("asfafaf");
        //the transaction
        const tx = {
            from: this.senderPublicKey,
            to: contractAddress,
            nonce: nonce,
        }


        const val: any = await temp?.nftContract.methods.getTraits().call(tx);
        return val;
    }

    async getTokenTraits(contractAddress: any, tokenId: number) {
        let temp = this.getContract(contractAddress);
        const nonce = await temp?.web3.eth.getTransactionCount(this.senderPublicKey, "latest") //get latest nonce
        //the transaction
        const tx = {
            from: this.senderPublicKey,
            to: contractAddress,
            nonce: nonce,
        }


        const val: any = await temp?.nftContract.methods.getTokenTraits(tokenId).call(tx);
        return val;
    }

    async updateTraits(contractAddress: any, traits: any,
                       gas: any) {
        let temp = this.getContract(contractAddress);
        const nonce = await temp?.web3.eth.getTransactionCount(this.senderPublicKey, "latest") //get latest nonce

        const fun = temp?.nftContract.methods.updateTraits(traits);
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

    async storeScript(contractAddress: any, projectId: number, script: string,
                      gas: any) {
        let temp = this.getContract(contractAddress);
        const nonce = await temp?.web3.eth.getTransactionCount(this.senderPublicKey, "latest") //get latest nonce

        const fun = temp?.nftContract.methods.storeScript(projectId, script);
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
}

export {GenerativeBoilerplateNFTCandy};