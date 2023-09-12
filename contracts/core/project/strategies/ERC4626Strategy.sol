// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../IBeneficiaryDonationManager.sol";
import "../../../interfaces/IERC4626.sol";
import "../ILosslessStrategy.sol";
import "../../helpers/BoringOwnable.sol";
import "../../libraries/math/Math.sol";

// sDAI - 0xD8134205b0328F5676aaeFb3B2a0DC15f4029d8C (GOERLI)
// 
contract ERC4626Strategy is ILosslessStrategy, ERC20, BoringOwnable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    uint256 public constant MAX_BPS_DENOMINATOR = 10_000;

    address public immutable BENEFICIARY_DONATION_MANAGER;
    address public immutable UNDERLYING_TOKEN;
    address public immutable YIELD_TOKEN;

    mapping(uint256 => uint256) internal _epochAccruedYield;
    mapping(address => uint256) internal _userShares;

    modifier validateEpochEnded(uint256 epochIndex) {
        uint256 epoch = IBeneficiaryDonationManager(BENEFICIARY_DONATION_MANAGER).getCurrentEpochIndex();
        require(epochIndex > epoch, "Epoch has not ended");
        _;
    }

    constructor(string memory name_, string memory symbol_, address erc4626_, address manager_) ERC20(name_, symbol_) {
        BENEFICIARY_DONATION_MANAGER = manager_;
        UNDERLYING_TOKEN = IERC4626(erc4626_).asset();
        YIELD_TOKEN = erc4626_;
        IERC20(UNDERLYING_TOKEN).safeApprove(erc4626_, type(uint256).max);
    }

    function deposit(address token, uint256 underlyingAmount) external returns (uint256 shares) {
        require(token == UNDERLYING_TOKEN, "Not underlying token");

        IERC20(UNDERLYING_TOKEN).safeTransferFrom(msg.sender,address(this), underlyingAmount);
        shares = IERC4626(YIELD_TOKEN).deposit(underlyingAmount, address(this));
        _userShares[msg.sender] += shares;
        _mint(msg.sender, underlyingAmount);
        uint256 epochIndex = _getEpochByTimestamp(block.timestamp);

        emit Deposit(epochIndex, msg.sender, UNDERLYING_TOKEN, underlyingAmount);
    }

    function withdraw(address token, uint256 underlyingAmount) external returns (uint256 underlyingAmountOut) {
        require(token == UNDERLYING_TOKEN, "Invalid token");

        require(balanceOf(msg.sender) >= underlyingAmount, "Amount requested exceeds deposit amount");
        IERC4626 yieldToken = IERC4626(YIELD_TOKEN);

        _burn(msg.sender, underlyingAmount);
        uint256 sharesToRedeem = yieldToken.convertToShares(underlyingAmount);
        _userShares[msg.sender] -= sharesToRedeem;
        underlyingAmountOut = yieldToken.redeem(sharesToRedeem, msg.sender, address(this));
        uint256 epochIndex = _getEpochByTimestamp(block.timestamp);

        emit Withdraw(epochIndex, msg.sender, UNDERLYING_TOKEN, underlyingAmount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        super._transfer(sender, recipient, amount);
        uint256 sharesAmount = IERC4626(YIELD_TOKEN).convertToShares(amount);
        _userShares[sender] -= sharesAmount;
        _userShares[recipient] += sharesAmount;
    }


    function exchangeRate() public view returns(uint256 rate) {
        rate = IERC4626(YIELD_TOKEN).convertToAssets(1e18);
    }

    function getCurrentSharesAndUnderlyingStake(address user) external view returns (uint256 shares, uint256 underlying) {
        shares = _userShares[user];
        underlying = IERC4626(YIELD_TOKEN).convertToAssets(shares);
    }


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
            IERC4626 yieldToken = IERC4626(YIELD_TOKEN);
            uint256 allShares = yieldToken.balanceOf(address(this));
            uint256 totalUnderlyingAmount = yieldToken.redeem(allShares, address(this), address(this));

            uint256 totalDeposited = totalSupply();
            yieldToken.deposit(totalDeposited, address(this));
            yieldInUnderlyingAsset = totalUnderlyingAmount - totalDeposited;
            _epochAccruedYield[epoch] = yieldInUnderlyingAsset;

            emit EpochYieldClaim(epoch, UNDERLYING_TOKEN, yieldInUnderlyingAsset);
        } 
    }

    function _getEpochByTimestamp(uint256 timestamp) internal view returns (uint256 epoch) {
        epoch = IBeneficiaryDonationManager(BENEFICIARY_DONATION_MANAGER).getEpochIndex(timestamp);
    }
}