// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IERC20Metadata } from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';

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
contract GmpDonationRelayer is AxelarExecutable {
    IAxelarGasService internal immutable gasService;
    IERC20Metadata internal immutable supportedToken; // Must be axlUSDC
    address public constant RECEIVER = 0x27235EE90ff5379D228f7692aFDBEba358Ded8EA;
    uint256 public lastBeneficiaryIndex;

    constructor(address gateway_, address gasReceiver_, address _token) AxelarExecutable(gateway_) {
        gasService = IAxelarGasService(gasReceiver_);
        supportedToken = IERC20Metadata(_token);
    }

    // If `donationType` == 2, `beneficiaryIndex` can be set to 0 as a placeholder.
    function executeMainDonation(string memory destinationChain, string memory destinationAddress, uint256 beneficiaryIndex, uint256 amount, uint256 donationType) external payable  {
        require(msg.value > 0, 'Gas payment is required');

        supportedToken.transferFrom(msg.sender, address(this), amount);
        supportedToken.approve( address(gateway) , amount);

        string memory symbol = supportedToken.symbol();
        uint256 srcChainId = block.chainid;
        bytes memory payload = abi.encode(msg.sender, srcChainId, donationType, beneficiaryIndex); // DonationType: 1 or 2

        // Need to approve spending for ERC20 first? KIV
        gasService.payNativeGasForContractCallWithToken{value: msg.value} (
            address(this),
            destinationChain,
            destinationAddress,
            payload,
            symbol,
            amount,
            msg.sender
        );

        gateway.callContractWithToken(destinationChain, destinationAddress, payload, symbol, amount);
    }

    function getAxelarGasService() public view returns(address service) {
        service = address(gasService);
    }

    function getSupportTokenAddress() public view returns(address token) {
        token = address(supportedToken);
    }
}