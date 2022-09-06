// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

import {background} from "./assets/background.sol";
import {defs} from "./assets/defs.sol";
import {dog} from "./assets/dog.sol";

import {LibString, Base64} from "./utils/utils.sol";

interface IAmpliceGhoul {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface INonFungibleDog {
    function getRank(uint256 tokenId) external view returns (uint256);
    function getTimesBurnt(uint256 tokenId) external view returns (uint256);
    function getCInuBurnt(uint256 tokenId) external view returns (uint256);
}



contract dogURI{
    using LibString for string;

    IAmpliceGhoul ampliceGhoul;
    INonFungibleDog nonFungibleDog;

    struct NFT_DATA {
        uint256 rank;
        uint256 burnTimesCount;
        uint256 burnAmtCount;
        bool ampliceHolder;
    }

    struct SVG_STATE {
        string defs;
        string baseElements;
        string attrElements;
    }

    string constant SVG_HEADER = '<svg version="1.1" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">//<mask id="screen"><rect width="310" height="310" x="20" y="20" rx="20" fill="white"/>';
    string constant SVG_FOOTER = '</svg>';

    string[] private goodBoy = [
        "Top Dog",
        "A very good dog indeed",
        "Such a good pup",
        "Man's best friend",
        "Cheemsburbger",
        "Thank You Based Dog",
        "They're good dogs, Brent",
        "13/10"
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
        "white",
        "yellow",
        "blue",
        "green",
        "orange",
        "blue",
        "purple",
        "gray"
    ];

    string[] private objects = [
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

    /*
    function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, tokenId.toString())));
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            output = string(abi.encodePacked(output, " ", suffixes[rand % suffixes.length]));
        }
        if (greatness >= 19) {
            string[2] memory name;
            name[0] = namePrefixes[rand % namePrefixes.length];
            name[1] = nameSuffixes[rand % nameSuffixes.length];
            if (greatness == 19) {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output));
            } else {
                output = string(abi.encodePacked('"', name[0], ' ', name[1], '" ', output, " +1"));
            }
        }
        return output;
    }
    */



    function uri(uint256 id) external view returns (string memory) {

        NFT_DATA memory tokenInfo = NFT_DATA(
            nonFungibleDog.getRank(id),
            nonFungibleDog.getTimesBurnt(id),
            nonFungibleDog.getCInuBurnt(id),
            ampliceGhoul.balanceOf(msg.sender) > 0 //need to figure out if this works
        );

        // initialize a blank state element
        SVG_STATE memory s = SVG_STATE(
            "",
            "",
            ""
        );

        // build common elements (background)


        // calculate background layer color

        // add amplice?
        
        return string.concat(
            SVG_HEADER,
            s.defs,
            s.baseElements,
            s.attrElements,
            SVG_FOOTER
        );
    }



    constructor(
        address _nonFungibleDog, 
        address _ampliceGhoul
        ){
            nonFungibleDog =INonFungibleDog(_nonFungibleDog);
            ampliceGhoul = IAmpliceGhoul(_ampliceGhoul);
        }  

}