// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CantoInu.sol";
import "../src/DogPound.sol";
import "../src/DogCatcher.sol";


contract DogCatcherTest is Test {
    CantoInu public cINU;
    DogPound public pound;
    DogCatcher public catcher;
    
    function setUp() public logs_gas {
       vm.startPrank(address(0xa11ce));
       cINU = new CantoInu();
       pound = new DogPound(address(cINU));
       catcher = new DogCatcher();
       cINU.transfer(address(pound), 931_000_000_000_000 * 10**18);
       vm.stopPrank();
    }

    function testCatcherDeposit() public {
        vm.deal(address(0xb0b),1000*10**18);
        vm.startPrank(address(0xb0b));

        payable(pound).call{gas: 100_000, value: 10*10**18}("");

        assertEq(cINU.balanceOf(address(pound)), (931_000_000_000_000 * 10**18 - 50_000_000_000 * 10**18));
        assertEq(cINU.balanceOf(address(0xb0b)), 50_000_000_000 * 10**18);

        vm.stopPrank();
        vm.startPrank(address(0xa11ce));

        pound.setRouter(address(catcher)); 

        pound.fillLP();

        assertEq(cINU.balanceOf(address(catcher)), (931_000_000_000_000 * 10**18 - 50_000_000_000 * 10**18));
        assertEq(address(catcher).balance, 10*10**18);

        catcher.retrieveCANTO(address(0xbeef), address(catcher).balance);
        catcher.retrieveCINU(address(0xbeef), cINU.balanceOf(address(catcher)));

        assertEq(cINU.balanceOf(address(0xbeef)), (931_000_000_000_000 * 10**18 - 50_000_000_000 * 10**18));
        assertEq(address(0xbeef).balance, 10*10**18);

    }

    

}
