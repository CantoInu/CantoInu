// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CantoInu.sol";
import "../src/DogPound.sol";



contract DogPoundTest is Test {
    CantoInu public cINU;
    DogPound public pound;
    
    function setUp() public logs_gas {
       cINU = new CantoInu();
       pound = new DogPound(address(cINU));
       cINU.transfer(address(pound), 931_000_000_000_000 * 10**18);
    }

    function testBalances() public {
        assertEq(cINU.balanceOf(address(this)), 69_000_000_000_000 * 10**18);
        assertEq(cINU.balanceOf(address(pound)), 931_000_000_000_000 * 10**18);

    }

    function testReceiverGood() public {
        vm.deal(address(0xb0b),1000*10**18);
        vm.startPrank(address(0xb0b));

        payable(pound).call{gas: 100_000, value: 10*10**18}("");

        assertEq(cINU.balanceOf(address(pound)), (931_000_000_000_000 * 10**18 - 50_000_000_000 * 10**18));
        assertEq(cINU.balanceOf(address(0xb0b)), 50_000_000_000 * 10**18);
    }

    function testReceiverExceedAmount() public {
        vm.deal(address(0xb0b),1000*10**18);
        vm.startPrank(address(0xb0b));

        payable(pound).call{gas: 100_000, value: 101*10**18}("");


        assertEq(address(0xb0b).balance, 1000*10**18);
        assertEq(address(pound).balance, 0);
        assertEq(cINU.balanceOf(address(0xb0b)), 0);
    }

    function testReceiverExceedTotal() public {

        unchecked{
            for(uint160 i = 0; i<1000; i++){
                vm.deal(address(i),1000*10**18);
                vm.startPrank(address(i));
                payable(pound).call{gas: 100_000, value: 100*10**18}("");
                assertEq(cINU.balanceOf(address(pound)), (931_000_000_000_000 * 10**18 - ((i+1) * 500_000_000_000 * 10**18)));
                vm.stopPrank();
            }
        }

        emit log_uint(cINU.balanceOf(address(pound)));

        vm.deal(address(0xb0b),1000*10**18);
        vm.startPrank(address(0xb0b));

        payable(pound).call{gas: 100_000, value: 100*10**18}("");

        assertEq(address(0xb0b).balance, 1_000*10**18);
        assertEq(address(pound).balance, 100_000*10**18);
        assertEq(cINU.balanceOf(address(0xb0b)), 0);
    }

}
