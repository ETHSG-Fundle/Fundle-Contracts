// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../helpers/BoringOwnable.sol";

contract BeneficiaryCertificate is ERC721Enumerable, BoringOwnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Beneficiary Certificate Token", "BCT") {}

    function awardBeneficiaryCertificate(address to) external onlyOwner returns (uint256) {
        require(balanceOf(to) == 0, "Recipient has already an existing certification.");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        return tokenId;
    }

    // Decide: who burns it, why and how?
    function removeCertification(uint256 tokenId) external onlyOwner {
        // require(ownerOf(tokenId) == msg.sender, "Only the owner of the token can burn it.");
        _burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256, uint256) pure override(ERC721Enumerable) internal {
        require(from == address(0) || to == address(0), "Certificate is untransferrable.");
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }
}