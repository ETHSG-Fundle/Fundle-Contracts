// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IERC20Metadata } from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IGMPDonationRelayer } from "./IGMPDonationRelayer.sol";

contract GmpDonationRelayer is IGMPDonationRelayer, AxelarExecutable {
    IAxelarGasService internal immutable gasService;
    IERC20Metadata internal immutable supportedToken; // Must be axlUSDC
    uint256 public lastBeneficiaryIndex;

    constructor(address gateway_, address gasReceiver_, address token_) AxelarExecutable(gateway_) {
        gasService = IAxelarGasService(gasReceiver_);
        supportedToken = IERC20Metadata(token_);
    }

    // If `donationType` == 2, `beneficiaryIndex` can be set to 0 as a placeholder.
    function executeMainDonation(string calldata destChain, string calldata destAddress, uint256 beneficiaryIndex, uint256 amount, uint256 donationType) external payable  {
        require(msg.value > 0, 'Gas payment is required');

        supportedToken.transferFrom(msg.sender, address(this), amount);
        supportedToken.approve( address(gateway) , amount);

        string memory symbol = supportedToken.symbol();
        uint256 srcChainId = block.chainid;
        bytes memory payload = abi.encode(msg.sender, srcChainId, donationType, beneficiaryIndex); // DonationType: 1 or 2

        gasService.payNativeGasForContractCallWithToken{value: msg.value} (
            address(this),
            destChain,
            destAddress,
            payload,
            symbol,
            amount,
            msg.sender
        );

        gateway.callContractWithToken(destChain, destAddress, payload, symbol, amount);
    }

    function getAxelarGasService() external view returns(address service) {
        service = address(gasService);
    }

    function getSupportedToken() external view returns(address token) {
        token = address(supportedToken);
    }
}