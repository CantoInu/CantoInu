// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

import "solmate/tokens/ERC20.sol";

contract CantoInu is ERC20 {

    constructor()
    ERC20(
        "CANTO INU",
        "cINU",
        18
    ){
        _mint(msg.sender, 1_000_000_000_000_000 * 10**18);
    }

    function burn(uint256 value) public {
      _burn(msg.sender, value);
    }
}
