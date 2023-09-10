// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface IMockEndpoint {

    event MockTransfer(address indexed sender, address indexed receiver, uint256 amount);

    function mockTransfer(address sender, uint256 index, uint256 amount) external;

     function getReceiverByIndex(uint256 index) external view returns (address);
}