// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/NonFungibleDog.sol";

// reads from the Canto mainnet to return a file with data from forked chain
// forge test --match-path test/NFT_leaderboard.t.sol --fork-url <RPC_URL>
contract NFT_leaderboardTest is Test {
    NonFungibleDog public nft = NonFungibleDog(payable(0xDE7Aa2B085bef0d752AA61058837827247Cc5253));

    string fileName = "./test/output/leaderBoard.txt";

    function setUp() public {
    }

    function testGrabBurnt() public {
        uint256 len = nft.totalSupply();

        for(uint i = 0; i<len; i++) {
            vm.writeLine(fileName, 
                string.concat(
                    "ID: ",
                    vm.toString(i), 
                    " - Burnt: ",
                    vm.toString(nft.getCInuBurnt(i))
                )
            );
        }
    }
 
}