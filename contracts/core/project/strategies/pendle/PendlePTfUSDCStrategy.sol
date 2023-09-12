// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IPActionSwapPT } from "@pendle/core-v2/contracts/interfaces/IPActionSwapPT.sol";
import { IPMarket } from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import { IPPrincipalToken } from "@pendle/core-v2/contracts/interfaces/IPPrincipalToken.sol";
import "@pendle/core-v2/contracts/router/base/ActionBaseMintRedeem.sol";
import "@pendle/core-v2/contracts/router/base/MarketApproxLib.sol";
import "@pendle/core-v2/contracts/router/swap-aggregator/IPSwapAggregator.sol";
import "../../IBeneficiaryDonationManager.sol";
import "../../../../interfaces/IERC4626.sol";
import "../../ILosslessStrategy.sol";
import "../../../helpers/BoringOwnable.sol";
// import "../../../libraries/math/Math.sol";


contract PendlePTfUSDCStrategy is ILosslessStrategy, ERC20, BoringOwnable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    uint256 public constant MAX_BPS_DENOMINATOR = 10_000;

    address public immutable BENEFICIARY_DONATION_MANAGER;
    address public immutable UNDERLYING_TOKEN;
    address public immutable PENDLE_ROUTER;
    address public immutable PRINCIPAL_TOKEN;
    address public immutable MARKET;

    mapping(uint256 => uint256) internal _epochAccruedYield;

    modifier validateEpochEnded(uint256 epochIndex) {
        uint256 epoch = IBeneficiaryDonationManager(BENEFICIARY_DONATION_MANAGER).getCurrentEpochIndex();
        require(epochIndex > epoch, "Epoch has not ended");
        _;
    }

    constructor(string memory name_, string memory symbol_,address underlying_, address fUSDCPt_,address pendleRouter_,address market_, address manager_) ERC20(name_, symbol_) {
        BENEFICIARY_DONATION_MANAGER = manager_;
        UNDERLYING_TOKEN = underlying_;
        PRINCIPAL_TOKEN = fUSDCPt_;
        PENDLE_ROUTER = pendleRouter_;
        MARKET = market_;
        IERC20(UNDERLYING_TOKEN).safeApprove(pendleRouter_, type(uint256).max);
        IERC20(PRINCIPAL_TOKEN).safeApprove(pendleRouter_, type(uint256).max);
    }

    function deposit(address token, uint256 underlyingAmount) external returns (uint256 shares) {
        require(token == UNDERLYING_TOKEN, "Not underlying token");

        IERC20(UNDERLYING_TOKEN).safeTransferFrom(msg.sender,address(this), underlyingAmount);
        shares = _swapUnderlyingDepositsForPT(underlyingAmount); 
        _mint(msg.sender, underlyingAmount);
        uint256 epochIndex = _getEpochByTimestamp(block.timestamp);

        emit Deposit(epochIndex, msg.sender, UNDERLYING_TOKEN, underlyingAmount);
    }

    function withdraw(address token, uint256 underlyingAmount) external returns (uint256 underlyingAmountOut) {
        require(token == UNDERLYING_TOKEN, "Invalid token");

        require(balanceOf(msg.sender) >= underlyingAmount, "Amount requested exceeds deposit amount");

        _burn(msg.sender, underlyingAmount);
        uint256 ptAmount = underlyingAmount;
        underlyingAmountOut = _swapUnderlyingDepositsForPT(ptAmount);
        IERC20(UNDERLYING_TOKEN).safeTransfer(msg.sender, underlyingAmountOut);
        uint256 epochIndex = _getEpochByTimestamp(block.timestamp);

        emit Withdraw(epochIndex, msg.sender, UNDERLYING_TOKEN, underlyingAmount);
    }

    function _swapUnderlyingDepositsForPT(uint256 underlyingAmount) internal returns(uint256 netPtOut) {

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
            tokenIn: UNDERLYING_TOKEN,
            netTokenIn: underlyingAmount,
            tokenMintSy: UNDERLYING_TOKEN,
            bulk: address(0),
            pendleSwap: address(0),
            swapData: swapData
        });


        (netPtOut,) = IPActionSwapPT(PENDLE_ROUTER).swapExactTokenForPt(address(this), MARKET, 0, guessPtOut, input);
    }

     function _swapPtHoldingsToUnderlying(uint256 amount) internal returns (uint256 netPtIn, uint256 netTokenOut) {
        netPtIn = amount;

        SwapData memory swapData = SwapData({  
            swapType: SwapType.NONE,
            extRouter: address(0),
            extCalldata: "",
            needScale: false
        });

        TokenOutput memory output = TokenOutput({
            tokenOut: UNDERLYING_TOKEN,
            minTokenOut: 0,
            tokenRedeemSy: UNDERLYING_TOKEN,
            bulk: address(0),
            pendleSwap: address(0),
            swapData: swapData
        });

        (netTokenOut,) = IPActionSwapPT(PENDLE_ROUTER).swapExactPtForToken(address(this), MARKET, netPtIn, output);
    }


    function exchangeRate() public view returns(uint256 rate) {}


    function assetDetails() external view returns(address asset, uint8 decimals) {
        asset = UNDERLYING_TOKEN;
        decimals = IERC20Metadata(UNDERLYING_TOKEN).decimals();
    }


    function claimYieldAndDistributeByEpoch(uint256 epochIndex, address[] memory beneficiaries, uint256[] memory basisPoints) external validateEpochEnded(epochIndex) returns(uint256 yield, address token) {
        require(msg.sender == BENEFICIARY_DONATION_MANAGER, "Only can be called by donation manager");

        yield = _accrueYieldByEpoch(epochIndex);

        for(uint256 i = 0; i < beneficiaries.length; i++) {
            uint256 amount = (yield * basisPoints[i]) / MAX_BPS_DENOMINATOR;
            IERC20(UNDERLYING_TOKEN).safeTransfer(beneficiaries[i], amount);

            emit DistributeYield(epochIndex, UNDERLYING_TOKEN, beneficiaries[i], amount);
        }

        token = UNDERLYING_TOKEN;
    }


        function _accrueYieldByEpoch(uint256 epoch) internal returns (uint256 yieldInUnderlyingAsset) {
 
        if (_epochAccruedYield[epoch] != 0) {
            yieldInUnderlyingAsset = 0;
        } else {
            IERC20 principalToken = IPPrincipalToken(PRINCIPAL_TOKEN);
            uint256 allShares = principalToken.balanceOf(address(this));
            (,uint256 totalUnderlyingAmount) = _swapPtHoldingsToUnderlying(allShares);

            uint256 totalDeposited = totalSupply();
            _swapUnderlyingDepositsForPT(totalDeposited);
            yieldInUnderlyingAsset = totalUnderlyingAmount - totalDeposited;
            _epochAccruedYield[epoch] = yieldInUnderlyingAsset;

            emit EpochYieldClaim(epoch, UNDERLYING_TOKEN, yieldInUnderlyingAsset);
        } 
    }

    function _getEpochByTimestamp(uint256 timestamp) internal view returns (uint256 epoch) {
        epoch = IBeneficiaryDonationManager(BENEFICIARY_DONATION_MANAGER).getEpochIndex(timestamp);
    }
}