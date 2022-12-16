// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is ERC721, Ownable {
    constructor() ERC721("MyToken", "MTK") {}

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
    mapping(uint=>sellerInfo)public MarketItem;
    mapping (uint=>bool) public depositedNft;

    uint public englishEndAt;
    bool public englishStarted;
    bool public englishEnded;
    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public bids;

    uint public  dutchStartingPrice;
    uint public  dutchStartAt;
    uint public  dutchExpiresAt;
    uint public  dutchDiscountRate;

    struct sellerInfo{
        address payable seller;
        uint nftId;
        uint nftPrice;
    }

    //DIRECT SALE SYSTEM

    function directDeposit(uint _id,uint _price) public {
      sellerInfo memory seller=sellerInfo(payable(msg.sender),_id,_price*10**18);
      MarketItem[_id]=seller;
      transferFrom(msg.sender,address(this),_id);
      depositedNft[_id]=true;
    }

    function directBuy(uint id) public payable {
        ERC721(address(this)).approve(msg.sender, id);
        address payable _sellerAddress=MarketItem[id].seller;
        uint price=MarketItem[id].nftPrice;
        require(msg.value == price, "Not adequate ethers");
        bool sent=_sellerAddress.send(msg.value);
        require(sent,"transfer failed");
        safeTransferFrom(address(this),msg.sender,id);
        depositedNft[id]=false; 
    }

    //ENGLISH AUCTION SYSTEM

     function englishStart(uint _id,uint _price,uint duration) external {
         sellerInfo memory seller=sellerInfo(payable(msg.sender),_id,_price*10**18);
         MarketItem[_id]=seller;
        require(!englishStarted, "started");
        transferFrom(msg.sender, address(this), _id);
        englishStarted = true;
        englishEndAt = block.timestamp + duration;
        highestBid = _price;
        depositedNft[_id]=true;
    }

    function englishBid() external payable {
        require(englishStarted, "not started");
        require(block.timestamp < englishEndAt, "ended");
        require(msg.value > highestBid, "value > highest");

        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        
    }
    function englishWithdraw() external {
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);
    }

    function englishEnd(uint _id) external onlyOwner {
        ERC721(address(this)).approve(msg.sender, _id);
        address payable _seller=MarketItem[_id].seller;
        require(englishStarted, "not started");
        require(block.timestamp >= englishEndAt, "not ended");
        require(!englishEnded, "ended");

        englishEnded = true;
        if (highestBidder != address(0)) {
            safeTransferFrom(address(this), highestBidder, _id);
            _seller.transfer(highestBid);
        } else {
            safeTransferFrom(address(this), _seller, _id);
        }
        depositedNft[_id]=false;
    }

    //DUTCH AUCTION SYSTEM

    function dutchBid(uint _id,uint _price,uint duration,uint rate) public {
         sellerInfo memory seller=sellerInfo(payable(msg.sender),_id,_price*10**18);
         transferFrom(msg.sender, address(this), _id);
         MarketItem[_id]=seller;
         dutchStartingPrice=_price*10**18;
         dutchStartAt = block.timestamp;
         dutchExpiresAt = block.timestamp + duration;
         dutchDiscountRate = rate;
         require(_price >= rate * duration, " price < min");
    }

    function DutchgetPrice() public view returns (uint) {
        uint timeElapsed = block.timestamp - dutchStartAt;
        uint discount = (dutchDiscountRate*10**18) * timeElapsed;
        return dutchStartingPrice - discount;
    }

    function getBack(uint _id ) public {
        ERC721(address(this)).approve(msg.sender, _id);
         address payable seller=MarketItem[_id].seller;
         require(msg.sender==seller,"Not NFT owner");
        require(block.timestamp>dutchExpiresAt,"Auction still going");
        safeTransferFrom(address(this), msg.sender, _id);
    }

    function buy(uint _id) external payable {
        require(block.timestamp < dutchExpiresAt, "auction expired");
        address payable seller=MarketItem[_id].seller;
        ERC721(address(this)).approve(msg.sender, _id);
        uint price = DutchgetPrice();
        require(msg.value >= price, "ETH < price");
        bool sent=seller.send(price);
        require(sent,"transfer failed");
        transferFrom(address(this), msg.sender,_id);
        uint refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
   }

}