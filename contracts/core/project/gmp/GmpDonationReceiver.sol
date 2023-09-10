// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IERC20Metadata } from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { TokenHelper } from "../../helpers/TokenHelper.sol"; 
// Testing
import { IMockEndpoint } from "./IMockEndpoint.sol";
import { IBeneficiaryDonationManager } from "../IBeneficiaryDonationManager.sol";

// MITKN Fuji - 0x0f0Bb9362EAB5De2A7e3E0a34628243014621f53
// Fuji Gateway - 0xC249632c2D40b9001FE907806902f63038B737Ab
// Fuji GasService - 0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6
// Fuji Receiver - 0x9a72c125b30f7bebE4B3e8D1cFFA214EEaf79128
/*
MITKN Base Goerli - 0x7BE9f92109Adc6066F8Aa649CcE9b689A1b341c0
Base Goerli Gateway - 0xe432150cce91c13a887f7D836923d5597adD8E31
Base Goerli GasService - 0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6
Base Goerli Receiver - 0xD4b4014849d154Ff1445611f2234fd08aeB8A736
*/
contract CrossChainDonationDistributor is AxelarExecutable, TokenHelper {
    IAxelarGasService internal immutable gasService;
    IERC20Metadata internal immutable supportedToken;
    address public constant DONANTION_MANAGER = 0x27235EE90ff5379D228f7692aFDBEba358Ded8EA; // TO MockEndpoint
    uint256 public lastBeneficiaryIndex;

    event ExecuteCrossChainDonation(address indexed sender, uint256 indexed srcChainId, uint256 indexed beneificiaryIndex,address token, uint256 amount);

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

    function getAxelarGasService() public view returns(address service) {
        service = address(gasService);
    }

    function getSupportTokenAddress() public view returns(address token) {
        token = address(supportedToken);
    }
}