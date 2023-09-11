// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


interface IBeneficiaryCertificate is IERC721Enumerable {
    
    function awardBeneficiaryCertificate(address to) external returns(uint256);

    function removeCertification(uint256 tokenId) external;
}