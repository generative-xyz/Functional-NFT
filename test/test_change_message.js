var FunctionFactory = artifacts.require("FunctionFactory")

contract("FunctionFactory", function(accounts) {

        const fs = require('fs');

        const code = fs.readFileSync('functions/voronoi.py', 'utf8', (err, data) => {
                if (err) {
                        console.error(err);
                        return;
                }
        });

        const name = "voronoi";
        var contractInstance;

        it("Should add function", function() {
                return FunctionFactory.deployed().then(function(instance) {
                        contractInstance = instance;
                        return instance.setFunction(name, code, {from: accounts[1]});
                }).then(function() {
                        return contractInstance.getFunction(name);
                }).then(function(result) {
                        fs.writeFile('output/' + name, result, err => {
                                if (err) {
                                        console.error(err);
                                }
                        })
                        assert.equal(result, code);
                });
        });

        it("Should retrieve function", function() {
                return FunctionFactory.deployed().then(function(instance) {
                        contractInstance = instance;
                        return contractInstance.getFunction(name);
                }).then(function(result) {
                        fs.writeFile('output/' + name, result, err => {
                                if (err) {
                                        console.error(err);
                                }
                        })
                        assert.equal(result, code);
                });
        });
});
