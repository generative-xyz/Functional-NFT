const FunctionFactory = artifacts.require("FunctionFactory");

module.exports = function (deployer) {
        deployer.deploy(FunctionFactory);
};
