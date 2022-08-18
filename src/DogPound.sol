// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

import "solmate/auth/Owned.sol";
import "solmate/utils/ReentrancyGuard.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface IRouter {
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
    );
}

contract DogPound is Owned(msg.sender), ReentrancyGuard {

    uint256 constant RATE = 5_000_000_000; //
    uint256 constant MAX_CLAIM = 100 * 10**18; //maximum number of CANTO to be received

    uint256 public cINU_REMAINING;

    IERC20 public immutable cInu;
    IRouter public DEXRouter;
    
    mapping(address => uint256) public claims;

    constructor(address _cInu) {
        cInu = IERC20(_cInu);
        cINU_REMAINING = 500_000_000_000_000 * 10**18; //max amount of cINU that this contract that can be claimed
        DEXRouter = IRouter(0xa252eEE9BDe830Ca4793F054B506587027825a8e);
    }

    event LPAdded(uint amountToken, uint amountCANTO, uint liquidity);

    receive() external payable nonReentrant() {
        require(msg.value <= MAX_CLAIM, "SENT_TOO_MUCH"); // user cannot send more than 100 CANTO

        uint256 amt_to_release = msg.value * RATE; // calculate how much cINU is to be sent
        require(cINU_REMAINING >= amt_to_release, "INSUFFICIENT_CANTO_INU"); // make sure that there is enough cINU in this contract

        require((claims[msg.sender]+amt_to_release) <= RATE * MAX_CLAIM, "ALREADY_CLAIMED"); // make sure that the user has not already claimed more than 5bn cINU from this address

        unchecked{
            cINU_REMAINING = cINU_REMAINING - amt_to_release;
            claims[msg.sender] += amt_to_release; // increase the counter for the amount being released in this transaction
        }

        cInu.transfer(msg.sender, amt_to_release); // transfer the cINU to the caller's address
    }

    function setRouter(address _DEXRouter) public onlyOwner {
        DEXRouter = IRouter(_DEXRouter);
    }

    function fillLP() public onlyOwner {
        require(address(DEXRouter) != address(0), "ROUTER_UNSET");

        cInu.approve(address(DEXRouter), cInu.balanceOf(address(this)));

        (uint amountToken, uint amountCANTO, uint liquidity) = DEXRouter.addLiquidityCANTO{value: address(this).balance}(address(cInu), false, cInu.balanceOf(address(this)),cInu.balanceOf(address(this)), address(this).balance, address(this), block.timestamp+3600);

        emit LPAdded(amountToken, amountCANTO, liquidity);

    }

    function fillLP(uint256 cantoAmt, uint256 cInuAmt, uint256 cInuAmtMin) public onlyOwner {
        require(address(DEXRouter) != address(0), "ROUTER_UNSET");

        cInu.approve(address(DEXRouter), cInuAmt);

        (uint amountToken, uint amountCANTO, uint liquidity) = DEXRouter.addLiquidityCANTO{value: cantoAmt}(address(cInu), false, cInuAmt, cInuAmtMin, cantoAmt, address(this), block.timestamp+3600);

        emit LPAdded(amountToken, amountCANTO, liquidity);

    }

    // careful, this lets the owner of this contract transfer the LP token after depositing to the DEX to another wallet. This should be transfered to the Canto DAO or a burn wallet after filling LP
    function transferLP(address to, address lpTokenAddr) public onlyOwner {
        IERC20 lpToken = IERC20(lpTokenAddr);

        lpToken.transfer(to, lpToken.balanceOf(address(this)));
    }

}