// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

import "solmate/auth/Owned.sol";

contract placeHolderURI is Owned(msg.sender){

    string BaseUri = "ipfs://QmSbjatwbq552s4ZUfX55tbDGyQRzG2nrvDtCK9fEyy24k";

    constructor(){}

    function uri(uint256 id) external view returns (string memory) {
        return BaseUri;
    }

    function setUri(string memory _BaseUri) public onlyOwner{
        BaseUri = _BaseUri;
    }


}