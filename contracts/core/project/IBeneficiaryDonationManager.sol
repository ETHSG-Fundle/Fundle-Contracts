// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBeneficiaryDonationManager {

    event Donation(uint256 indexed epoch, address indexed donor, uint256 indexed beneficiary, uint256 amount); // User Total amount donated can be tracked via indexing this event

    event DepositForEpochDistributedDonation(uint256 indexed epoch, address indexed donor, uint256 amount);

    function donateBeneficiary(uint256 beneficiaryIndex, uint256 amount) external;

     function donateBeneficiary(address donor, uint256 beneficiaryIndex, uint256 amount) external;

    function getEpochIndex(uint256 timestamp) external view returns(uint256);

    function getCurrentEpochIndex() external view returns (uint256);

   function getEpochBeneficiaryDonation(uint256 epochIndex, uint256 beneficiaryIndex) external view returns(uint256);

    function getTotalEpochDonation(uint256 epochIndex) external view returns(uint256 total);

    function getEpochDonationDistribution(uint256 epochIndex) external view returns(address[] memory, uint256[] memory);

    function getBeneficiaryAddress(uint256 beneficiaryIndex) external view returns(address beneficiary);
    
    function getAllBeneficiaries() external view returns (address[] memory beneficiaries);
    
    // function getWeightDistributionByEpoch(uint256 epochIndex) external view returns (address[] memory bpsAmounts);
}