// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/// @title Market
/// @author Alberto Lalanda
/// @notice NFT marketplace NFT to buy/sell NumbersNFT with the NumbersToken
/// @notice The marketplace can be deployed with another NFT and token contracts
contract Market is IERC721Receiver, Ownable {
    address public immutable NUM_NFT;
    address public immutable NUM_TOKEN;

    struct Listing {
        uint256 activeIndexes; // uint128(activeListingIndex),uint128(userActiveListingIndex)
        uint256 tokenId;
        uint256 price;
        address owner;
    }

    mapping(uint256 => Listing) public listings;

    uint256[] public listingsArray; // list of listingIDs tokens being sold
    mapping(address => uint256[]) public userListings; // list of listingIDs which are active and belong to the user

    /*///////////////////////////////////////////////////////////////
                       MARKET MANAGEMENT SETTINGS
    //////////////////////////////////////////////////////////////*/
    uint256 public marketFeePercent;
    bool public isMarketOpen;
    bool public emergencyDelisting;

    /*///////////////////////////////////////////////////////////////
                        MARKET GLOBAL STATISTICS
    //////////////////////////////////////////////////////////////*/
    uint256 public totalVolume;
    uint256 public totalSales;
    uint256 public highestSalePrice;

    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    event AddListingEv(uint256 indexed tokenId, uint256 price, address seller);
    event UpdateListingEv(uint256 tokenId, uint256 price);
    event CancelListingEv(uint256 tokenId);
    event FulfillListingEv(uint256 tokenId, address buyer);

    /*///////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/
    error Percentage0to100();
    error ClosedMarket();
    error InvalidListing();
    error InactiveListing();
    error InvalidOwner();
    error NoActiveListings();
    error WrongIndex();
    error OnlyEmergency();
    error ZeroAddress();
    error NoFundsToWithdraw();

    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/
    constructor(
        address nft_address,
        uint256 market_fee,
        address token_address
    ) {
        if (nft_address == address(0x0)) revert ZeroAddress();
        if (token_address == address(0x0)) revert ZeroAddress();

        if (market_fee > 100) {
            revert Percentage0to100();
        }

        NUM_TOKEN = token_address;
        NUM_NFT = nft_address;

        marketFeePercent = market_fee;
    }

    /*///////////////////////////////////////////////////////////////
                      MARKET MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/
    function openMarket() external onlyOwner {
        if (emergencyDelisting) {
            emergencyDelisting = false;
        }
        isMarketOpen = true;
    }

    function closeMarket() external onlyOwner {
        isMarketOpen = false;
    }

    function allowEmergencyDelisting() external onlyOwner {
        emergencyDelisting = true;
    }

    function adjustFees(uint256 newMarketFee) external onlyOwner {
        if (newMarketFee > 100) {
            revert Percentage0to100();
        }

        marketFeePercent = newMarketFee;
    }

    // If something goes wrong, we can close the market and enable emergencyDelisting
    //    After that, anyone can delist active listings
    function emergencyDelist(uint256[] calldata listingIDs) external {
        if (!(emergencyDelisting && !isMarketOpen)) revert OnlyEmergency();

        uint256 len = listingIDs.length;
        for (uint256 i; i < len; ++i) {
            uint256 id = listingIDs[i];
            Listing memory listing = listings[id];
            removeListing(listing.activeIndexes >> (8 * 16));
            removeUserListing(
                listing.owner,
                uint256(uint128(listing.activeIndexes))
            );

            //listings[id].active = false;
            IERC721(NUM_NFT).transferFrom(
                address(this),
                listing.owner,
                listing.tokenId
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                            WITHDRAWALS
    //////////////////////////////////////////////////////////////*/
    function withdrawNUM() external onlyOwner {
        uint256 balance = IERC20(NUM_TOKEN).balanceOf(address(this));
        if (balance <= 0) {
            revert NoFundsToWithdraw();
        }
        bool sent = IERC20(NUM_TOKEN).transfer(msg.sender, balance);
        require(sent, "Token transfer failed");
    }

    /*///////////////////////////////////////////////////////////////
                        LISTINGS READ OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function totalListings() public view returns (uint256) {
        return listingsArray.length;
    }

    function getListing(uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return listings[tokenId];
    }

    function getAllListings() external view returns (Listing[] memory listing) {
        return getListings(0, listingsArray.length);
    }

    function getListings(uint256 from, uint256 length)
        public
        view
        returns (Listing[] memory listing)
    {
        unchecked {
            uint256 listingsLength = listingsArray.length;
            if (from + length > listingsLength) {
                length = listingsLength - from;
            }

            Listing[] memory _listings = new Listing[](length);
            for (uint256 i; i < length; ++i) {
                _listings[i] = listings[listingsArray[from + i]];
            }
            return _listings;
        }
    }

    function getMyListingsCount() external view returns (uint256) {
        return userListings[msg.sender].length;
    }

    function getAllMyListings()
        external
        view
        returns (Listing[] memory listing)
    {
        return getMyListings(0, userListings[msg.sender].length);
    }

    function getMyListings(uint256 from, uint256 length)
        public
        view
        returns (Listing[] memory listing)
    {
        unchecked {
            uint256 myListingsLength = userListings[msg.sender].length;

            if (from + length > myListingsLength) {
                length = myListingsLength - from;
            }

            Listing[] memory myListings = new Listing[](length);
            for (uint256 i; i < length; ++i) {
                myListings[i] = listings[userListings[msg.sender][i + from]];
            }
            return myListings;
        }
    }

    /*///////////////////////////////////////////////////////////////
                    LISTINGS STORAGE MANIPULATION
    //////////////////////////////////////////////////////////////*/

    /// Moves the last element to the one to be removed
    function removeListing(uint256 index) internal {
        uint256 numActive = listingsArray.length;

        if (numActive == 0) revert NoActiveListings();
        if (index >= numActive) revert WrongIndex();

        // cannot underflow
        unchecked {
            uint256 listingID = listingsArray[numActive - 1];

            listingsArray[index] = listingID;

            listings[listingID].activeIndexes =
                uint256(index << (8 * 16)) |
                uint128(listings[listingID].activeIndexes);
        }
        listingsArray.pop();
    }

    /// Moves the last element to the one to be removed
    function removeUserListing(address user, uint256 index) internal {
        uint256 numActive = userListings[user].length;

        if (numActive == 0) revert NoActiveListings();
        if (index >= numActive) revert WrongIndex();

        // cannot underflow
        unchecked {
            uint256 listingID = userListings[user][numActive - 1];

            userListings[user][index] = listingID;

            listings[listingID].activeIndexes =
                (listings[listingID].activeIndexes &
                    (type(uint256).max << (8 * 16))) |
                uint128(index);
        }
        userListings[user].pop();
    }

    /*///////////////////////////////////////////////////////////////
                        LISTINGS WRITE OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function addListing(uint256 _tokenId, uint256 _price) external {
        if (!isMarketOpen) revert ClosedMarket();

        uint256[] storage _senderActiveListings = userListings[msg.sender];

        listings[_tokenId] = Listing(
            (listingsArray.length << (8 * 16)) |
                uint128(_senderActiveListings.length),
            _tokenId,
            _price,
            msg.sender
        );

        _senderActiveListings.push(_tokenId);
        listingsArray.push(_tokenId);

        emit AddListingEv(_tokenId, _price, msg.sender);
        IERC721(NUM_NFT).transferFrom(msg.sender, address(this), _tokenId);
    }

    function updateListing(uint256 tokenId, uint256 price) external {
        if (!isMarketOpen) revert ClosedMarket();

        Listing storage listing = listings[tokenId];
        if (listing.owner == address(0)) revert InvalidListing();
        if (listing.owner != msg.sender) revert InvalidOwner();

        listing.price = price;
        emit UpdateListingEv(tokenId, price);
    }

    function cancelListing(uint256 tokenId) external {
        Listing memory listing = listings[tokenId];

        if (listing.owner == address(0)) revert InvalidListing();
        if (listing.owner != msg.sender) revert InvalidOwner();

        removeListing(listing.activeIndexes >> (8 * 16));
        removeUserListing(msg.sender, uint256(uint128(listing.activeIndexes)));

        delete listings[tokenId];

        emit CancelListingEv(tokenId);

        IERC721(NUM_NFT).transferFrom(
            address(this),
            listing.owner,
            listing.tokenId
        );
    }

    function fulfillListing(uint256 tokenId) external {
        if (!isMarketOpen) revert ClosedMarket();

        Listing memory listing = listings[tokenId];
        if (listing.owner == address(0)) revert InvalidListing();

        delete listings[tokenId];

        if (msg.sender == listing.owner) revert InvalidOwner();

        (address royaltyReceiver, uint256 royaltyAmount) = IERC2981(NUM_NFT)
            .royaltyInfo(listing.tokenId, listing.price);

        // Update active listings
        removeListing(listing.activeIndexes >> (8 * 16));
        removeUserListing(
            listing.owner,
            uint256(uint128(listing.activeIndexes))
        );

        // Update global stats
        unchecked {
            totalVolume += listing.price;
            totalSales += 1;
        }

        if (listing.price > highestSalePrice) {
            highestSalePrice = listing.price;
        }

        uint256 marketFee = (listing.price * marketFeePercent) / 100;

        _safeTransferFrom(
            IERC20(NUM_TOKEN),
            msg.sender,
            listing.owner,
            listing.price - royaltyAmount - marketFee
        );

        _safeTransferFrom(
            IERC20(NUM_TOKEN),
            msg.sender,
            royaltyReceiver,
            royaltyAmount
        );

        _safeTransferFrom(
            IERC20(NUM_TOKEN),
            msg.sender,
            address(this),
            marketFee
        );

        emit FulfillListingEv(tokenId, msg.sender);

        IERC721(NUM_NFT).transferFrom(
            address(this),
            msg.sender,
            listing.tokenId
        );
    }

    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }

    function onERC721Received(
        address, //_operator,
        address, //_from,
        uint256, //_id,
        bytes calldata //_data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
