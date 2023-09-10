// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

interface ILosslessStrategy {

    event Deposit(uint256 indexed epochIndex, address indexed user, address indexed asset, uint256 underlyingAmountIn);
    event Withdraw(uint256 indexed epochIndex, address indexed user, address indexed asset, uint256 underlyingAmountOut);
    event EpochYieldClaim(uint256 indexed epoch, address indexed asset, uint256 yieldAmount);
    event DistributeYield(uint256 indexed epochIndex, address indexed underlyingAsset, address indexed beneficiary, uint256 amount);

    function claimYieldAndDistributeByEpoch(uint256 epochIndex, address[] memory beneficiaries, uint256[] memory basisPoints) external returns(uint256 yield, address token);

    function exchangeRate() external view returns(uint256 rate);

    function assetDetails() external view returns(address asset, uint8 decimals);

}