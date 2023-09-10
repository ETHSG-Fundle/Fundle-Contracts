// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract LosslessStrategyManager {
    address[] internal _losslessYieldStrategies;

    /// Add lossless strategies for additional funding via yield generation from external lossless capital.
    function addStrategy(address strategy) external virtual;

    /// @notice Retrieves strategy index via address of strategy. Reverts if it does not exists.
    function getStrategyIndex(address strategy) external view returns(uint256 strategyIndex) {
        for(uint256 i = 0; i < _losslessYieldStrategies.length; i++) {
            if(strategy == _losslessYieldStrategies[i]) {
                strategyIndex = i;
                return strategyIndex;
            }
        }
        revert();
    }

     /// @notice Retrieves all strategies in a list of addresses of the strategies implemented.
    function getAllStrategies() external view returns(address[] memory strategies) {
        strategies = _losslessYieldStrategies;
    }

    /// @notice Retrieves total strategies based on length of strategies list.
    function getStrategiesLength() external view returns(uint256 length) {
        length = _losslessYieldStrategies.length;
    }
}

    