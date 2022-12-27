const{expect}=require("chai");
const { ethers } = require('hardhat');
const { BigNumber, utils } = require("ethers");


describe("Marketplace Contract", function(){
    let TestContract;
    let NFTcontract;
    let contract;
    let contract1;
    let owner;
    let addr1;
    let addr2;
    let addr3;



    beforeEach(async function(){
        TestContract=await ethers.getContractFactory("Marketplace");
        NFTcontract=await ethers.getContractFactory("ChristmasNFT");
        [owner,addr1,addr2,addr3]=await ethers.getSigners();
        contract=await TestContract.deploy();
        contract1=await NFTcontract.deploy();
    });



    describe("Test contract", function () {

        it("Providing 0 as amount while listing",async function(){
            await contract1.safeMint(addr1.address,1);
            await contract1.connect(addr1).approve(contract.address,1);
            await expect( contract.connect(addr1).fixedPricesale(contract1.address,1,0)).to.be.revertedWith("Price must be at least 1 wei");
        })



        it("Check if the address listing nft is not owner of nft ",async function(){
            await contract1.safeMint(addr1.address,1);
            await contract1.connect(addr1).approve(contract.address,1);
            await expect( contract.connect(addr2).fixedPricesale(contract1.address,1,1)).to.revertedWith("You are not the owner of this nft");
    });




        it("Check for fixedPricesellSell",async function (){
        await contract1.safeMint(addr1.address,1);
        await contract1.connect(addr1).approve(contract.address,1);
        await contract.connect(addr1).fixedPricesale(contract1.address,1,2);
        await contract.connect(addr2).fixedPricebuy(1,{value:ethers.utils.parseEther("2")});
        expect(await contract1.ownerOf(1)).to.equal(addr2.address); 
    })




        it("Check if item id dosen't exist",async function(){
            await contract1.safeMint(addr1.address,1);
            await contract1.connect(addr1).approve(contract.address,1);
            await contract.connect(addr1).fixedPricesale(contract1.address,1,2);
            await expect( contract.connect(addr2).fixedPricebuy(2,{value:ethers.utils.parseEther("2")})).to.revertedWith("item doesn't exist")
        })



        it("Check send amount is less than listed",async function(){
            await contract1.safeMint(addr1.address,1);
            await contract1.connect(addr1).approve(contract.address,1);
            await contract.connect(addr1).fixedPricesale(contract1.address,1,BigInt(3000000000000000000));
            await expect( contract.connect(addr2).fixedPricebuy(1,{value:ethers.utils.parseEther("1")})).to.revertedWith("Please submit the asking price in order to complete the purchase")
        })



        it(" Check if listing nft in english auction is done by owner",async function(){
            await contract1.safeMint(addr1.address,1);
            await contract1.connect(addr1).approve(contract.address,1);
            await expect( contract.connect(addr2).englishStart(contract1.address,1,20,1)).to.revertedWith("You are not the owner of this nft")
        })




        it(" Revert if english auction already started",async function(){
            await contract1.safeMint(addr1.address,1);
            await contract1.connect(addr1).approve(contract.address,1);
            await contract.connect(addr1).englishStart(contract1.address,1,20,1);
            await expect( contract.connect(contract).englishStart(contract1.address,1,20,1)).to.revertedWith("started");
        })



        it("Check if item dosen't exist while bid",async function(){
            await contract1.safeMint(addr1.address,1);
            await contract1.connect(addr1).approve(contract.address,1);
            await contract.connect(addr1).englishStart(contract1.address,1,20,1);
            await expect( contract.connect(addr2).englishBid(2,{value:ethers.utils.parseEther("2")})).to.revertedWith("item doesn't exist")

        })



        it("Revert if bidding after auction ended",async function(){
            function sleep(ms) {
                return new Promise(resolve => setTimeout(resolve, ms));
            }
            await contract1.safeMint(addr1.address,1);
            await contract1.connect(addr1).approve(contract.address,1);
            await contract.connect(addr1).englishStart(contract1.address,1,20,1);
            await sleep(20000);
            await expect( contract.connect(addr2).englishBid(1,{value:ethers.utils.parseEther("2")})).to.revertedWith("ended")
        })


        it("check for highest bid ",async function(){
            await contract1.safeMint(addr1.address,1);
            await contract1.connect(addr1).approve(contract.address,1);
            await contract.connect(addr1).englishStart(contract1.address,1,20,1);
            await contract.connect(addr2).englishBid(1,{value:ethers.utils.parseEther("2")});
            await contract.connect(addr3).englishBid(1,{value:ethers.utils.parseEther("3")});
            expect(await contract.getHighestBid(1)).to.equal(BigInt(3000000000000000000));
        })




        it("Revert if auction has not started while calling endfunction",async function(){
        await expect( contract.connect(owner).englishEnd(1)).to.revertedWith("item doesn't exist")
        })



        it("Check for EnglishAuction",async function (){
            function sleep(ms) {
                return new Promise(resolve => setTimeout(resolve, ms));
            }
            await contract1.safeMint(addr1.address,1);
            await contract1.connect(addr1).approve(contract.address,1);
            await contract.connect(addr1).englishStart(contract1.address,1,20,1);
            await contract.connect(addr2).englishBid(1,{value:ethers.utils.parseEther("2")});
            await contract.connect(addr3).englishBid(1,{value:ethers.utils.parseEther("3")});
            await sleep(25000);
            await contract.connect(owner).englishEnd(1);
            expect(await contract1.ownerOf(1)).to.equal(addr3.address);
    })



        it("Check for DutchAuction",async function (){
            await contract1.safeMint(addr1.address,1);
            await contract1.connect(addr1).approve(contract.address,1);
            await contract.connect(addr1).dutchBid(contract1.address,1,100,1,100,10);
            await contract.connect(addr2).buyDutch(1,{value:ethers.utils.parseEther("100")});
            expect(await contract1.ownerOf(1)).to.equal(addr2.address);

        })



        it("Check if the entry amount in dutch auction is less than or equal to 0",async function(){
            await contract1.safeMint(addr1.address,1);
            await contract1.connect(addr1).approve(contract.address,1);
            await expect( contract.connect(addr1).dutchBid(contract1.address,1,100,1,0,10)).to.revertedWith("Price must be at least 1 wei")
        })

        
        it("revert if buying after auction end in dutch",async function(){
            function sleep(ms) {
                return new Promise(resolve => setTimeout(resolve, ms));
            }
            await contract1.safeMint(addr1.address,1);
            await contract1.connect(addr1).approve(contract.address,1);
            await contract.connect(addr1).dutchBid(contract1.address,1,10,1,10,2);
            await sleep(11000);
            await expect( contract.connect(addr2).buyDutch(1,{value:ethers.utils.parseEther("100")})).to.revertedWith("auction expired")
        })



       it(" cancel listing of NFT",async function (){
        await contract1.safeMint(addr1.address,1);
        await contract1.connect(addr1).approve(contract.address,1);
        await contract.connect(addr1).englishStart(contract1.address,1,20,1);
        await contract.connect(addr1).cancelListing(1);
        expect(await contract1.ownerOf(1)).to.equal(addr1.address);
       })



       it("revert if cancel nft is not done by actual owner",async function(){
        await contract1.safeMint(addr1.address,1);
        await contract1.connect(addr1).approve(contract.address,1);
        await contract.connect(addr1).englishStart(contract1.address,1,20,1);
        await expect( contract.connect(addr2).cancelListing(1)).to.revertedWith("NOT THE ACTUAL OWNER");
       })



       
       it(" check if the nft transfer to marketplace",async function (){
        await contract1.safeMint(addr1.address,1);
        await contract1.connect(addr1).approve(contract.address,1);
        await contract.connect(addr1).englishStart(contract1.address,1,20,1);
        expect(await contract1.ownerOf(1)).to.equal(contract.address);
       })



       it(" Check if one buying interpret to other buying option",async function(){
       
        await contract1.safeMint(addr1.address,1);
        await contract1.connect(addr1).approve(contract.address,1);
        await contract.connect(addr1).englishStart(contract1.address,1,20,1);
        await contract.connect(addr2).englishBid(1,{value:ethers.utils.parseEther("2")});
        await expect( contract.connect(addr3).fixedPricebuy(1,{value:ethers.utils.parseEther("2")})).to.revertedWith("INVALID BUY OPTION");
       })



       it(" Check for buyers bid",async function(){
        await contract1.safeMint(addr1.address,1);
        await contract1.connect(addr1).approve(contract.address,1);
        await contract.connect(addr1).englishStart(contract1.address,1,20,1);
        await contract.connect(addr2).englishBid(1,{value:ethers.utils.parseEther("2")});
        await contract.connect(addr3).englishBid(1,{value:ethers.utils.parseEther("3")});
        expect(await contract.bids(1,addr3.address)).to.equal(BigInt(3000000000000000000));
       })



       it(" Check for Dutchgetprice",async function(){
        function sleep(ms) {
           return new Promise(resolve => setTimeout(resolve, ms));
        }
        await contract1.safeMint(addr1.address,1);
        await contract1.connect(addr1).approve(contract.address,1);
        await contract.connect(addr1).dutchBid(contract1.address,1,100,1,100,10);
        expect(await contract. DutchgetPrice(1)).to.equal(100);
       })

       
    
    })})
