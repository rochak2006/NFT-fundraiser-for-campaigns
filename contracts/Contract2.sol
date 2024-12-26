// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTMarketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _listingIds;
    
    // Owner of the marketplace
    address payable public owner;
    
    // Listing fee for the marketplace
    uint256 public listingFee = 0.025 ether;
    
    struct Listing {
        uint256 listingId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }
    
    // Mapping listingId to Listing
    mapping(uint256 => Listing) private _listings;
    
    // Events
    event ListingCreated(
        uint256 indexed listingId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price
    );
    
    event ListingSold(
        uint256 indexed listingId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price
    );
    
    constructor() {
        owner = payable(msg.sender);
    }
    
    /**
     * @dev Updates the listing fee of the marketplace
     * @param _listingFee New listing fee
     */
    function updateListingFee(uint256 _listingFee) public payable {
        require(owner == msg.sender, "Only marketplace owner can update listing fee");
        listingFee = _listingFee;
    }
    
    /**
     * @dev Creates a new listing in the marketplace
     * @param nftContract Address of the NFT contract
     * @param tokenId Token ID of the NFT
     * @param price Price at which to list the NFT
     */
    function createListing(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price > 0, "Price must be greater than 0");
        require(msg.value == listingFee, "Must pay listing fee");
        
        _listingIds.increment();
        uint256 listingId = _listingIds.current();
        
        _listings[listingId] = Listing(
            listingId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );
        
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        
        emit ListingCreated(
            listingId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price
        );
    }
    
    /**
     * @dev Executes the sale of an NFT
     * @param listingId ID of the listing
     */
    function buyNFT(uint256 listingId) public payable nonReentrant {
        Listing storage listing = _listings[listingId];
        uint256 price = listing.price;
        uint256 tokenId = listing.tokenId;
        
        require(msg.value == price, "Must pay the asking price");
        require(!listing.sold, "Listing already sold");
        
        listing.seller.transfer(msg.value);
        IERC721(listing.nftContract).transferFrom(address(this), msg.sender, tokenId);
        listing.owner = payable(msg.sender);
        listing.sold = true;
        
        payable(owner).transfer(listingFee);
        
        emit ListingSold(
            listingId,
            listing.nftContract,
            tokenId,
            listing.seller,
            msg.sender,
            price
        );
    }
    
    /**
     * @dev Retrieves a listing by its ID
     * @param listingId ID of the listing
     */
    function getListing(uint256 listingId) public view returns (Listing memory) {
        return _listings[listingId];
    }
    
    /**
     * @dev Returns the current listing fee
     */
    function getListingFee() public view returns (uint256) {
        return listingFee;
    }
    
    /**
     * @dev Returns all unsold listings
     */
    function getUnsoldListings() public view returns (Listing[] memory) {
        uint256 totalListings = _listingIds.current();
        uint256 unsoldCount = 0;
        
        // Count unsold listings
        for (uint256 i = 1; i <= totalListings; i++) {
            if (!_listings[i].sold) {
                unsoldCount++;
            }
        }
        
        // Create array of unsold listings
        Listing[] memory unsoldListings = new Listing[](unsoldCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 1; i <= totalListings; i++) {
            if (!_listings[i].sold) {
                unsoldListings[currentIndex] = _listings[i];
                currentIndex++;
            }
        }
        
        return unsoldListings;
    }
    
    /**
     * @dev Returns listings created by a specific user
     * @param user Address of the user
     */
    function getMyListings(address user) public view returns (Listing[] memory) {
        uint256 totalListings = _listingIds.current();
        uint256 myListingCount = 0;
        
        // Count user's listings
        for (uint256 i = 1; i <= totalListings; i++) {
            if (_listings[i].seller == user) {
                myListingCount++;
            }
        }
        
        // Create array of user's listings
        Listing[] memory myListings = new Listing[](myListingCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 1; i <= totalListings; i++) {
            if (_listings[i].seller == user) {
                myListings[currentIndex] = _listings[i];
                currentIndex++;
            }
        }
        
        return myListings;
    }
}