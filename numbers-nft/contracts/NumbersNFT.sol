// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title NumbersNFT
/// @author Alberto Lalanda
/// @notice NFTs of images of numbers saved on IPFS
/// @notice Capped supply at 1 million. Contract inheriting from OpenZeppelin contracts.

contract NumbersNFT is ERC721, ERC721Royalty, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;
    mapping(string => bool) existingURIs;
    uint256 public totalSupplyCap;
    string public baseURI =
        "https://gateway.pinata.cloud/ipfs/QmUydfVzQEz1BvxouTsBCLB7Mp5aWXnbjNeUFzFfvFKW1c/";
    uint256 public price = 10 * 10**18;

    /*///////////////////////////////////////////////////////////////
                            IMMUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/

    IERC20 public immutable NUM_TOKEN;

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error MintLimit();

    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event NFTMinted(uint256 itemId, address buyer);
    event PriceUpdate(uint256 price);
    event supplyCapRaised(uint256 amount, uint256 newCap);

    constructor(
        uint256 _TOTAL_SUPPLY,
        address _numbersToken,
        address royaltyReceiver
    ) ERC721("NumbersNFT", "nNUM") {
        totalSupplyCap = _TOTAL_SUPPLY;
        NUM_TOKEN = IERC20(_numbersToken);
        _setDefaultRoyalty(royaltyReceiver, 500);
    }

    function safeMint(address to) external onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        string memory tokenIdString = tokenId.toString();
        _tokenIdCounter.increment();
        _setTokenURI(tokenId, tokenIdString);
        existingURIs[tokenIdString] = true;
        _safeMint(to, tokenId);
    }

    /// @param _price price in NumbersTokens without the decimals
    function updatePrice(uint256 _price) external onlyOwner {
        price = _price * 10**18;
        emit PriceUpdate(_price);
    }

    function increaseAvailableTotalSupply(uint256 amount) external onlyOwner {
        // overflow is unrealistic
        unchecked {
            totalSupplyCap += amount;
        }
        emit supplyCapRaised(amount, totalSupplyCap);
    }

    /*///////////////////////////////////////////////////////////////
                            WITHDRAWALS
    //////////////////////////////////////////////////////////////*/

    function withdrawNUM() external onlyOwner {
        uint256 balance = NUM_TOKEN.balanceOf(address(this));
        bool sent = NUM_TOKEN.transfer(msg.sender, balance);
        require(sent, "Token transfer failed");
    }

    /*
    struct Number {
        uint16 number;
        uint16 color;
        uint16 digits;
        uint16 rarity;
    }

    /// @dev Option to get seed to generate random values for the NFT attributes. Not a perfectly unpredictable random seed, for more security we could use Chainlink VRF  
    function enoughRandom() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        msg.sender,
                        blockhash(block.number - 1)
                    )
                )
            );
    }
    */

    function _mint(address to, uint256 tokenId) internal override(ERC721) {
        emit NFTMinted(tokenId, to);

        uint256 nftLength = tokenId; // Gives us the length of the NFT pool, without the newly minted token
        if (nftLength + 1 > totalSupplyCap) revert MintLimit();
        super._mint(to, tokenId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721Royalty, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function payToMint(address recipient) external returns (uint256) {
        uint256 newItemId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        string memory newItemIdString = newItemId.toString();
        existingURIs[newItemIdString] = true;

        bool sent = NUM_TOKEN.transferFrom(msg.sender, address(this), price);
        require(sent, "Token transfer failed");

        _mint(recipient, newItemId);
        _setTokenURI(newItemId, newItemIdString);

        return newItemId;
    }

    function isContentOwned(string memory uri) external view returns (bool) {
        return existingURIs[uri];
    }

    function count() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Royalty)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
