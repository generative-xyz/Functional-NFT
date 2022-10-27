const candyProject = {
    name: "Candy algo 2",
    description: "",
    script: "/Users/autonomous/Documents/generative-objs/Functional-NFT/test_script/candy.py",
    scriptType: 1,
    image: "ipfs://QmRanwBkgwgmbfHfwAmkEhbZyQui8FdkYpBrJ9BWcwt7Pf",
    animation_url: "",
    fee: "0.0",
    feeTokenAddr: "0x0000000000000000000000000000000000000000",
    maxMint: 0,
    notOwnerLimit: 0,
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

const candyProject2 = {
    name: "SWEET - On-chain Candies",
    description: "",
    script: "/Users/autonomous/Documents/generative-objs/Functional-NFT/test_script/candy_2.py",
    scriptType: 1,
    image: "ipfs://QmZha95v86iME98rpxrJWbHerK3JjEHKkiGpdS4NgZKjdb",
    animation_url: "ipfs://QmWF66ri417i2fZ8xzDRKyVzB2bpnUzZXL4ks9dhjphdJk",
    fee: "0.0",
    feeTokenAddr: "0x0000000000000000000000000000000000000000",
    maxMint: 5000,
    notOwnerLimit: 4500,
    clientSeed: true,
    params: [
        { // color
            _typeValue: 3,
            _max: 0,
            _min: 0,
            _decimal: 0,
            _availableValues: [
                "#FFDE8F,#FFE16F,#FFE17F,#FCE357,#FFF879",
                "#F1FFF3,#E3FFED,#D2FFEB,#C1FFED,#AFFFEF",
                "#D2D6FF,#CFCFF9,#D6D1FF,#B6BEFC,#9FB9FA",
                "#DCD8C2,#DDDAD8,#E4DCE1,#E7E0E2,#EDEAEB",
                "#569910,#58A20E,#55AA00,#50AF00,#2EBE00",
                "#E2D7D1,#E0D8D7,#DFD9DA,#E1D9DC,#E3D9DE",
                "#64F8E2,#74FAE4,#91FAE6,#B5FBF7,#E1FBEB",
                "#A38511,#AC8D0F,#B29400,#B49800,#BAA500",
                "#DBEAFD,#E2F2FF,#C8E0F9,#8AD6FF,#CCE2FF",
                "#C0EEFF,#DCF5FF,#BBE9FF,#46E1FF,#BFE7FF",
                "#CA871B,#BB8244,#B1865B,#A48A72,#9A8D84",
                "#F8D8FF,#E4C7FD,#DEB5F6,#C7A1E7,#A68DF5",
                "#E1D2CF,#B08E83,#A9A299,#AFBCB9,#D8D7C8",
                "#C2A752,#E6CEA2,#DDF2BA,#D8EA9E,#E1BE82",
                "#577F84,#76B5BE,#49757A,#5B8B8F,#7AB5BA",
                "#21ADF1,#B5C8F1,#6B96F6,#D1D2E4,#51B7FD",
                "#211C00,#332C00,#413900,#534910,#6D6015",
                "#679502,#5C8601,#4E7101,#415C01,#2F4201",
                "#6F4B50,#7B4449,#C25642,#A5523E,#954C4F",
                "#9EFB00,#BCE131,#AAD24C,#A4B961,#A1A230",
                "#43EA99,#00DD42,#7FBA37,#616C44,#A1BFAD",
                "#8DC1A8,#62A096,#E1D188,#F4EBD2,#FAF2E6",
                "#EAB3FA,#E1AEFF,#B799F1,#9494FF,#6486F0",
                "#707F8D,#99BCA8,#9DE2A0,#7EFE7A,#A3FFB8",
                "#C5D1DE,#D3EBF4,#66E1E5,#5A8588,#8CD0DD",
                "#3A8864,#FFFFFF,#83BA97,#ABD9B7,#D7F0DD",
                "#DDBAF1,#E2A0E0,#CD97B4,#E47686,#C5792F",
                "#3E3F1E,#575931,#4B6734,#26755B,#16876B",
                "#E5E8E5,#CFDCCF,#BCC3BF,#9099A1,#686F8A",
                "#548B97,#597074,#555E5C,#6A7177,#738698",
                "#706A51,#8C8781,#47626C,#9991AD,#D2D1E4",
                "#D7D0D5,#B7DCED,#79D5E7,#6FD2B8,#50B087",
                "#496065,#547772,#509488,#4CAEAA,#00CCD9",
                "#BCF5E8,#BBEBB1,#EFECB4,#E2FA8C,#FFB5D8",
                "#4B5655,#9C9281,#D9C6B4,#F4E1D4,#CFB035",
                "#D5E9EA,#C9D2DA,#A4C5B5,#76C45B,#67BD10",
                "#A5A5A5,#7D8181,#5F5B4B,#574631,#402917",
                "#E0D8E4,#CCD0E6,#6ACAFB,#2EADCF,#2D8C9F",
                "#FFEDE5,#FFFCF9,#D2ECE2,#9DD8C3,#9C735E",
                "#686868,#F3A95F,#DE8347,#DC3E50,#A32945",
                "#B97B7E,#C88893,#D493AA,#081105,#EEBBCC",
                "#DDDCDC,#C6C3C2,#50464C,#774D69,#D81CC6",
                "#00B9D3,#6ECFFF,#D7DBF7,#CFA8BE,#55568B",
                "#00AB85,#007959,#885F70,#614353,#221B1C",
                "#1E4044,#3C2D6C,#63428B,#AD64BC,#E79BBD",
                "#CBE6E2,#F6F1DC,#E4B9B0,#E69CA7,#E96F5C",
                "#4E89B7,#204273,#20477D,#121F41,#86BFDC",
                "#000005,#9A9C9D,#646165,#939999,#D0CDCD",
                "#BDCACB,#D0A384,#D69166,#CF6A4A,#323A42",
                "#B57400,#9A6B3D,#8A7E74,#6B626B,#291B2F",
                "#FFFFFF,#81DFA2,#B6FFAA,#FFA2C4,#FF5DB0",
                "#55877C,#C5C8FB,#FC9DAE,#938495,#C9CDD2",
                "#EF8AAF,#B77593,#557A79,#108F88,#189A8F",
                "#072B19,#858B70,#C28C86,#C19CAC,#D1D0ED",
                "#00141F,#A994BE,#D5C9DF,#EEECF8,#CDAFC6",
                "#230D0A,#52191A,#953A4E,#C2747C,#DDEEF0",
                "#675543,#80BC9F,#F8F5D1,#EEA927,#CD3E28",
                "#4F4F4E,#9C8600,#A19700,#9EBD00,#00F368",
                "#EBDEF3,#D09998,#67593D,#3F3A38,#D9B362",
                "#F682AE,#E2A8CD,#CED6E6,#00D9E4,#009A8E",
                "#FFFEFE,#116174,#002B37,#001117,#639DC6",
                "#423141,#BAC8CE,#E7FBFF,#404B4D,#24211F",
                "#4B1E43,#4EB000,#F5EDEE,#FE4BE9,#E01FEA",
                "#0A0D00,#213926,#4F6E6C,#90B3BF,#D4D8E4",
                "#081403,#576561,#A3B7C3,#8FC7B0,#F4F2EF",
                "#DBCECF,#E4D3DE,#F0CCED,#7D92EA,#1D302E",
                "#F5F8F6,#2DE7AA,#9E08CC,#850CA6,#6D0282",
                "#4FC868,#F6FEEA,#01ADA6,#AC621D,#D3AB29",
                "#5B76BB,#E5F0B3,#C8C4A8,#5E5845,#2D2717",
                "#1F0319,#E8F1C9,#84504B,#8F6F5F,#1E1A1D",
                "#FFB6BE,#CD48CA,#1F7A77,#768C30,#FFFFFF",
                "#003019,#1D6713,#FFEDF9,#DB90FF,#8E51FF",
                "#F4FF79,#F6D75F,#C3A45D,#252B3C,#06182D",
                "#0C0D00,#4C6D11,#FBB8BA,#E719DE,#2A3A3D",
                "#346446,#C3EEF3,#A64680,#762259,#251915",
                "#030400,#471917,#9F7C7D,#F1D8D1,#FDFCFF",
                "#0B816B,#DFD3E7,#ECF4FC,#30D2E3,#22241B",
                "#417C13,#F9C317,#FE81BD,#62A0FF,#3291BC",
                "#0D262B,#E8C5FF,#5E6004,#D8B899,#E9D1D2",
                "#51D8BA,#001105,#747879,#FFFFFF,#FFAC00",
                "#FDFBFF,#F2BCAA,#F7B4FD,#0093A1,#272520",
                "#693312,#D8006D,#00A2F8,#00F2DC,#1DB142",
                "#000000,#0F2615,#CFA4FE,#E5E5E5,#FFFFFF",
                "#0A59A0,#D5FE9C,#F9D1A9,#BA7321,#681B1F",
                "#F6ECE1,#8ADD99,#27545F,#0A334B,#F2D6C6",
                "#80C54A,#044C52,#FDC2A9,#2F3018,#FEC8D1",
                "#99FECD,#3BDD92,#997002,#6C4D03,#2A2726",
                "#E7EDEA,#FAC700,#EA3D06,#120356,#D2EBEF",
                "#FBDD36,#98FF9E,#FFAC92,#DF3999,#0066AB",
                "#0C2404,#1D7B7B,#D4D1FA,#E9E8EF,#AD6C17",
                "#00F0A3,#DCFE8D,#C78F02,#A7500A,#620180",
                "#FFD5CC,#FD97E9,#9B6AFC,#02736E,#048A68",
                "#25919F,#22EBB3,#7CA220,#DF5A0A,#14110B",
                "#670434,#FAB478,#FFF6C8,#9CF700,#154E8C",
                "#120C15,#00958A,#F5F5FF,#FCC4D2,#FFFFFF",
                "#053650,#DAB3F8,#FFF1FB,#FFD5DC,#0F592F",
                "#14054B,#F91180,#FEA853,#FFCA53,#0CE4DF",
                "#141702,#109185,#14CBFB,#B3D5FF,#FFBCBB",
                "#F4E3D2,#FBF0EE,#D19E9E,#133E4B,#001B23",
                "#043A31,#49D2F5,#F2F5FF,#EFD6FF,#5B4C0F"
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
            _editable: true,
        },
        { // height
            _typeValue: 1,
            _max: 5,
            _min: 1,
            _decimal: 0,
            _availableValues: ["1", "1", "1", "1", "1", "1", "2", "2", "2", "3"],
            _value: 0,
            _editable: false,
        },
        {// surface
            _typeValue: 2,
            _max: 5,
            _min: 1,
            _decimal: 0,
            _availableValues: ["0", "0", "0", "0", "0", "0", "0.5", "0.5", "0.5", "1"],
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
    animation_url: "",
    fee: "0.0",
    feeTokenAddr: "0x0000000000000000000000000000000000000000",
    maxMint: 0,
    notOwnerLimit: 0,
    clientSeed: true,
    params: [{
        _typeValue: 1,
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

export {candyProject, candyProject2, voronoiProject};