// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CantoInu.sol";
import "../src/NonFungibleDog.sol";
import "../src/PlaceHolderURI.sol";

import "./wCanto.sol";

import "Lending/Swap/BaseV1-core.sol";
import "Lending/Swap/BaseV1-periphery.sol";

contract ERC20Test is ERC20 {
    constructor(string memory name, string memory symbol, uint256 totalSup, uint8 decimals) ERC20(name, symbol, decimals) {}
    
    function mintTo(address to, uint256 totalSup) external {
        _mint(to, totalSup);
    }
}

contract NonFungibleDogTest is Test {
    BaseV1Factory public factory; 
    BaseV1Router01 public router; 
    CantoInu public cInu;
    NonFungibleDog public nft;
    placeHolderURI public uri;

    WCANTO public wCanto;
    ERC20Test public note;

    address public admin = address(1);
    address Bob = address(0xb0b);
    address Alice = address(0xa11ce);

    function setUp() public {

        
        vm.startPrank(admin);
        factory = new BaseV1Factory();
        wCanto = new WCANTO();
        note = new ERC20Test("note", "note", 10000*10**18, 18);

        router = new BaseV1Router01(address(factory), address(wCanto), address(note), admin);
        vm.stopPrank();

        vm.deal(Bob, 100*10**18);

        vm.startPrank(Bob);
        cInu = new CantoInu();
        uri = new placeHolderURI();
        nft = new NonFungibleDog();
        //nft = new NonFungibleDog(address(cInu), address(wCanto), address(uri));
        nft.setRouter(address(router));
        cInu.transfer(address(nft), 430_500_000_000_000 * 10**18);
        cInu.transfer(Alice, 500_000_000 * 10**18);
        vm.stopPrank();
    }

    function testMintAndBurn() public {
        vm.deal(Alice, 100*10**18);

        vm.startPrank(Alice);

        payable(nft).call{gas: 200_000, value: 10*10**18}("");

        assertEq(nft.balanceOf(Alice),1);
        assertEq(nft.ownerOf(0),Alice);

        uint256 burnt = 1_690_000_000 * 10*10**18;
        assertEq(cInu.totalSupply(), 1_000_000_000_000_000 * 10**18-burnt);
        assertEq(cInu.balanceOf(Alice), 500_000_000 * 10**18);
        assertEq(cInu.balanceOf(address(nft)), 430_500_000_000_000 * 10**18-burnt);

        vm.stopPrank();

    }

    function testMintAndMultipleBurn() public {
        vm.deal(Alice, 1000*10**18);

        vm.startPrank(Alice);

        payable(nft).call{gas: 200_000, value: 10*10**18}("");

        assertEq(nft.balanceOf(Alice),1);
        assertEq(nft.ownerOf(0),Alice);

        uint256 burnt = 1_690_000_000 * 10*10**18;
        assertEq(cInu.totalSupply(), 1_000_000_000_000_000 * 10**18-burnt);
        assertEq(cInu.balanceOf(Alice), 500_000_000 * 10**18);
        assertEq(cInu.balanceOf(address(nft)), 430_500_000_000_000 * 10**18-burnt);

        vm.roll(1000);

        payable(nft).call{gas: 200_000, value: 11*10**18}("");

        assertEq(nft.balanceOf(Alice),1);
        assertEq(nft.ownerOf(0),Alice);

        uint256 burnt2 = 1_690_000_000 * 21*10**18;
        assertEq(cInu.totalSupply(), 1_000_000_000_000_000 * 10**18-burnt2);
        assertEq(cInu.balanceOf(Alice), 500_000_000 * 10**18);

        assertEq(cInu.balanceOf(address(nft)), 430_500_000_000_000 * 10**18-burnt2);

        vm.stopPrank();

    }

    function testMintAndTrade() public {
        vm.deal(Alice, 1000*10**18);

        vm.startPrank(Alice);

        payable(nft).call{gas: 200_000, value: 10*10**18}("");

        assertEq(nft.balanceOf(Alice),1);
        assertEq(nft.ownerOf(0),Alice);

        uint256 burntAlice = 1_690_000_000 * 10*10**18;
        assertEq(cInu.totalSupply(), 1_000_000_000_000_000 * 10**18-burntAlice);
        assertEq(cInu.balanceOf(Alice), 500_000_000 * 10**18);
        assertEq(cInu.balanceOf(address(nft)), 430_500_000_000_000 * 10**18-burntAlice);

        vm.stopPrank();
        vm.roll(1000);

        address beef = address(0xbeef);
        vm.deal(beef, 1000*10**18);

        vm.startPrank(beef);

        payable(nft).call{gas: 200_000, value: 1*10**18}("");

        assertEq(nft.balanceOf(beef),1);
        assertEq(nft.ownerOf(1),beef);

        uint256 burntBeef = 1_690_000_000 * 1*10**18;
        assertEq(cInu.totalSupply(), 1_000_000_000_000_000 * 10**18-burntAlice-burntBeef);
        assertEq(cInu.balanceOf(address(nft)), 430_500_000_000_000 * 10**18-burntAlice-burntBeef);

        nft.transferFrom(beef, Alice, 1);

        vm.stopPrank();

        assertEq(nft.ownerOf(1),Alice);

        assertEq(nft.tokenOfOwnerByIndex(Alice, 0),0);
        assertEq(nft.tokenOfOwnerByIndex(Alice, 1),1);

    }

    function testRank() public {
        vm.deal(Alice, 1000*10**18);

        vm.startPrank(Alice);

        payable(nft).call{gas: 200_000, value: 10*10**18}("");

        assertEq(nft.balanceOf(Alice),1);
        assertEq(nft.ownerOf(0),Alice);

        uint256 burntAlice = 1_690_000_000 * 10*10**18;
        assertEq(cInu.totalSupply(), 1_000_000_000_000_000 * 10**18-burntAlice);
        assertEq(cInu.balanceOf(Alice), 500_000_000 * 10**18);
        assertEq(cInu.balanceOf(address(nft)), 430_500_000_000_000 * 10**18-burntAlice);

        vm.stopPrank();
        vm.roll(1000);

        address beef = address(0xbeef);
        vm.deal(beef, 1000*10**18);

        vm.startPrank(beef);

        payable(nft).call{gas: 200_000, value: 1*10**18}("");

        assertEq(nft.balanceOf(beef),1);
        assertEq(nft.ownerOf(1),beef);

        uint256 burntBeef = 1_690_000_000 * 1*10**18;
        assertEq(cInu.totalSupply(), 1_000_000_000_000_000 * 10**18-burntAlice-burntBeef);
        assertEq(cInu.balanceOf(address(nft)), 430_500_000_000_000 * 10**18-burntAlice-burntBeef);

        vm.roll(1100);

        payable(nft).call{gas: 200_000, value: 2*10**18}("");
        burntBeef = 1_690_000_000 * 3*10**18;

        vm.stopPrank();

        address fed = address(0xfed);
        vm.deal(fed, 1000*10**18);

        vm.roll(1150);

        vm.startPrank(fed);

        payable(nft).call{gas: 200_000, value: 20*10**18}("");

        vm.stopPrank();

        assertEq(nft.getRank(0),2);
        assertEq(nft.getRank(1),3);
        assertEq(nft.getRank(2),1);

        assertEq(nft.getTimesBurnt(0),1);
        assertEq(nft.getCInuBurnt(0),burntAlice);

        assertEq(nft.getTimesBurnt(1),2);
        assertEq(nft.getCInuBurnt(1),burntBeef);


    }

    function testUri() public {

        vm.deal(Alice, 1000*10**18);

        vm.startPrank(Alice);

        payable(nft).call{gas: 200_000, value: 10*10**18}("");

        assertEq(nft.tokenURI(0), "ipfs://QmSbjatwbq552s4ZUfX55tbDGyQRzG2nrvDtCK9fEyy24k");
    }

    function testTrade() public {

        vm.deal(Alice, 1000*10**18);

        vm.startPrank(Alice);

        payable(nft).call{gas: 200_000, value: 10*10**18}("");

        assertEq(nft.balanceOf(Alice),1);
        assertEq(nft.ownerOf(0),Alice);

        uint256 burntAlice = 1_690_000_000 * 10*10**18;
        assertEq(cInu.totalSupply(), 1_000_000_000_000_000 * 10**18-burntAlice);
        assertEq(cInu.balanceOf(Alice), 500_000_000 * 10**18);
        assertEq(cInu.balanceOf(address(nft)), 430_500_000_000_000 * 10**18-burntAlice);

        vm.stopPrank();
        vm.roll(10);

        vm.startPrank(Bob);

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

        vm.roll(20);

        uint balanceBefore = cInu.balanceOf(address(nft));

        (uint amount, bool stable) = router.getAmountOut(10*10**18, address(wCanto), address(cInu));

        uint minAmt = nft.estimateAmount(10*10**18);

        assertEq(minAmt, amount);

        nft.justMarketBuy(minAmt, 10*10**18);

        assertEq(wCanto.balanceOf(address(lpPairToken)), 61*10**18);
        assertEq(balanceBefore+minAmt, cInu.balanceOf(address(nft)));

        vm.stopPrank();

    }


}