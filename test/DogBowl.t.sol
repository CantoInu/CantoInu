// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/DogBowl.sol";
import "../src/CantoInu.sol";

// Test to be run on forking mode
//forge test --match-path test/DogBowl.t.sol --fork-url <RPC_URL> -vv
contract DogBowlTest is Test {

    DogBowl public bowl;

    address public deployer = 0xF0e4e74Ce34738826477b9280776fc797506fE13;
    address alice = address(0xa11ce);
    address bob = address(0xb0b);

    address router = 0x0e2374110f4Eba21f396FBf2d92cC469372f7DA0;
    address lp = 0x42A515C472b3B953beb8ab68aDD27f4bA3792451;

    CantoInu cinu;
    address WCANTO;
    address NFT;

    function setUp() public {
        vm.deal(alice, 1_000 ether);
        vm.deal(bob, 1_000 ether);

        vm.startPrank(deployer,deployer);

        bowl = new DogBowl(router,lp);
        cinu = CantoInu(bowl.CINU());

        cinu.approve(router, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        vm.stopPrank();

    }

    function testSetup() public  {

        vm.startPrank(deployer);

        emit log_address(deployer);
        emit log_uint(cinu.balanceOf(deployer));
        emit log_uint(IERC20(lp).balanceOf(deployer));

        vm.stopPrank();

    }


}

