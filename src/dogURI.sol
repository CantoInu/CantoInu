// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

//import {DEFS} from "./assets/defs.sol";
//import {dog} from "./assets/dog.sol";

import {LibString, Base64} from "./utils/utils.sol";
import {libDogEffects} from "./libs/libDogEffects.sol";

interface ICInu {
    function totalSupply() external view returns (uint256);
}

interface IAmpliceGhoul {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface INonFungibleDog {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint256);
    function getRank(uint256 tokenId) external view returns (uint256);
    function getTimesBurnt(uint256 tokenId) external view returns (uint256);
    function getCInuBurnt(uint256 tokenId) external view returns (uint256);

}

interface IDefs {
    function buildDefs(uint8 eyeAttr, bool amplice) external pure returns (string memory);
    function getAttributePlacements(uint8 eyeAttr, bool amplice) external view returns (string memory useStr);
    function getBackground(string memory _borderLvl, string memory _noiseColor) external pure returns (string memory);
    function createPNGs(uint256 count) external pure returns (string memory pngRunners);
}

interface IDog {
    function fetchDog(uint8 colourIdx)  external pure returns (string memory);
    function fetchDog(uint8 colourIdx, string memory chewToy)  external pure returns (string memory);
    function getColorName(uint8 colourIdx) external pure returns (string memory);
}


