// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../helpers/BoringOwnable.sol";

contract BeneficiaryCertificate is ERC721, BoringOwnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Fundle Beneficiary Certificate Token", "FBCT") {}

    function awardBeneficiaryCertificate(address to) external onlyOwner returns (uint256) {
        require(balanceOf(to) == 0, "Recipient has already an existing certification.");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);

        return tokenId;
    }

    function removeCertification(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256, uint256) pure override(ERC721) internal {
        require(from == address(0) || to == address(0), "Certificate is untransferrable.");
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function totalSupply() public view returns(uint256) {
        return _tokenIdCounter.current();
    }
}