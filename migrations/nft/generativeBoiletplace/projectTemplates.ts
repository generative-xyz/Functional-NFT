const candyProject = {
    name: "Candy algo 1",
    description: "",
    script: "/Users/autonomous/Documents/generative-objs/Functional-NFT/test_script/candy.py",
    scriptType: 1,
    image: "ipfs://QmRanwBkgwgmbfHfwAmkEhbZyQui8FdkYpBrJ9BWcwt7Pf",
    fee: "0.0",
    feeTokenAddr: "0x0000000000000000000000000000000000000000",
    maxMint: 0,
    clientSeed: true,
    params: [
        { // color
            _typeValue: 3,
            _max: 0,
            _min: 0,
            _decimal: 0,
            _availableValues: [
                "#7030A0,#E59B15,#4F493D,#6E9077,#F8CD7D",
                "#4D5B77,#87ABBC,#B6E4EF,#F9F9E5,#E3EDEF",
                "#D5B4CE,#EDDF9F,#FEBFB4,#B8D5D6,#D9ADB9",
                "#5D4436,#874F2F,#A6633B,#C27C53,#2E405D"
            ],
            _value: 0,
            _editable: false,
        },
        { // shape
            _typeValue: 1,
            _max: 5,
            _min: 1,
            _decimal: 0,
            _availableValues: ["1", "2", "3", "4", "5", "6", "7"],
            _value: 0,
            _editable: false,
        },
        { // height
            _typeValue: 1,
            _max: 5,
            _min: 1,
            _decimal: 0,
            _availableValues: ["1", "2", "3"],
            _value: 0,
            _editable: false,
        },
        {// surface
            _typeValue: 2,
            _max: 5,
            _min: 1,
            _decimal: 0,
            _availableValues: ["0", "0.5", "1"],
            _value: 0,
            _editable: false,
        }
    ]
};

const voronoiProject = {
    name: "Voronoi 1",
    description: "",
    script: "/Users/autonomous/Documents/generative-objs/Functional-NFT/test_script/voronoi.py",
    scriptType: 1,
    image: "ipfs://QmRanwBkgwgmbfHfwAmkEhbZyQui8FdkYpBrJ9BWcwt7Pf",
    fee: "0.0",
    feeTokenAddr: "0x0000000000000000000000000000000000000000",
    maxMint: 0,
    clientSeed: true,
    params: [{
        _typeValue: 0,
        _max: 5,
        _min: 1,
        _decimal: 0,
        _availableValues: [],
        _value: 0,
        _editable: false,
    }, {
        _typeValue: 1,
        _max: 65535,
        _min: 100,
        _decimal: 0,
        _availableValues: [],
        _value: 0,
        _editable: false,
    }]
};

export {candyProject, voronoiProject};