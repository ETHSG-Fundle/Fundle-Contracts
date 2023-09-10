// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IERC20Metadata } from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { TokenHelper } from "../../helpers/TokenHelper.sol"; 
import { IBeneficiaryDonationManager } from "../IBeneficiaryDonationManager.sol";
import { IGMPDonationBase } from "./IGMPDonationBase.sol";



contract GMPDonationReceiver is IGMPDonationBase, AxelarExecutable, TokenHelper {
    IAxelarGasService internal immutable gasService;
    IERC20Metadata internal immutable supportedToken;
    address public constant DONANTION_MANAGER = 0x27235EE90ff5379D228f7692aFDBEba358Ded8EA;
    uint256 public lastBeneficiaryIndex;


    constructor(address gateway_, address gasReceiver_, address _token) AxelarExecutable(gateway_) {
        gasService = IAxelarGasService(gasReceiver_);
        supportedToken = IERC20Metadata(_token);
        _safeApproveInf(_token, DONANTION_MANAGER);
    }

    function _executeWithToken(string calldata, string calldata,bytes calldata payload,string calldata tokenSymbol,uint256 amount) internal override {
        (address sender, uint256 srcChainId, uint256 donationType, uint256 beneficiaryIndex) = abi.decode(payload, (address, uint256, uint256, uint256));
        lastBeneficiaryIndex = beneficiaryIndex;
       
        // get ERC-20 address from gateway
        address tokenAddress = gateway.tokenAddresses(tokenSymbol);

        // Already max approve spending for this contract to RECEIVER via constructor for supported token.
        if(donationType == 1) {
            IBeneficiaryDonationManager(DONANTION_MANAGER).donateBeneficiary(sender, beneficiaryIndex, amount);
        } else if (donationType == 2) {
            IBeneficiaryDonationManager(DONANTION_MANAGER).depositForEpochDistribution(sender, amount);
        }

         emit ExecuteCrossChainDonation(sender, srcChainId, beneficiaryIndex, tokenAddress, amount);
    }

    function getAxelarGasService() external view returns(address service) {
        service = address(gasService);
    }

    function getSupportedToken() external view returns(address token) {
        token = address(supportedToken);
    }
}