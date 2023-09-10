// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract QuadraticFundingHelper {

    // @author Uniswap
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /// Execute donation fund matching via quadratic formula to distribute yields accumulated from supported lossless strategies to whitelisted beneficiaries.
    function clrMatching(uint256 epochIndex) external virtual returns(address[] memory beneficiaries, uint256[] memory basisPoints); 
}