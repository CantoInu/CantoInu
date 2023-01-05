// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

import "solmate/tokens/ERC721.sol";

contract AmpliceGhouls is ERC721 {

    uint256 nextId;

    constructor() ERC721("amplice GHOULS", "GHLS") {}

    function tokenURI(uint256 id)  public view override returns (string memory) {
        return "https://ghlsprod.s3.amazonaws.com/json/5589.json";
    }

    receive() external payable {
        require(nextId < 10000, "NO_MORE_AMPLICE_GHOULS_LEFT");

        _mint(msg.sender, nextId);
        nextId++;
    }


}