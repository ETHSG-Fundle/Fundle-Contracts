// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IGMPDonationBase {
    event ExecuteCrossChainDonation(address indexed sender, uint256 indexed srcChainId, uint256 indexed beneificiaryIndex,address token, uint256 amount);

    function getAxelarGasService() external view returns(address service);

    function getSupportedToken() external view returns(address token);

}