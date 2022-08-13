# smart-contracts

Collection of smart contracts for the EVM. Each contract has been unit tested.

### NumbersCoin [Link](https://github.com/albertolalanda/smart-contracts/tree/master/numbers-token)

Token made to mint the NumbersNFT.  
ERC20. Contract inheriting from OpenZeppelin contracts.  
Capped supply at 1 million.

### NumbersNFT [Link](https://github.com/albertolalanda/smart-contracts/tree/master/numbers-nft)

NFTs of images of numbers hosted with IPFS.  
ERC721. Contract inheriting from OpenZeppelin contracts.  
Royalty enabled, as defined in the ERC2981 NFT Royalty Standard.  
NFT images were randomly pre-generated and hosted on IPFS before the mints. [Image generator used.](https://github.com/albertolalanda/nft-number-image-generator)  
In the future the image characteristics must be generated in the smart contract at the time of minting. For the random nonce we can use Chainlink VRF.

### NFT Marketplace [Link](https://github.com/albertolalanda/smart-contracts/tree/master/nft-marketplace)

NFT marketplace to buy/sell NumbersNFT with the NumbersToken  
The marketplace can be deployed with another NFT and token contract addresses.  
The marketplace takes a fee on the sale of the percentage defined by the owner.  
The contract implements ERC2981 and fowards the royalties to the NFT creator.  
If something goes wrong **Emergency Delisting** can be enabled, allowing anyone to take their NFTs on sale, out of the contract.

### Dex V2 [Link](https://github.com/albertolalanda/smart-contracts/tree/master/dex)

Descentralized exchange to host liquidity for the NumbersCoin.  
Fork of UniswapV2, adapted to build with Solidity compiler 0.8+

### Rock-Paper-Scissors [Link](https://github.com/albertolalanda/rock-paper-scissors)

Solidity smart contract of a rock, paper and scissors game.
