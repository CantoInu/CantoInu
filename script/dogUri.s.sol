// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/assets/defs.sol";
import "src/assets/dog.sol";
import "src/dogURI.sol";

contract DogUriScript is Script {

    DEFS public Defs;
    DOG public Dog;
    dogURI public Uri;


    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        //Defs = new DEFS();
        //Dog = new DOG();
        Defs = DEFS(0x5Ea2D88C9Cc8593DEBA1484b03B22f44bC42590A);
        Dog = DOG(0x494E14191aFfE84cDF37877AC880B911da9A06C6);

        Uri = new dogURI(address(Defs), address(Dog), 0xDE7Aa2B085bef0d752AA61058837827247Cc5253, 0x81996BD9761467202c34141B63B3A7F50D387B6a);

        vm.stopBroadcast();
    }
}

