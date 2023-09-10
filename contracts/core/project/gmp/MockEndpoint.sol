// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IMockEndpoint } from "./IMockEndpoint.sol";


/*
Constructor:  (Receivers) [0x0CB481aa69B8eC20c5C9C4f8750370E1E59173ca, 0x55bA68ccf705B07c4F067E1a02780484315Ed76e,0x45112BE77c895a9FeB2F7d8d6Fd2B0A469795224 ]
["0x0CB481aa69B8eC20c5C9C4f8750370E1E59173ca", "0x55bA68ccf705B07c4F067E1a02780484315Ed76e","0x45112BE77c895a9FeB2F7d8d6Fd2B0A469795224"]
*/


/*
MockEndpoint - FUJI - 0xe345181ABD2e9154Efa4A4CC06EB55658674ff3a
GMPDonationReceiver - FUJI - 0x67cC5160a9710a5eA75715a0BFA5F8B5BA54B3b0
// Testing GmpDonationReceiver - FUJI - 0x5b21d2a107B819186E6BeFC2Ac6aF1eAE5154DED
GMPDonationRelayer - BASE GOERLI - 0xe7ecF9266F81dAE10FC241983Cf838E6BDf2A1a3

// SET APPROVAL FOR RELAYER TO SPEND!!!! 
- https://goerli.basescan.org/address/0x254d06f33bDc5b8ee05b2ea472107E300226659A#writeContract


/*
axlUSDC
Fuji: 0x57F1c63497AEe0bE305B8852b354CEc793da43bB
Polygon zkEVM: 0xCb7996d51Ff923b2C6076d42C065a6ca000D32A1
Goerli: 0x254d06f33bDc5b8ee05b2ea472107E300226659A
Mumbai: 0x2c852e740B62308c46DD29B982FBb650D063Bd07
Mantle: 0x254d06f33bDc5b8ee05b2ea472107E300226659A
Base: 0x254d06f33bDc5b8ee05b2ea472107E300226659A
*/

/*
Testing Trial:
Main Chain: Fuji
Support Chains: Mantle/Polyogon

Step 1: Deploy Mockendpoint on Fuji
Step 2: Deploy GmpDonationReceiver on Fuji -> SET RECEIVER to Mockpoint Contract
Step 3: Deploy GmpDonationSender on supporting chains

*/
contract MockEndpoint is IMockEndpoint {
    using SafeERC20 for IERC20;

    address public constant USDC = 0xde637d4C445cA2aae8F782FFAc8d2971b93A4998; // Change to axlUSDC
    
    mapping(uint256 => address) private _indexReceiverMap;

    constructor(address[] memory receivers_) {
        for(uint256 i = 0; i < receivers_.length; i++) {
            _indexReceiverMap[i] = receivers_[i];
        }
    }

    
    function mockTransfer(address sender, uint256 index, uint256 amount) external {
        require(amount > 0, "Invalid amount");
        
        address receiver = _indexReceiverMap[index];
        require(receiver != address(0), "Null address");
        IERC20(USDC).safeTransferFrom(msg.sender, receiver, amount); // Will be transferred by GmpDonationReceiver

        emit MockTransfer(sender, receiver, amount);
    }

    function getReceiverByIndex(uint256 index) external view returns (address receiver) {
        receiver = _indexReceiverMap[index];
    }
}