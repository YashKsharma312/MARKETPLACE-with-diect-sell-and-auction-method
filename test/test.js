const{expect}=require("chai");
const { BigNumber, utils } = require("ethers");


describe("Marketplace Contract",function(){
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

        it("1)Should set right owner",async function(){
        expect(await contract.owner()).to.equal(owner.address);})


        it("2)Should assign the token to the address",async function(){
        await contract1.safeMint(addr1.address,1);
        expect(await contract1.balanceOf(addr1.address)).to.equal(1);
    });


        it("3)Check for fixedPricesellSell",async function (){
        await contract1.safeMint(addr1.address,1);
        await contract1.connect(addr1).approve(contract.address,1);
        await contract.connect(addr1).fixedPricesale(contract1.address,1,2);
        await contract.connect(addr2).fixedPricebuy(1,{value:ethers.utils.parseEther("2")});
        expect(await contract1.ownerOf(1)).to.equal(addr2.address); 
    })


        it("4)Check for DutchAuction",async function (){
            await contract1.safeMint(addr1.address,1);
            await contract1.connect(addr1).approve(contract.address,1);
            await contract.connect(addr1).dutchBid(contract1.address,1,100,1,100,10);
            await contract.connect(addr2).buyDutch(1,{value:ethers.utils.parseEther("100")});
            expect(await contract1.ownerOf(1)).to.equal(addr2.address);

        })



        it("5)Check for EnglishAuction",async function (){
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
        
        it("6) cancel listing of NFT",async function (){
        await contract1.safeMint(addr1.address,1);
        await contract1.connect(addr1).approve(contract.address,1);
        await contract.connect(addr1).englishStart(contract1.address,1,20,1);
        await contract.connect(addr1).cancelListing(1);
        expect(await contract1.ownerOf(1)).to.equal(addr1.address);
       })

       
    
    })})
