// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ILosslessStrategy.sol";
import "../helpers/BoringOwnable.sol";
import "./IBeneficiaryCertificate.sol";
import "./LosslessStrategyManager.sol";
import "./QuadraticFundingHelper.sol";
import "../libraries/TokenHelper.sol";
import "./IBeneficiaryDonationManager.sol";

/// @notice Main Managing Contract to facilitate direct donations to supported NPOs & also handle claiming of yields from Lossless strategies alongside with distrubutions of yields based on quadratric funding determined by distribution of main donation.
contract BeneficiaryDonationManager is IBeneficiaryDonationManager, LosslessStrategyManager, BoringOwnable, TokenHelper, QuadraticFundingHelper {
    using SafeERC20 for IERC20;

    address public immutable USDC; // Fake Address
    address public immutable BENEFICIARY_CERTIFICATE; // Fake Address of Soulbound Token
    
    // Each Epoch Interval -> Fund raising round to determine the yield distribution from lossless pool, beyond an epoch, the yield accumulated will 
    uint256 public constant MAX_BPS_DENOMINATOR = 10_000;

    uint256 public constant EPOCH_INTERVAL = 4 * 6 weeks;

    // Direct donate opportunity vs direct donation of funds
    uint256 public immutable START_TIME; // This is the Unix timestamp for August 26, 12:00AM;


    // EPOCH -> Beneficiary (represented by index or address) => Total donated amount
    mapping(uint256 => mapping(uint256 => uint256)) internal _epochBeneficiaryDonations;
    // Soulbound Token (BeneficiaryCertificate) -> address of created AA from BeneficiaryAccountFactory
    mapping(uint256 => address) internal _beneficiaryAccount;



    constructor(address token_, address certificate_) {
        START_TIME = block.timestamp;
        USDC = token_; // alxUSDC
        BENEFICIARY_CERTIFICATE = certificate_;
    }

 /*
=========================================================================
                        PUBLIC/EXTERNAL FUNCTIONS
=========================================================================
*/
    // @notice [CROSS-CHAIN] Allows anyone who wanted to donate funds, but are not willing to decide which specific beneficiary to donate to, to get active donors to decide on distribution via quadratic funding mechanism.
    function depositForEpochDistribution(address donor, uint256 amount) external {
        _donateForEpochDistribution(donor, msg.sender, amount);
    }

      // @notice Allows anyone who wanted to donate funds, but are not willing to decide which specific beneficiary to donate to, to get active donors to decide on distribution via quadratic funding mechanism.
    function depositForEpochDistribution(uint256 amount) external {
        _donateForEpochDistribution(msg.sender, msg.sender, amount);
    }

     /// @notice Allows anyone to donate to beneficiary of choice based on `beneficiaryIndex` with a specified amount of supported token.
    function donateBeneficiary(uint256 beneficiaryIndex, uint256 amount) external {
        _donateBeneficiary(msg.sender, msg.sender, beneficiaryIndex, amount);
    }

     /// @notice [CROSS-CHAIN] Allows anyone to donate to beneficiary of choice based on `beneficiaryIndex` with a specified amount of supported token.
    function donateBeneficiary(address donor, uint256 beneficiaryIndex, uint256 amount) external {
        require(donor != address(0), "Null address");
        _donateBeneficiary(donor, msg.sender, beneficiaryIndex, amount);
    }

    /// @dev See-{QuadraticFundingHelper-clrMatching}
    function clrMatching(uint256 epochIndex) external override returns(address[] memory beneficiaries, uint256[] memory basisPoints){
        (beneficiaries, basisPoints) = _getEpochDonationDistribution(epochIndex);

        // 1. Execute for all lossless strategies
        for(uint256 i = 0; i < _losslessYieldStrategies.length; i++) {
            ILosslessStrategy(_losslessYieldStrategies[i]).claimYieldAndDistributeByEpoch(epochIndex, beneficiaries, basisPoints);
        }

        // 2. Execute for Main pool deposits
        _distributeMainDepositsByEpoch(epochIndex, beneficiaries, basisPoints);
    }  

    /// @dev See {LosslessStrategyManager-addStrategy}.
    function addStrategy(address strategy) external override onlyOwner {
        _losslessYieldStrategies.push(strategy);
    } 

    function removeStrategy(address strategy) external override onlyOwner {
        uint256 strategyIndex = _getStrategyIndexByAddress(strategy);
        uint256 length = _losslessYieldStrategies.length;

        if(strategyIndex != length - 1) {
             _losslessYieldStrategies[strategyIndex] = _losslessYieldStrategies[length - 1];
        }
        _losslessYieldStrategies.pop();
    }


    function registerBeneficiary(address beneficiary, uint256 index) external onlyOwner {
        _beneficiaryAccount[index] = beneficiary;
    }

 /*
=========================================================================
                PUBLIC/EXTERNAL VIEW FUNCTIONS
=========================================================================
*/
  
    /// @notice Returns the current total accumulated amount of donations for a specified `epochIndex` and `beneficiaryIndex`.
   function getEpochBeneficiaryDonation(uint256 epochIndex, uint256 beneficiaryIndex) external view returns(uint256) {
        return _epochBeneficiaryDonations[epochIndex][beneficiaryIndex];
    }

    /// @notice Returns Total donation for epoch specifed by `epochIndex`
    function getTotalEpochDonation(uint256 epochIndex) external view returns(uint256 total){
        total = _calcTotalEpochDonation(epochIndex);
    }    

    // For Lossless pool to execute quadratic funding formula on the weightage of donation for each epoch -> MODIFY FOR QUADRATIC FUNDING FORMULA
    function getEpochDonationDistribution(uint256 epochIndex) external view returns(address[] memory beneficiaries, uint256[] memory basisPoints) {
       (beneficiaries, basisPoints) = _getEpochDonationDistribution(epochIndex);
    }

    /// @notice Returns all addresses of whitelisted benefiaries eligible to receive donations.
    function getAllBeneficiaries() external view returns (address[] memory beneficiaries) {
        uint256 length = IBeneficiaryCertificate(BENEFICIARY_CERTIFICATE).totalSupply();
        beneficiaries = new address[](length);
        for(uint256 i = 0; i < length; i++) {
            beneficiaries[i] = _getBeneficiaryAddress(i);
        }
    }

    /// @notice Returns the benefiaciary abstracted account address mapped by `beneficiaryIndex`
    function getBeneficiaryAddress(uint256 beneficiaryIndex) external view returns(address beneficiary) {
        beneficiary = _getBeneficiaryAddress(beneficiaryIndex);
    }

    /// @notice Returns the epoch index based on a specified `blockNumber`
    function getEpochIndex(uint256 blockNumber) external view returns(uint256 index) {
        index = _calcEpochIndex(blockNumber);
    }

    /// @notice Returns the epoch index based on the current block.timestamp
    function getCurrentEpochIndex() external view returns(uint256 index) {
        index = _calcEpochIndex(block.timestamp);
    }


 /*
=========================================================================
                    INTERNAL/PRIVATE FUNCTIONS
=========================================================================
*/

    function _donateBeneficiary(address donor, address sender, uint256 beneficiaryIndex, uint256 amount) internal {
         require(amount > 0, "Invalid amount");

        uint256 epochIndex =  _calcEpochIndex(block.timestamp);
        address beneficiary = _getBeneficiaryAddress(beneficiaryIndex);
        require(beneficiary != address(0), "Beneficiary does not exist");

        _epochBeneficiaryDonations[epochIndex][beneficiaryIndex] += amount;
        IERC20(USDC).safeTransferFrom(sender, beneficiary, amount); // Need Approval from donor to allow contract to spendon their behalf

        emit Donation(epochIndex, donor, beneficiaryIndex, amount);
    }

    /// @notice For direct donations but to be distrubuted via quadratic funding mechanism based on active donation distribution to supported NPOs.
    function _donateForEpochDistribution(address donor,address sender, uint256 amount) internal {
        require(amount > 0, "Invalid amount");

        uint256 epochIndex =  _calcEpochIndex(block.timestamp);
        IERC20(USDC).safeTransferFrom(sender, address(this), amount);

        emit DepositForEpochDistributedDonation(epochIndex, donor, amount);
    }

    function _distributeMainDepositsByEpoch(uint256 epochIndex, address[] memory beneficiaries, uint256[] memory basisPoints) internal {
        uint256 epoch = _calcEpochIndex(block.timestamp);
        require(epochIndex > epoch, "Epoch has not ended");

        uint256 totalDeposited = _selfBalance(USDC);

        for(uint256 i = 0; i < beneficiaries.length; i++) {
            uint256 amount = (totalDeposited * basisPoints[i]) / MAX_BPS_DENOMINATOR;
            IERC20(USDC).safeTransfer(beneficiaries[i], amount);
        }
    }

    /// @notice Calculates the resp ective basis points for each whitelisted benefiaciary based on the distribution of main donations received via the quadratic funding formula
  function _getEpochDonationDistribution(
    uint256 epochIndex
  ) internal view returns (address[] memory beneficiaries, uint256[] memory basisPoints) {
    uint256 totalBeneficiaries = IBeneficiaryCertificate(BENEFICIARY_CERTIFICATE).totalSupply();
    uint256 totalQuadSum;
    for (uint256 i = 0; i < totalBeneficiaries; i++) {
      uint256 quadSum = sqrt(_epochBeneficiaryDonations[epochIndex][i]);
      totalQuadSum += quadSum;
    }

    address[] memory internal_beneficiaries = new address[](totalBeneficiaries);
    uint256[] memory internal_basisPoints = new uint256[](totalBeneficiaries);

    for (uint256 i = 0; i < totalBeneficiaries; i++) {
      uint256 quadSum = sqrt(_epochBeneficiaryDonations[epochIndex][i]);
      internal_beneficiaries[i] = (_getBeneficiaryAddress(i));
      internal_basisPoints[i] = (_calcBeneficiaryDonationBps(quadSum, totalQuadSum));
    }

    beneficiaries = internal_beneficiaries;
    basisPoints = internal_basisPoints;
  }

   /// @notice Retrieves the address of the benefiary tagged to the `beneficiaryIndex`.
    function _getBeneficiaryAddress(uint256 beneficiaryIndex) internal view returns (address beneficiary) {
        beneficiary = _beneficiaryAccount[beneficiaryIndex];
        require(beneficiary != address(0), "Beneficiary Index does not exist anymore");
    }

    /// @notice Calculates the current total accumulated amount of donations for a specified `epochIndex` and `beneficiaryIndex`.
    function _calcTotalEpochDonation(uint256 epochIndex) internal view returns(uint256 total) {
          IBeneficiaryCertificate BeneficiaryCertificate = IBeneficiaryCertificate(BENEFICIARY_CERTIFICATE);
        uint256 totalSupply = BeneficiaryCertificate.totalSupply();

        for(uint256 i; i < totalSupply;){
            total += _epochBeneficiaryDonations[epochIndex][i];
            unchecked {
                i++;
            }
        }
    }

    /// @notice Calculates the unfiltered basis points of a benefiary based on `received` amount relative to `total`.
    function _calcBeneficiaryDonationBps(uint256 received, uint256 total) internal pure returns(uint256) {
        return (received * MAX_BPS_DENOMINATOR) / total;
    }

    /// @notice Calculates and retrives the epoch index belonging to a specified `timestamp`.
    function _calcEpochIndex(uint256 timestamp) internal view returns(uint256) {
        require(timestamp > START_TIME, "Invalid timestamp");
        return (timestamp - START_TIME) / EPOCH_INTERVAL; // Round down
    }
}