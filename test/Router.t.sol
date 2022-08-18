// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CantoInu.sol";
import "../src/DogPound.sol";

import "./wCanto.sol";

import "Lending/Swap/BaseV1-core.sol";
import "Lending/Swap/BaseV1-periphery.sol";

contract ERC20Test is ERC20 {
    constructor(string memory name, string memory symbol, uint256 totalSup, uint8 decimals) ERC20(name, symbol, decimals) {}
    
    function mintTo(address to, uint256 totalSup) external {
        _mint(to, totalSup);
    }
}

contract RouterTest is Test {
    BaseV1Factory public factory; 
    BaseV1Router01 public router; 
    CantoInu public cInu;
    DogPound public pound;

    WCANTO public wCanto;
    ERC20Test public note;

    address public admin = address(1);
    address Bob = address(0xb0b);

    function setUp() public {
        vm.startPrank(admin);
        factory = new BaseV1Factory();
        wCanto = new WCANTO();
        note = new ERC20Test("note", "note", 10000*10**18, 18);

        router = new BaseV1Router01(address(factory), address(wCanto), address(note), admin);
        vm.stopPrank();

        vm.startPrank(Bob);
        cInu = new CantoInu();
        pound = new DogPound(address(cInu));
        pound.setRouter(address(router));
        cInu.transfer(address(pound), 931_000_000_000_000 * 10**18);
        vm.stopPrank();
    }

    function testAddLiquidityCanto() public {
        vm.deal(Bob, 100*10**18);

        vm.startPrank(Bob);

        emit log_uint(cInu.balanceOf(Bob));

        IBaseV1Pair lpPairToken = IBaseV1Pair(router.pairFor(address(cInu), address(wCanto), false));

        cInu.approve(address(router), 1_000_000_000 * 10**18);
        
        router.addLiquidityCANTO{value: 51*10**18}(
            address(cInu),
            false,
            100_000_000 * 10**18,
            100_000_000 * 10**18,
            50 * 10**18,
            Bob,
            block.timestamp + 3600
        );

        vm.stopPrank();

        emit log_uint(lpPairToken.balanceOf(Bob));
    }

    function testMintOutAndAddLiquidity() public {
        unchecked{
            for(uint160 i = 0; i<1000; i++){
                vm.deal(address(i),1000*10**18);
                vm.startPrank(address(i));
                payable(pound).call{gas: 100_000, value: 100*10**18}("");
                assertEq(cInu.balanceOf(address(pound)), (931_000_000_000_000 * 10**18 - ((i+1) * 500_000_000_000 * 10**18)));
                vm.stopPrank();
            }
        }

        IBaseV1Pair lpPairToken = IBaseV1Pair(router.pairFor(address(cInu), address(wCanto), false));

        vm.startPrank(Bob);
        
            pound.fillLP();
            assertEq(address(pound).balance, 0);
            assertEq(cInu.balanceOf(address(pound)), 0);
            emit log_uint(lpPairToken.balanceOf(address(pound)));

        vm.stopPrank();

    }


}