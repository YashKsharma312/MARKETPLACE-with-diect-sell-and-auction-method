// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChristmasNFT is ERC721, Ownable {
    constructor() ERC721("ChristmasNFT", "CNT") {}

    function safeMint(address to, uint256 tokenId) public  {
        _safeMint(to, tokenId);
    }
}