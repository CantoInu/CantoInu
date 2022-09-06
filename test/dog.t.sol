// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {dog} from "../src/assets/dog.sol";
import {defs} from "../src/assets/defs.sol";

contract dogTest is Test {

    dog dogImg;
    defs defBuilder;

    function setUp() public {

        dogImg = new dog();
        defBuilder = new defs();

    }

    string[4] plte = [
        '#f0e4d1',
        '#e4cca9',
        '#ca9962',
        '#a96e38'
    ];

    function testDogUri() public {

        emit log_string(dogImg.fetchDog(plte));
        emit log_string(defBuilder.getAllConsts());
    }


}