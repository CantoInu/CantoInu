// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {dogURI} from "../src/dogURI.sol";

import {NonFungibleDog} from "../src/NonFungibleDog.sol";
import {AmpliceGhouls} from "./ampliceGhoul.sol";
import "../src/CantoInu.sol";


contract dogURITest is Test {

    dogURI uri;
    AmpliceGhouls ampliceNFT;
    NonFungibleDog dogNFT;
    CantoInu cInu;

    address Alice = address(0xa11ce);
    address Bob = address(0xb0b);

    function setUp() public {

        cInu = new CantoInu();

        dogNFT = new NonFungibleDog(address(cInu));
        ampliceNFT = new AmpliceGhouls();
        uri = new dogURI(address(dogNFT),address(ampliceNFT));

        cInu.transfer(address(dogNFT), 830_500_000_000_000 * 10**18);

        vm.deal(Alice, 100*10**18);

        vm.startPrank(Alice);
        payable(ampliceNFT).call{gas: 200_000, value: 1*10**18}("");
        payable(dogNFT).call{gas: 200_000, value: 1*10**18}("");

        vm.stopPrank();

    }


    function testBalances() public {
        assertEq(dogNFT.balanceOf(Alice),1);
        assertEq(ampliceNFT.balanceOf(Alice),1);

    }


}