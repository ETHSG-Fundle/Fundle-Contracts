// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IGMPDonationBase } from "./IGMPDonationBase.sol";


interface IGMPDonationRelayer is IGMPDonationBase {
    function executeMainDonation(string calldata destChain, string calldata destAddress,uint256 beneficiaryIndex, uint256 amount, uint256 donationType) external payable;

}