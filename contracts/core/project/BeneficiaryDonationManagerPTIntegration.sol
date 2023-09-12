// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPActionSwapPT } from "@pendle/core-v2/contracts/interfaces/IPActionSwapPT.sol";
import { IPMarket } from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import { IPPrincipalToken } from "@pendle/core-v2/contracts/interfaces/IPPrincipalToken.sol";
import "@pendle/core-v2/contracts/router/base/ActionBaseMintRedeem.sol";
import "@pendle/core-v2/contracts/router/base/MarketApproxLib.sol";
import "@pendle/core-v2/contracts/router/swap-aggregator/IPSwapAggregator.sol";
import { BeneficiaryDonationManager } from "./BeneficiaryDonationManager.sol";
import { PendlePTHelper } from "./strategies/pendle/PendlePTHelper.sol";


// contract Hello {}

contract BeneficiaryDonationManagerPTIntegration is BeneficiaryDonationManager, PendlePTHelper {
    using SafeERC20 for IERC20;

    address public PT_FUSDC_MARKET = 0xcB71c2A73fd7588E1599DF90b88de2316585A860;
    address public PENDLE_ROUTER;

    constructor(address token_, address certificate_, address pendleRouter_) BeneficiaryDonationManager(token_, certificate_) {
        PENDLE_ROUTER = pendleRouter_;
        _safeApproveInf(token_, pendleRouter_); // Approve max for underlying USC token
    }



    function convertQFPoolDepositsForPT() external returns (uint256 netPtOut, uint256 netUnderlyingIn) {
        (netPtOut, netUnderlyingIn) = _swapUnderlyingDepositsForPT();
    }

    
    function _swapUnderlyingDepositsForPT() internal override returns(uint256 netPtOut, uint256 netUnderlyingIn) {

        netUnderlyingIn = _selfBalance(USDC);
        SwapData memory swapData = SwapData({  
            swapType: SwapType.NONE,
            extRouter: address(0),
            extCalldata: "",
            needScale: false
        });

        ApproxParams memory guessPtOut = ApproxParams({
            guessMin: 0, 
            guessMax: type(uint256).max, 
            guessOffchain: 0, 
            maxIteration: 256, 
            eps: 1e15
        });

        TokenInput memory input = TokenInput({
            tokenIn: USDC,
            netTokenIn: netUnderlyingIn,
            tokenMintSy: USDC,
            bulk: address(0),
            pendleSwap: address(0),
            swapData: swapData
        });


        (netPtOut,) = IPActionSwapPT(PENDLE_ROUTER).swapExactTokenForPt(address(this), PT_FUSDC_MARKET, 0, guessPtOut, input);
    }

      function _distributeMainDepositsByEpoch(uint256 epochIndex, address[] memory beneficiaries, uint256[] memory basisPoints) internal override {
        uint256 epoch = _calcEpochIndex(block.timestamp);
        require(epochIndex > epoch, "Epoch has not ended");

        _swapPtHoldingsToUnderlying();
        uint256 totalDeposited = _selfBalance(USDC);

        for(uint256 i = 0; i < beneficiaries.length; i++) {
            uint256 amount = (totalDeposited * basisPoints[i]) / MAX_BPS_DENOMINATOR;
            IERC20(USDC).safeTransfer(beneficiaries[i], amount);
        }
    }

    function _swapPtHoldingsToUnderlying() internal override returns (uint256 netPtIn, uint256 netTokenOut) {
        (,IPPrincipalToken PT,) = IPMarket(PT_FUSDC_MARKET).readTokens();
        netPtIn = _selfBalance(address(PT));

        SwapData memory swapData = SwapData({  
            swapType: SwapType.NONE,
            extRouter: address(0),
            extCalldata: "",
            needScale: false
        });

        TokenOutput memory output = TokenOutput({
            tokenOut: USDC,
            minTokenOut: 0,
            tokenRedeemSy: USDC,
            bulk: address(0),
            pendleSwap: address(0),
            swapData: swapData
        });

        (netTokenOut,) = IPActionSwapPT(PENDLE_ROUTER).swapExactPtForToken(address(this), PT_FUSDC_MARKET, netPtIn, output);
    }
}