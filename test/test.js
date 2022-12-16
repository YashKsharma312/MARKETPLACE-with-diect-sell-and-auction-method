const{expect}=require("chai");
const { BigNumber, utils } = require("ethers");
describe("Marketplace Contract",function(){
    let TestContract;
    let contract;
    let owner;
    let addr1;
    let addr2;
    let addr3;

    beforeEach(async function(){
        TestContract=await ethers.getContractFactory("Marketplace");
        [owner,addr1,addr2,addr3]=await ethers.getSigners();
        contract=await TestContract.deploy();
    });
    describe("Test contract", function () {
        it("Should set right owner",async function(){
        expect(await contract.owner()).to.equal(owner.address);})
        it("Should assign the token to the address",async function(){
        await contract.safeMint(addr1.address,1);
        expect(await contract.balanceOf(addr1.address)).to.equal(1);});
        it("Check for directSell",async function (){
        await contract.connect(owner).safeMint(addr1.address,1);
        await contract.connect(addr1).directDeposit(1,2);
        await contract.connect(addr2).directBuy(1,{value:ethers.utils.parseEther("2")});
        expect(await contract.ownerOf(1)).to.equal(addr2.address); })
        it("Check for DutchAuction",async function (){
            await contract.connect(owner).safeMint(addr1.address,1);
            await contract.connect(addr1).dutchBid(1,10,10,1);
            await contract.connect(addr2).buy(1,{value:ethers.utils.parseEther("10")});
            expect(await contract.ownerOf(1)).to.equal(addr2.address);

        })

        it("Check for EnglishAuction",async function (){
        function sleep(ms) {
            return new Promise(resolve => setTimeout(resolve, ms));
        }
        await contract.connect(owner).safeMint(addr1.address,1);
        await contract.connect(addr1).englishStart(1,1,20);
        await contract.connect(addr2).englishBid({value:ethers.utils.parseEther("2")});
        await contract.connect(addr3).englishBid({value:ethers.utils.parseEther("3")});
        await sleep(25000);
        await contract.connect(owner).englishEnd(1);
        expect(await contract.ownerOf(1)).to.equal(addr3.address);
})

       
    
    })})