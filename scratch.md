forge script script/dogUri.s.sol:DogUriScript --rpc-url $RPC_URL --broadcast --verify  --chain-id 7700 --verifier-url https://evm.explorer.canto.io/api --verifier blockscout -vvvv



forge verify-contract 0x5Ea2D88C9Cc8593DEBA1484b03B22f44bC42590A src/assets/defs.sol:DEFS --chain-id 7700 --verifier-url https://evm.explorer.canto.io/api --verifier blockscout

forge verify-contract 0x494E14191aFfE84cDF37877AC880B911da9A06C6 src/assets/dog.sol:DOG --chain-id 7700 --verifier-url https://evm.explorer.canto.io/api --verifier blockscout

forge verify-contract $CONTRACT src/dogURI.sol:dogURI  --constructor-args $(cast abi-encode "constructor(address,address,address,address)" 0x5Ea2D88C9Cc8593DEBA1484b03B22f44bC42590A 0x494E14191aFfE84cDF37877AC880B911da9A06C6 0xDE7Aa2B085bef0d752AA61058837827247Cc5253 0x81996BD9761467202c34141B63B3A7F50D387B6a)  --chain-id 7700 --verifier-url https://evm.explorer.canto.io/api --verifier blockscout --watch

0xface03c10ab2a8bb8df208f274a42d2d510d5baf


forge verify-check --chain-id 7700 --verifier-url https://evm.explorer.canto.io/api --verifier blockscout 9c1d857b587b4c1878507407484ee82e9d5e0e136373a1b8



cast call 0xface03c10ab2a8bb8df208f274a42d2d510d5baf --rpc-url $RPC_URL "uri(uint256)" 1



forge verify-contract 0x826551890Dc65655a0Aceca109aB11AbDbD7a07B test/wCanto.sol:WCANTO --constructor-args $(cast abi-encode "constructor(string,string)" "wCanto" "WCANTO") --chain-id 7700 --verifier-url https://evm.explorer.canto.io/api --verifier blockscout --watch
