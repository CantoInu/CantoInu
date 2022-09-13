// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {LibString} from "../src/utils/utils.sol";


contract libStringTest is Test {
    using LibString for *;

    bytes12 constant PLTE_0 = hex'f0e4d1e4cca9ca9962a96e38';
    bytes12 constant PLTE_1 = hex'f0ded1e4bda9ca8362a73e10';
    bytes12 constant PLTE_2 = hex'd9d3cfcbc4b2bba99299846b';
    bytes12 constant PLTE_3 = hex'dfdddbece7d8cdc5bceae0d4';
    bytes12 constant PLTE_4 = hex'f0ecd1f0ecd1cab662a98638';
    bytes12 constant PLTE_5 = hex'dfdddba8a28d7b5b36543921';
    bytes12 constant PLTE_6 = hex'cfd6d9b2c0cb819ab36b8c99';
    bytes12 constant PLTE_7 = hex'd1d9cfb7cbb281b3952d7155';
    bytes12 constant PLTE_8 = hex'd2cfd9bbb2cb9581b38b6b99';
    bytes12 constant PLTE_9 = hex'd9d9cfcbcab2b2b38199936b';


    function testBasic() public {

        bytes3 test = hex'123456';

        emit log_string(uint256(uint96(PLTE_0)).toHexStringNoPrefix(12));




    }



}