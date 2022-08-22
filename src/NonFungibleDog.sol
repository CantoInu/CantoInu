// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

import "solmate/auth/Owned.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/*
///////////////Very wow, so free public infrastructure!!!!!///////////////

⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡟⠋⠈⠙⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠤⢤⡀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠈⢇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠞⠀⠀⢠⡜⣦⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡃⠀⠀⠀⠀⠈⢷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠊⣠⠀⠀⠀⠀⢻⡘⡇
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠃⠀⠀⠀⠀⠀⠀⠙⢶⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡠⠚⢀⡼⠃⠀⠀⠀⠀⠸⣇⢳
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⠀⣀⠖⠀⠀⠀⠀⠉⠀⠀⠈⠉⠛⠛⡛⢛⠛⢳⡶⠖⠋⠀⢠⡞⠀⠀⠀⠐⠆⠀⠀⣿⢸
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⣦⣀⣴⡟⠀⠀⢶⣶⣾⡿⠀⠀⣿⢸
⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⠞⠁⠀⠀⠀⠀⠀⠀⠀⠀⡠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣏⠀⠀⠀⣶⣿⣿⡇⠀⠀⢏⡞
⠀⠀⠀⠀⠀⠀⢀⡴⠛⠀⠀⠀⠀⠀⠀⠀⠀⢀⢀⡾⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢦⣤⣾⣿⣿⠋⠀⠀⡀⣾⠁
⠀⠀⠀⠀⠀⣠⠟⠁⠀⠀⠀⣀⠀⠀⠀⠀⢀⡟⠈⢀⣤⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⣏⡁⠀⠐⠚⠃⣿⠀
⠀⠀⠀⠀⣴⠋⠀⠀⠀⡴⣿⣿⡟⣷⠀⠀⠊⠀⠴⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠀⠀⠀⠀⢹⡆
⠀⠀⠀⣴⠃⠀⠀⠀⠀⣇⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⡶⢶⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇
⠀⠀⣸⠃⠀⠀⠀⢠⠀⠊⠛⠉⠁⠀⠀⠀⠀⠀⠀⠀⢲⣾⣿⡏⣾⣿⣿⣿⣿⠖⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢧
⠀⢠⡇⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠈⠛⠿⣽⣿⡿⠏⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡜
⢀⡿⠀⠀⠀⠀⢀⣤⣶⣟⣶⣦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇
⢸⠇⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇
⣼⠀⢀⡀⠀⠀⢷⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡇
⡇⠀⠈⠀⠀⠀⣬⠻⣿⣿⣿⡿⠙⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠁
⢹⡀⠀⠀⠀⠈⣿⣶⣿⣿⣝⡛⢳⠭⠍⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠃⠀
⠸⡇⠀⠀⠀⠀⠙⣿⣿⣿⣿⣿⣿⣷⣦⣀⣀⣀⣤⣤⣴⡶⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⠇⠀⠀
⠀⢿⡄⠀⠀⠀⠀⠀⠙⣇⠉⠉⠙⠛⠻⠟⠛⠛⠉⠙⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡰⠋⠀⠀⠀
⠀⠈⢧⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠞⠁⠀⠀⠀⠀
⠀⠀⠘⢷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠞⠁⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠱⢆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⡴⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠛⢦⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⠴⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠲⠤⣤⣤⣤⣄⠀⠀⠀⠀⠀⠀⠀⢠⣤⣤⠤⠴⠒⠛⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀                                                                                                                                                                               

 CantoInu is purely for entertaining, there is no roadmap, there are no promises, it's not worth anything, you will lose all of your monies!

*/

interface ICINU {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function burn(uint256 value) external;
}

interface IRouter {

    struct route {
        address from;
        address to;
        bool stable;
    }

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable);

    function swapExactCANTOForTokens(uint amountOutMin, route[] calldata routes, address to, uint deadline) external payable returns (uint[] memory amounts);
}

interface IUri {
    function uri(uint256 id) external view returns (string memory);
}

