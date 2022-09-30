// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC20.sol";

/* 

This contract is a wrapper for the Liquidity Position (LP) for CINU/wCANTO that allows LP to be unlocked for a fee that reduces over time, users earn DogBowl by staking cINU/WCANTO LP in Forteswap and their WOOF NFT 

When initialized the DogBowl stores the timestamp, and allows DogBowl token holders to extract LP (for which there is a tax that decreases over time, which is used to buy CINU that is sent to the NFT for burning later)
Initially the tax (cut) is set at 50% of the WCANTO amount, decreasing to 5% after 100 days.

*/

interface IRouter {

    function swapExactTokensForTokensSimple(
        uint amountIn,
        uint amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint deadline
    ) external returns (
        uint[] memory amounts
    );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (
        uint amountA, 
        uint amountB
    );

}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

}

contract DogBowl is ERC20, Owned(msg.sender) {

    IERC20  public lp;
    IRouter public router;

    uint256 public initTimeStamp;

    uint256 constant INITIAL_EXTRACTION_CUT         = 50; //50% of WETH | 25% of LP value
    address constant NON_FUNGIBLE_DOG       = 0xDE7Aa2B085bef0d752AA61058837827247Cc5253;
    address constant CINU                   = 0x7264610A66EcA758A8ce95CF11Ff5741E1fd0455;
    address constant WCANTO                 = 0x826551890Dc65655a0Aceca109aB11AbDbD7a07B;
    
    constructor(
        address _router, 
        address _lp
    ) ERC20("Dog Bowls", "BOWL", 18) {
        router  = IRouter(_router);
        lp      = IERC20(_lp);
    }   
    
    function extract(uint256 amt) public {
        require(balanceOf[msg.sender] >= amt, "insufficient user balance");

        // burn the users DogBowl amount
        _burn(msg.sender, amt);

        // withdraw LP
        (uint amountWCanto, uint amountCInu) = router.removeLiquidity(
            WCANTO,
            CINU,
            false,
            amt, 
            0,
            0,
            address(this),
            block.timestamp + 3600
        );

        // buy cINU with wCANTO from current cut percentage & send cINU to NFT to be burnt later
        uint wCantoCut = amountWCanto * getCurrentCut() / 100_000;
        router.swapExactTokensForTokensSimple(
            wCantoCut,
            0,
            WCANTO,
            CINU,
            false,
            NON_FUNGIBLE_DOG,
            block.timestamp + 3600
        );

        // send wCANTO and CINU to msg.sender
        IERC20(WCANTO).transfer(msg.sender, amountWCanto - wCantoCut);
        IERC20(CINU).transfer(msg.sender, amountCInu);

    }

    // we start at a 50% of WCANTO cut reducing to 5% by day 100
    function getCurrentCut() public view returns (uint256) {
        //check if 100 days has already passed, if so then just pass 5%
        if((block.timestamp - initTimeStamp) >= 86_400*100) {
            return 5000;
        } else {
            return 50000-(((block.timestamp - initTimeStamp)/86_400)*450);
        }
    }

    function depositLP(uint256 lpAmt) public onlyOwner {
        require(lp.transferFrom(msg.sender, address(this), lpAmt), "lp transfer failed");

        initTimeStamp = block.timestamp;

        // approve the lp and WETH for the router so we don't have to worry about it later
        lp.approve(address(router), lpAmt);
        IERC20(WCANTO).approve(address(router), IERC20(WCANTO).totalSupply());

        _mint(msg.sender, lpAmt);

    }

}


