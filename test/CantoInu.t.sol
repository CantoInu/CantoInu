// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import "../src/CantoInu.sol";

contract CantoInuTest is Test {
    CantoInu public cINU;
    
    function setUp() public {
       cINU = new CantoInu();
    }

    function testGetByteCode() public {
        emit log_bytes(type(CantoInu).creationCode);
        emit log_bytes(address(cINU).code);


    }

    function testInvariantMetaData() public {
        assertEq(cINU.name(), "CANTO INU");
        assertEq(cINU.symbol(), "cINU");
        assertEq(cINU.decimals(), 18);
        assertEq(cINU.totalSupply(), 1_000_000_000_000_000 * 10**18);

        assertEq(cINU.balanceOf(address(this)), 1_000_000_000_000_000 * 10**18);

    }

    function testBurn() public {
        cINU.burn(10);

        assertEq(cINU.balanceOf(address(this)), 1_000_000_000_000_000 * 10**18 - 10);
        assertEq(cINU.totalSupply(), 1_000_000_000_000_000 * 10**18 - 10);

    }

}