contract dogURI{
    using LibString for uint256;

    // set this to reveal only when less than 690t total supply
    bool revealed;
    string DNAJuice;

    IAmpliceGhoul ampliceGhoul;
    INonFungibleDog nonFungibleDog;
    IDefs defs;
    IDog dog;

    struct DOG_ATTR {
        uint8 bg_color;
        uint8 dog_color;
        uint8 words_text;
        uint8 words_color;
        uint8 eyes;
        uint8 filters;
        uint8 chewToys;
        uint8 animation;
        uint8 noise_color;
        uint8 goodBoy_text;
        bool amplice;
    }

    struct STATS_DATA {
        uint256 rank;
        uint256 burnTimesCount;
        uint256 burnAmtCount;
    }

    struct IMAGE_DATA {
        string defs;
        string bgElement;
        string dogElement;
    }


    struct SVG_STATE {
        uint256 id;
        DOG_ATTR attr;
        STATS_DATA stats;
        IMAGE_DATA img;
        string jsonAttr;
    }

    string constant SVG_HEADER = '<svg version="1.1" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><mask id="screen"><rect width="310" height="310" x="20" y="20" rx="20" fill="white" /></mask>';
    string constant SVG_FOOTER = '</svg>';

    // first 8 normal, 9th for missing dogs
    string[] private goodBoy = [
        "Top Dog",
        "A very good dog indeed",
        "Such a good pup",
        "Man's best friend",
        "Cheemsburbger",
        "Thank You Based Dog",
        "They're good dogs, Brent",
        "13/10",
        "Umm hey, where's my dog?"
    ];

    string[] private words = [
        "such wow",
        "very moon",
        "good boi", 
        "many burn",
        "wen",
        "protec",
        "attac",
        "so hodl",
        "muh canto",
        "I havs marketing proposal",
        "bonk",
        "devs do something",
        "no rug pls"
        "@raydaybot",
        "CANTO INU",
        "RIP Miraj"
    ];

    // noise uses full set, words only use first 5
    string[] private colors = [
        "blue",
        "green",
        "orange",
        "blue",
        "purple",
        "gray",
        "yellow",
        "white"
    ];

    string[] private borderLvlColors = [
            "Gold",
            "Silver",
            "#CD7F32",
            "#7FFFD4",
            "#F5F5F5"        
    ];

    //default values, need to be able to set this
    uint256[] private borderLvlAmts = [
        16_900_000_000_000 * 10**18,
        8_450_000_000_000 * 10**18,
        4_225_000_000_000 * 10**18,
        845_000_000_000 * 10**18
    ];

    string[] private chewToys = [
        unicode"🦴",
        unicode"🦴",
        unicode"🍖",
        unicode"🚀",
        unicode"🐕",
        unicode"🐈",
        unicode"🦶",
        unicode"☠️",
        unicode"🤝",
        unicode"🧟",
        unicode"🫂",
        unicode"🥓",
        unicode"🍔",
        unicode"🗾",
        unicode"🌙",
        unicode"🔥",
        unicode"📫",
        unicode"📈",
        unicode"🛹",
        unicode"🏏",
        unicode"💣"
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function bg_colour_idx(uint256 _burn) internal view returns (uint8) {
        if (_burn > borderLvlAmts[0]) {
            return 0;
        } else if (_burn > borderLvlAmts[1]) {
            return 1;
        } else if (_burn > borderLvlAmts[2]) {
            return 2;
        } else if (_burn > borderLvlAmts[3]) {
            return 3;
        } else {
            return 4;
        }
    }

    function attributify(uint256 _id, bool _amplice) internal view returns (DOG_ATTR memory _attr) {
        
        bytes32 dogDna = bytes32(random(string.concat(_id.toString(),DNAJuice)));
         /*//dogDNA is a tightly packed array of bytes used to assign NFT attributes, info arranged as follows:
            // [0-1] - missing dog
            // [2] - dog color
            // [3] - words text
            // [4] - words color
            // [5] - eyes
            // [6] - filters
            // [7] - playToy
            // [8] - animation/transformation
            // [9] - screenNoise
            // [10] - goodBoy text
            */
        

        //first check if this is an ultra rare, missing dog
        bool _missing = uint16((bytes2(dogDna[0])) | bytes2(dogDna[1])>>8)%69 == 0;

        _attr = DOG_ATTR({
            bg_color:       0,
            dog_color:      uint8(uint8(dogDna[2]) % 10),
            words_text:     uint8(dogDna[3]),
            words_color:    uint8(dogDna[4]),
            eyes:           uint8(dogDna[5]),
            filters:        uint8(dogDna[6]),
            chewToys:       uint8(dogDna[7]),
            animation:      uint8(dogDna[8]),
            noise_color:    uint8(uint8(dogDna[9]) % colors.length - 2),
            goodBoy_text:   _missing ? uint8(8) : uint8(uint8(dogDna[10]) % (goodBoy.length-1)),
            amplice:        _amplice
        });
    }

    function word_attr(DOG_ATTR memory _attr) internal view {
        if(_attr.words_text > 127) {
            _attr.words_text %= uint8(words.length);
            _attr.words_color %= uint8(colors.length-2);
        } else {
            _attr.words_text = 255;
            _attr.words_color = 255;
        }
    }

    function dog_attr(DOG_ATTR memory _attr) internal pure {
        _attr.eyes > 127 ? _attr.eyes %= 4 : _attr.eyes = 255;
        _attr.filters > 127 ? _attr.filters %= 6 : _attr.filters = 255;
        _attr.chewToys > 64 ? _attr.chewToys % 18 : _attr.chewToys = 255;
        _attr.animation > 127 ? _attr.animation %= 10 : _attr.animation = 255;
    }   

    function attributes(uint256 id, bool amplice) internal view returns (DOG_ATTR memory attr) {

        attr = attributify(id, amplice);

        //update attributes for rarity
        word_attr(attr);
        dog_attr(attr);

    }

    function initializeState(uint256 id) internal view returns (SVG_STATE memory s) {


        STATS_DATA memory tokenInfo = STATS_DATA(
            nonFungibleDog.getRank(id),
            nonFungibleDog.getTimesBurnt(id),
            nonFungibleDog.getCInuBurnt(id)
        );

        address dogOwner = nonFungibleDog.ownerOf(id);

        DOG_ATTR memory attr = attributes(id, ampliceGhoul.balanceOf(dogOwner) > 0);
        attr.bg_color = bg_colour_idx(tokenInfo.burnAmtCount);

        IMAGE_DATA memory img;

        s = SVG_STATE(
            id,
            attr,
            tokenInfo,
            img,
            ""
        );
    }

    // This one is a heavy one, we may need to rethink it
    function createStats(SVG_STATE memory s) internal view returns (string memory statsStr) {

        statsStr = string.concat(
            '<g class="stats"><text x="33" y="40">NFT ID: ',
            s.id.toString(),
            '</text><text x="160" y="40">RANK: ',
            s.stats.rank.toString(),
            '/',
            nonFungibleDog.totalSupply().toString(),
            '</text><text x="33" y="70">cINU Burnt: ',
            (s.stats.burnAmtCount/10**18).toString(),
            '</text><text x="33" y="85">Good dog? ',
            goodBoy[s.attr.goodBoy_text],
            '</text></g>'
        );

        return statsStr;
    }

    function writeDefs(SVG_STATE memory s) internal view {
        s.img.defs = defs.buildDefs(s.attr.eyes, s.attr.amplice);

    }

    function writeBG(SVG_STATE memory s) internal view {

        s.img.bgElement = string.concat(
            defs.getBackground(borderLvlColors[s.attr.bg_color], colors[s.attr.noise_color]),
            defs.createPNGs(s.stats.burnTimesCount),
            createStats(s)
        );

    }

    function writeDog(SVG_STATE memory s) internal view {
        //@todo add transform animation
        string memory dogEl = '<g id="dog">';

        if (s.attr.chewToys == 255) {
            dogEl = string.concat(
                dogEl,
                dog.fetchDog(s.attr.dog_color)
            );
        } else {
            dogEl = string.concat(
                dogEl,
                dog.fetchDog(s.attr.dog_color,chewToys[s.attr.chewToys])
            );
        }

        if(s.attr.words_text != 255) {
            dogEl = string.concat(
                dogEl,
                libDogEffects.getWordBubble(words[s.attr.words_text],colors[s.attr.words_color])
            );
        }

        dogEl = string.concat(
            dogEl,
            defs.getAttributePlacements(s.attr.eyes, s.attr.amplice),
            '</g>'
        );

        s.img.dogElement = dogEl;

    }

    
    function returnImg(SVG_STATE memory s) internal returns (string memory) {
                
        writeDefs(s);

        writeBG(s);

        if(s.attr.goodBoy_text != 8) {
            writeDog(s);
        } else {
            defs.getAttributePlacements(255, s.attr.amplice);
        }
        

        return string.concat(
            s.img.defs,
            s.img.bgElement,
            s.img.dogElement
        );

    }

    function uri(uint256 id) external returns (string memory) {

        if(revealed) {
            // initialize state elements
            SVG_STATE memory s = initializeState(id);

            string memory img = returnImg(s);
            
            return string.concat(
                SVG_HEADER,
                img,
                SVG_FOOTER
            );
        }

    }

    //@todo hardcode this before launch
    function revealNFTs() external {
        ICInu cINU = ICInu(0x7264610A66EcA758A8ce95CF11Ff5741E1fd0455);
        require(cINU.totalSupply() <= 690_000_000_000_000 * 10**18, "Cannot reveal until Total Supply is under 690t");

        revealed = true;
        DNAJuice = block.timestamp.toString();

    }


    //can hardcode NFT and Amplice
    constructor(
        address _nonFungibleDog, 
        address _ampliceGhoul,
        address _defs,
        address _dog
        ){
            nonFungibleDog = INonFungibleDog(_nonFungibleDog);
            ampliceGhoul = IAmpliceGhoul(_ampliceGhoul);
            defs = IDefs(_defs);
            dog = IDog(_dog);
        }  

}