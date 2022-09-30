// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

import "solmate/auth/Owned.sol";

/* 
// DogMaster is the master of DogBowls. He can serve Dogs their bowls and he is a fair guy.
//
// Note that it's ownable and that ownership powers have been stripped to their minimal state.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
*/

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface INonFungibleDog {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);

    // We rely on safeTransferFrom but give the user the ability to use unsafe reclaim
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    
    function getCInuBurnt(uint256 tokenId) external view returns (uint256);

}

// @dev this contract should never receive token ID 0 as it will create an issue with the UserInfo of users who have not transferred in

contract DogMaster is Owned(msg.sender) {

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 id; // link NFT ID to user
        //
        // We do some fancy math here. Basically, any point in time, the amount of DogBowls
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * accBowlsPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The `accBowlsPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // The DOGBOWL TOKEN!
    IERC20 public bowl;
    // Bowl tokens paid per block.
    uint256 public bowlsPerBlock;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;
    // The CINU/WCANTO lpToken
    IERC20 public lpToken;
    // The NonFungibleDog NFT, to expose the bonus
    INonFungibleDog public nft;
    // Weighted LP deposit, LP amount * NFT bonus.
    uint256 public weightedLPSupply;
    // Accumulated BOWLs per share, times 1e12. See below.
    uint256 public accBowlsPerShare; 
    // The block number when BOWLS mining starts.
    uint256 public startBlock;
    uint256 public lastRewardBlock; // Last block number that BOWLs distribution occurs.
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 amount
    );

    constructor(
        address _bowl,
        address _lpToken,
        address _nft,
        uint256 _bowlsPerBlock,
        uint256 _startBlock
    ) {
        bowl = IERC20(_bowl);
        lpToken = IERC20(_lpToken);
        nft = INonFungibleDog(_nft);
        bowlsPerBlock = _bowlsPerBlock;
        startBlock = _startBlock;
    }

    // Return reward multiplier over the given _from to _to block.  There is no multiplier but this was left to keep similiarity to base contract.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256) {
            
        return _to - _from;
    }

    // we determine the bonus to apply to the amount of LP staked
    function getNFTBonus(uint256 id)
        public
        view
        returns (uint256) {

        uint256 burntCinu = nft.getCInuBurnt(id);

        if(burntCinu >= 16_900_000_000_000 * 10**18) {
            return 10;
        } else if(burntCinu >= 169_000_000_000 * 10**18) {
            return 5;
        } else if(burntCinu >= 1_690_000_000 * 10**18) {
            return 1;
        } else {
            return 0;
        }

    }

    // View function to see pending BOWLs on frontend.
    function pendingBowls(address _user)
        external
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_user];
        uint256 _accBowlsPerShare;
        if (block.number > lastRewardBlock && weightedLPSupply != 0) {
            uint256 _multiplier = getMultiplier(lastRewardBlock, block.number);
            _accBowlsPerShare = accBowlsPerShare + (_multiplier*(bowlsPerBlock * 1e12 / weightedLPSupply));
        }
        return user.amount * (_accBowlsPerShare / 1e12 - user.rewardDebt);
    }

    // Update reward variables to be up-to-date.
    function updateReward() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (weightedLPSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 _multiplier = getMultiplier(lastRewardBlock, block.number);
        accBowlsPerShare += (_multiplier*(bowlsPerBlock * 1e12 / weightedLPSupply));
        lastRewardBlock = block.number;
    }

    // Deposit LP tokens & nft to DogMaster for BOWL allocation.
    function deposit(uint256 _amount, uint256 _id) public {
        UserInfo storage user = userInfo[msg.sender];
        require(_id != 0, "Invalid NFT ID");
        require(nft.ownerOf(_id) == msg.sender || user.id == _id, "Invalid NFT Owner");
        require(nft.getCInuBurnt(_id) >= 1_690_000_000 * 10**18, "Insufficient CINU burn");

        updateReward();
        if (user.amount > 0) {
            uint256 pending = (user.amount * getNFTBonus(user.id)) * accBowlsPerShare / 1e12 - user.rewardDebt;
            bowl.transfer(msg.sender, pending);
        }

        // we checked that the user was the owner of this NFT at the top, if the NFT isn't in DogMaster we do the transfer
        if(user.id == 0) {
            // no need to do a safe transfer as it's coming here
            nft.transferFrom(msg.sender, address(this), _id);
            user.id = _id;
        }

        lpToken.transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount += _amount;
        weightedLPSupply += (_amount * getNFTBonus(user.id));
        user.rewardDebt = (user.amount * getNFTBonus(user.id)) * accBowlsPerShare / 1e12;
        emit Deposit(msg.sender, _amount);
    }

    // Deposit more LP tokens DogMaster for BOWL allocation, must have NFT deposited
    function deposit(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.id != 0, "No NFT deposited");

        updateReward();
        if (user.amount > 0) {
            uint256 pending = (user.amount * getNFTBonus(user.id)) * accBowlsPerShare / 1e12 - user.rewardDebt;
            bowl.transfer(msg.sender, pending);
        }

        lpToken.transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount += _amount;
        weightedLPSupply += (_amount * getNFTBonus(user.id));
        user.rewardDebt = (user.amount * getNFTBonus(user.id)) * accBowlsPerShare / 1e12;
        emit Deposit(msg.sender, _amount);
    }

    // Claim BOWL rewards
    function claim() public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.id != 0, "No NFT deposited");

        updateReward();
        if (user.amount > 0) {
            uint256 pending = (user.amount * getNFTBonus(user.id)) * accBowlsPerShare / 1e12 - user.rewardDebt;
            bowl.transfer(msg.sender, pending);
        }

        user.rewardDebt = (user.amount * getNFTBonus(user.id)) * accBowlsPerShare / 1e12;
        emit Deposit(msg.sender, 0);
    }

    // Withdraw LP tokens & nft from DogMaster.
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updateReward();
        uint256 pending = (user.amount * getNFTBonus(user.id)) * accBowlsPerShare /  1e12 - user.rewardDebt;
        bowl.transfer(msg.sender, pending);

        user.amount += _amount;
        weightedLPSupply -= (_amount * getNFTBonus(user.id));
        user.rewardDebt = (user.amount * getNFTBonus(user.id)) * accBowlsPerShare / 1e12;
        
        // we do a safe transfer as we don't know where it's going
        nft.safeTransferFrom(address(this), msg.sender, user.id);
        user.id = 0;

        lpToken.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];
        lpToken.transfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        // this is an emergency, if the NFT id fell out we don't care just pull the LP
        if(user.id != 0){
            // we do not do a safe transfer as this is an emergency
            nft.transferFrom(address(this), msg.sender, user.id);
            user.id = 0;
        }
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // We make sure to update userInfo in the event that we receive an errant transfer
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        require(msg.sender == address(nft), "Invalid NFT");
        require(userInfo[from].id == 0, "User has NFT deposited");

        userInfo[from].id = tokenId;

        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

}