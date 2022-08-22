// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

import "solmate/auth/Owned.sol";

interface ICINU {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract DogCatcher is Owned(msg.sender){

    ICINU cInu;

    constructor(address _cInu){
        cInu = ICINU(_cInu);
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