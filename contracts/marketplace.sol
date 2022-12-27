// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Marketplace {

    //Providing id's to nfts to keep their track
    uint private _items;
   

    address public owner;//Marketplace owner address

   //enum for type of auction
    enum Auction {
        FIXEDPRICE,
        DUTCH,
        ENGLISH
    }


    // structure to marketplace item
    struct MarketplaceItem {
        uint itemId;
        address nftContract;
        uint tokenId;
        address payable seller;
        address payable buyer;
        uint price;
        Auction auctiontype;
        bool sold;
        uint duration; 
        uint minPrice;//for dutchbid

    }
    
    mapping(uint => MarketplaceItem) private idToMarketplaceItem;//mapping for marketplace item with itemid

    //Structure for english auction
    struct englishAuctionstr{
      uint englishEndAt;
      bool englishStarted;
      bool englishEnded;
      uint highestBid;
      address   highestBidder;
    }

    mapping (uint=>englishAuctionstr) private idToEnglishAuction;//mapping for english auction items  with itemid
    mapping(uint=>mapping(address => uint)) public bids;//mapping to keep track of bids

    //Structure for dutch auction
    struct DutchAuctionstr {
      uint   dutchStartingPrice;
      uint   dutchStartAt;
      uint   dutchExpiresAt;
      uint   dutchDiscountRate;
    }

    mapping (uint=>DutchAuctionstr) private idToDutchAuction;//mapping for dutch auction items  with itemid

    //Structure for pending returns in english bids
    struct PendingReturn{
      address[] previousBidder;
      uint[] previousBid;
   }

  mapping(uint=>PendingReturn) private PendingReturns;//mapping for pendingreturns structure with itemid
    

    // declare a event for when a item is created on marketplace
    event MarketplaceItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 price,
        bool sold
    );

    constructor() {
        owner = msg.sender;
    }

    
    modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

    

    // places an item for sale on fixed price in marketplace
    function fixedPricesale(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public {

        require(price > 0, "Price must be at least 1 wei");

        require(msg.sender==IERC721(nftContract).ownerOf(tokenId),"You are not the owner of this nft");

        _items++;
        uint itemId = _items;

        idToMarketplaceItem[itemId] = MarketplaceItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            Auction.FIXEDPRICE,
            false,
            0,0
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketplaceItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    //function to buy nft on fixedprice basic
    function fixedPricebuy( uint256 itemId)
        public
        payable

    {
    
        require( itemId > 0  && itemId <= _items ,"item doesn't exist");

         require(idToMarketplaceItem[itemId].auctiontype==Auction.FIXEDPRICE,"INVALID BUY OPTION");

        uint price = idToMarketplaceItem[itemId].price;
        uint tokenId = idToMarketplaceItem[itemId].tokenId;
        address nftContract = idToMarketplaceItem[itemId].nftContract;

        require(
            msg.value >= price,
            "Please submit the asking price in order to complete the purchase"
        );

        idToMarketplaceItem[itemId].seller.transfer(msg.value);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketplaceItem[itemId].buyer = payable(msg.sender);
        idToMarketplaceItem[itemId].sold = true;


    }

    //ENGLISH AUCTION SYSTEM

     //function to put nft on english auction for sale
     function englishStart(address nftContract, uint tokenId,uint duration,uint price) external {

         require(msg.sender==IERC721(nftContract).ownerOf(tokenId),"You are not the owner of this nft");
         require(price > 0, "Price must be at least 1 wei");

        _items++;

        uint itemId = _items;

        idToMarketplaceItem[itemId] = MarketplaceItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            Auction.ENGLISH,
            false,
            duration,0
        );

       

        require(!idToEnglishAuction[itemId].englishStarted, "started");
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        idToEnglishAuction[itemId].englishStarted = true;
        idToEnglishAuction[itemId].englishEndAt = block.timestamp + duration;
        idToEnglishAuction[itemId].highestBid = price;

        emit MarketplaceItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );

    }


    //function to place bid
    function englishBid(uint itemId) external payable{

        require( itemId > 0  && itemId <= _items ,"item doesn't exist");
        require(idToEnglishAuction[itemId].englishStarted, "not started");
        require(idToMarketplaceItem[itemId].auctiontype==Auction.ENGLISH,"INVALID BUY OPTION");
        require(block.timestamp < idToEnglishAuction[itemId].englishEndAt, "ended");
        require(msg.value > idToEnglishAuction[itemId].highestBid, "value > highest");

        if (idToEnglishAuction[itemId].highestBidder != address(0)) {
            
           PendingReturns[itemId].previousBidder.push(
            idToEnglishAuction[itemId].highestBidder
            );

            PendingReturns[itemId].previousBid.push(
               idToEnglishAuction[itemId].highestBid
            );
        }
       

        idToEnglishAuction[itemId].highestBidder = msg.sender;
        idToEnglishAuction[itemId].highestBid = msg.value;
        bids[itemId][msg.sender]=msg.value;
        
    }
    
    
    function getHighestBid(uint itemId) public view returns (uint){
        return idToEnglishAuction[itemId].highestBid;
    } 

   
    //function to end bid and transfer nft and amount to seller
    function englishEnd( uint itemId) external payable onlyOwner {

        
        require( itemId > 0  && itemId <= _items ,"item doesn't exist");
        require(idToEnglishAuction[itemId].englishStarted, "not started");
        require(block.timestamp >= idToEnglishAuction[itemId].englishEndAt, "not ended");
        require(!idToEnglishAuction[itemId].englishEnded, "ended");


        uint256 tokenId = idToMarketplaceItem[itemId].tokenId;
        address nftContract = idToMarketplaceItem[itemId].nftContract;
        address seller = idToMarketplaceItem[itemId].seller;

        idToEnglishAuction[itemId].englishEnded = true;

        if (idToEnglishAuction[itemId].highestBidder != address(0)) {

            IERC721(nftContract).transferFrom(address(this), idToEnglishAuction[itemId].highestBidder, tokenId);

            payable(seller).transfer(
            idToEnglishAuction[itemId].highestBid
        );

            idToMarketplaceItem[itemId].buyer = payable(msg.sender);
            idToMarketplaceItem[itemId].sold = true;

        } 

        else {

           IERC721(nftContract).transferFrom(address(this),idToMarketplaceItem[itemId].seller, tokenId);
           idToMarketplaceItem[itemId].sold = true;

        }

        for(uint i = 0; i < PendingReturns[itemId].previousBidder.length; i++) {
            (bool success,) = PendingReturns[itemId].previousBidder[i].call{value: PendingReturns[itemId].previousBid[i]}("");
            require(success,"Transfer Failed");}

    }


    //DUTCH AUCTION SYSTEM

    //function to put nft on dutch auction for sell
    function dutchBid(address nftContract, uint tokenId,uint duration,uint rate,uint price,uint minprice) public {

        require(msg.sender==IERC721(nftContract).ownerOf(tokenId),"You are not the owner of this nft");
        require(price > 0, "Price must be at least 1 wei");


        _items++;
        uint256 itemId = _items;

        idToMarketplaceItem[itemId] = MarketplaceItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            Auction.DUTCH,
            false,
            duration,
            minprice
        );


        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        idToDutchAuction[itemId].dutchStartingPrice=price;
        idToDutchAuction[itemId].dutchStartAt = block.timestamp;
        idToDutchAuction[itemId].dutchExpiresAt = block.timestamp + duration;
        idToDutchAuction[itemId].dutchDiscountRate = rate;


        emit MarketplaceItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );

    }


     //function to get price of nft every second
     function DutchgetPrice(uint itemId) public view returns (uint) {

         require( itemId > 0  && itemId <= _items ,"item doesn't exist");

        uint timeElapsed = block.timestamp - idToDutchAuction[itemId].dutchStartAt;
        uint discount = idToDutchAuction[itemId].dutchDiscountRate * timeElapsed;
        uint amt=idToDutchAuction[itemId].dutchStartingPrice - discount; 
       
        if(amt<idToMarketplaceItem[itemId].minPrice){
            return idToMarketplaceItem[itemId].minPrice;
        }

        else{
             return amt;
        }

    }


    //function to buy nft 
    function buyDutch( uint itemId) external payable  {

        require( itemId > 0  && itemId <= _items ,"item doesn't exist");
        require(block.timestamp < idToDutchAuction[itemId].dutchExpiresAt, "auction expired");
        require(idToMarketplaceItem[itemId].auctiontype==Auction.DUTCH,"INVALID BUY OPTION");

        uint tokenId = idToMarketplaceItem[itemId].tokenId;
        address nftContract = idToMarketplaceItem[itemId].nftContract;
        address payable seller=idToMarketplaceItem[itemId].seller;


        uint price = DutchgetPrice(itemId);

        require(msg.value >= price, "ETH < price");

        bool sent=seller.send(price);
        require(sent,"transfer failed");

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
       
        idToMarketplaceItem[itemId].buyer = payable(msg.sender);
        idToMarketplaceItem[itemId].sold = true;

        uint refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

   }

    // function to cancel listing of an nft
    function cancelListing(uint itemId) external payable {

     require( itemId > 0  && itemId <= _items ,"item doesn't exist");
     address nftContract = idToMarketplaceItem[itemId].nftContract;  
     address seller = idToMarketplaceItem[itemId].seller;  
     uint tokenId = idToMarketplaceItem[itemId].tokenId;
     require(msg.sender==seller,"NOT THE ACTUAL OWNER");

     if(idToMarketplaceItem[itemId].auctiontype==Auction.ENGLISH)  {
         for(uint i = 0; i < PendingReturns[itemId].previousBidder.length; i++) {
            (bool success,) = PendingReturns[itemId].previousBidder[i].call{value: PendingReturns[itemId].previousBid[i]}("");
            require(success,"Transfer Failed");}
        if (idToEnglishAuction[itemId].highestBidder != address(0)){
        payable(idToEnglishAuction[itemId].highestBidder).transfer(idToEnglishAuction[itemId].highestBid);
     }}

        // need to transfer nft to original owner
  
         IERC721(nftContract).transferFrom(
         address(this),
         seller,
         tokenId);

        // delete listing object
        delete idToMarketplaceItem[itemId];
    }

   
}