contract NonFungibleDog is ERC721Enumerable, Owned(msg.sender) {

    ICINU cInu;
    IRouter router = IRouter(0xa252eEE9BDe830Ca4793F054B506587027825a8e);
    IUri uriReader;

    address wCANTO; // = 0x826551890Dc65655a0Aceca109aB11AbDbD7a07B;

    uint256 BURN_RATE = 1_690_000_000;

    struct NFTData {
        uint256 timesBurnt;
        uint256 cInuBurnt;
    }

    NFTData[] public nftData;

    constructor(
        address _cInu,
        address _wCanto,
        address _uriReader
    ) 
    ERC721("NON FUNGIBLE DOG", "WOOF") 
    {
        cInu = ICINU(_cInu);
        wCANTO = _wCanto;
        uriReader = IUri(_uriReader);
    }

    receive() external payable {
        uint256 _tokenId;
        uint256 _amtToBurn = msg.value * BURN_RATE;

        cInu.burn(_amtToBurn);

        //check if minted NFT and grab first id in index, if no NFT mint
        if(balanceOf(msg.sender) == 0){
            _tokenId = totalSupply();
            _mint(msg.sender, _tokenId);
            nftData.push(
                NFTData({
                    timesBurnt: 1,
                    cInuBurnt: _amtToBurn
                })
            );
        } else {
            _tokenId = tokenOfOwnerByIndex(msg.sender, 0);
            nftData[_tokenId] =
                NFTData({
                    timesBurnt: nftData[_tokenId].timesBurnt += 1,
                    cInuBurnt:  nftData[_tokenId].cInuBurnt += _amtToBurn
                });
        }     

    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        return uriReader.uri(tokenId);
    }

    function _quickSort(uint[2][] memory arr, int left, int right) internal pure {
        unchecked{
            int i = left;
            int j = right;
            if (i == j) return;
            uint pivot = arr[uint(left + (right - left) / 2)][1];
            while (i <= j) {
                while (arr[uint(i)][1] > pivot) i++;
                while (pivot > arr[uint(j)][1]) j--;
                if (i <= j) {
                    (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                    i++;
                    j--;
                }
            }
            if (left < j)
                _quickSort(arr, left, j);
            if (i < right)
                _quickSort(arr, i, right);
        }
    }

    function getCInuBurnt(uint256 tokenId) public view returns (uint256) {
        return nftData[tokenId].cInuBurnt;
    }

    function getTimesBurnt(uint256 tokenId) public view returns (uint256) {
        return nftData[tokenId].timesBurnt;
    }

    event here(uint256 i);

    function getRank(uint256 tokenId) public view returns (uint256) {
        unchecked{
            uint256 totalIds = totalSupply();

            uint[2][] memory sortingArr = new uint[2][](totalIds);

            

            for(uint i = 0; i<totalIds; i++){
                sortingArr[i][0] = i;
                sortingArr[i][1] = nftData[i].cInuBurnt;
            } 


            _quickSort(sortingArr, 0, int256(totalIds-1));

            uint j;
            while(sortingArr[j][0] != tokenId){
                j++;
            }
            return j+1;
        }
    }

    function estimateAmount(uint256 cantoSpent) public view returns (uint256) {
        (uint cInuOut,) = router.getAmountOut(cantoSpent, wCANTO, address(cInu));
        return cInuOut;
    }

    function justMarketBuy(uint256 cInuMin, uint256 cantoSpent) public onlyOwner returns (uint[] memory amounts) {
        
        IRouter.route[] memory _routes = new IRouter.route[](1);
        _routes[0] = IRouter.route(wCANTO, address(cInu), false);

        (amounts) = router.swapExactCANTOForTokens{value: cantoSpent}(cInuMin, _routes, address(this), block.timestamp+3600);

    }

    function setRouter(address _router) public onlyOwner {
        router = IRouter(_router);
    }

    function setUriReader(address _uriReader) public onlyOwner {
        uriReader = IUri(_uriReader);
    }

    function setBurnRate(uint256 _burnRate) public onlyOwner {
        BURN_RATE = _burnRate;
    }

}