// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {dogURI} from "../src/dogURI.sol";

import {NonFungibleDog} from "../src/NonFungibleDog.sol";
import {AmpliceGhouls} from "./ampliceGhoul.sol";
import {DEFS} from "../src/assets/defs.sol";
import {DOG} from "../src/assets/dog.sol";


import "../src/CantoInu.sol";


contract dogURITest is Test {

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
        uri = new dogURI(address(dogNFT), address(ampliceNFT), address(def), address(dog));

        cInu.transfer(address(dogNFT), 830_500_000_000_000 * 10**18);

        vm.deal(Alice, 100*10**18);
        vm.deal(Bob, 100*10**18);

        vm.startPrank(Alice);
        payable(ampliceNFT).call{gas: 200_000, value: 1*10**18}("");
        payable(dogNFT).call{gas: 200_000, value: 1*10**18}("");

        vm.stopPrank();

        vm.startPrank(Bob);
        payable(dogNFT).call{gas: 200_000, value: 1*10**17}("");

        vm.stopPrank();


    }

    function _testDefs() public {

        //emit log_string(def.createPNGs(2));
        emit log_string(def.buildDefs(2,true));

    }

    function testUri() public {
        

        string memory uriOutput = uri.uri(0);

        vm.removeFile("./test/output/testUri.txt");
        vm.writeFile("./test/output/testUri.txt",uriOutput);

    }


    function testBalances() public {
        assertEq(dogNFT.balanceOf(Alice),1);
        assertEq(ampliceNFT.balanceOf(Alice),1);



    }


}