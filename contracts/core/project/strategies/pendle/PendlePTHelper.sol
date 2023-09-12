// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@pendle/core-v2/contracts/oracles/PendlePtOracleLib.sol";

abstract contract PendlePTHelper {
   

   function _swapUnderlyingDepositsForPT() internal virtual returns(uint256, uint256) {}

   function _swapPtHoldingsToUnderlying() internal virtual returns(uint256, uint256) {}
}