// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "forge-std/console.sol";


import {dogURI} from "../src/dogURI.public.sol";

import {NonFungibleDog} from "../src/NonFungibleDog.sol";
import {AmpliceGhouls} from "./ampliceGhoul.sol";
import {DEFS} from "../src/assets/defs.sol";
import {DOG} from "../src/assets/dog.sol";

import "../src/utils/utils.sol";

import "../src/CantoInu.sol";

string constant DNAJuice = "1668594201";

contract dogURI_piecesTest is Test {
    
    dogURI uri;
    AmpliceGhouls ampliceNFT;
    NonFungibleDog dogNFT;
    CantoInu cInu;
    DEFS def;
    DOG dog;

    address Alice = address(0xa11ce);
    address Bob = address(0xb0b);

    function setUp() public {

        cInu = new CantoInu();

        dogNFT = new NonFungibleDog(address(cInu));
        ampliceNFT = new AmpliceGhouls();
        def = new DEFS();
        dog = new DOG();
        uri = new dogURI(address(def), address(dog), address(dogNFT), address(ampliceNFT));

        cInu.transfer(address(dogNFT), 830_500_000_000_000 * 10**18);

        vm.deal(address(uint160(696969)), 10*10**18);

            vm.startPrank(address(uint160(696969)));
                //payable(ampliceNFT).call{gas: 200_000, value: 1*10**18}("");
                payable(dogNFT).call{gas: 200_000, value: 1*10**18}("");
            vm.stopPrank();

    }

    function testUri() public {
        
        for (uint256 i=1; i<11; i++) {

            vm.deal(address(uint160(i)), 10*10**18);

            vm.startPrank(address(uint160(i)));
                //payable(ampliceNFT).call{gas: 200_000, value: 1*10**18}("");
                payable(dogNFT).call{gas: 200_000, value: 1*10**18}("");
            vm.stopPrank();

            console.logString("here");

            string memory uriOutput = uri.uri(i);
            console.logString(uriOutput);

        }

    }


}
