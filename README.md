# Fundle Contracts

## Table of Contents
- [Introduction](#introduction)
- [How It Works](#how-it-works)
- [Technologies Used](#technologies-used)
- [Deployed Contract Addresses](#deployed-contract-addresses)
- [Pendle Integration README](#pendle-integration-readme)
- [Axelar Bounty README](#axelar-bounty-readme)

## Introduction
Fundle is an **Interchain Quadratic Funding Platform** that is powered by a Lossless Pool generated from DeFi fixed yields. Beyond the traditional direct transfers, donors have the option give without losing anything by simply depositing funds to the protocol for an amount of time. They will get back 100% of their funds risk-free, meanwhile NPOs get to keep the yields (distributed quadratically) to support their causes.

## How It Works

![FundleChart](https://github.com/ETHSG-Fundle/Fundle-Contracts/assets/106247981/3ef1d493-bd85-4eb8-90df-12ce6c5dacab)

- `Beneficiary Certificate` is a soul-bound token contract issued by Fundle through governance to accredify and whitelist beneficiaries with their assigned wallets to receive funding/donations from our donations & quadratic funding pools.

- `Donation Manager` is the main contract manager that handles all
    - 1. Direct donations to Beneficiaries
    - 2. Donations to Quadratic Funding Pool.
    - 3. Lossless donation distributions from integrated strategies.
    - 4. Fund matching distributions of QF pool donations & lossless yields generated using quadratic formula.
    
- `Savings DAI ERC4626 Strategy` is one of the deployed lossless strategies for lossless donation using DAI, where the yields generated from Spark's Protocol sDAI's contract will be distributed to the supported beneficiaries using the quadratic formula.

### Quadratic Funding Mechanism

Quadratic fund matching for both (1) donations to Quadratic Funding Pool & (2) yield donations generated from lossless strategies are determined by each `EPOCH` where each `EPOCH` will last 6 months. 

The weightage breakdown will be determined by the respective amount given to each beneficiary via direct donations from active/passive donors. 

The direct donation breakdown will then be calculated with the quadratic funding formula in `Donation Manager` and subsequently disbursed on `clrMatching` function which can be called by anyone as long as the `EPOCH` based on current time has ended only once.

Any excess or unclaimed yield right after the `EPOCH` for direct deposits to the quadratic pool & yield accrued from the lossless donation will belong to the most recently ended `EPOCH`.


## Technologies Used
- Pendle Core v2
- Axelar Network
- OpenZeppelin Open-Sourced Contracts


## Deployed Contract Addresses

### Goerli 
 
`Beneficiary Certificate`: 0x9cC857A6291598D10e9446808d3F0DDd205E0D64 
 
`Donation Manager`:  0x32f972DFbFAD84c986Db30681f1177e221ef72dd 
 
`Savings DAI ERC4626 Strategy`:  0x10371645FcB4668E04807baB7A34564fd745A111 
 
`GMP Donation Receiver`: 0xc027F2D4A76E6e86369aFbA397cfc1a6Fd97D3b5 
 
`DAI (forked)`: 0x4023Ec52F26Cb9093D642cd7e40751EeA304eAbe 
 
`sDAI (forked)`: 0xaEcB1B62E8C3e6d0DeD2706c0e3A41b29B3Fdb73 
 
`AXLUSDC ERC20 Token`: 0x254d06f33bDc5b8ee05b2ea472107E300226659A 
 
### Mantle 
 
`GMP Donation Relayer`:  0x5E04F56F0C5257c398C9A6F7E1e5caa318Eb7398 
 
`AXLUSDC ERC20 Token`: 0x254d06f33bDc5b8ee05b2ea472107E300226659A 
 
### Linea 
 
`GMP Donation Relayer`: 0x1FFaa029FD4076c38e75A3dde600dd4A527a3229 
 
`AXLUSDC ERC20 Token`: 0x254d06f33bDc5b8ee05b2ea472107E300226659A


## Pendle Integration README

Given that Pendle contracts do not exists on any testnets and it would be unfeasible to fork the entire protocol for demostration purposes. Here are 2 drafted contracts that utilises Pendle Technology to improve capital efficient and provide a variation of lossless strategy.

1. **Donation Manager with PT Integration** -  `/contracts/core/project/BeneficiaryDonationManagerPTIntegration.sol`:
    - Given how deposits for our quadratic funding pool for indecisive donors are pooled in `Donation Manager` and only distributed after an `EPOCH` has ended, this contract variation implements a custom logic to directly swap the underlying `USDC` into `PT fUSDC` from the existing `PT Flux USDC Market` assuming that Fundle operates on the mainnet.
    - Upon each deposit into the QF pool, there will be an implicit swap via the `PendleRouter` to convert the underlying USDC to `PT fUSDC` and since over time it matures in principal value (relative to its underlying asset `USDC`) itself, this action of locking in the yield will allow more `USDC` to be accrued compared to the base donated amount upon the end of the `EPOCH`.
    
2. **Lossless PT fUSDC Strategy** -  `/contracts/core/project/pendle/PendlePTfUSDCStrategy.sol`:
    - An alternative strategy for lossless donors who have idle capital in terms of the underlying asset `USDC` and are willing to lend their capital to generate yield for donations.
    - This strategy will convert all underlying `USDC` to `PT fUSDC` and by doing this, this 'locks' in current yield of the yield bearing `fUSDC` asset and will appreciate in terms of the underlying `USDC` over time.
    - Just like other lossless strategies, the user will only be able to deposit and withdraw their underlying amount in the underlying token `USDC` any time, where the excess generated `USDC` accrued from the appreciate of `PT fUSDC` will then be kept in the strategy contract and distributed quadratically at the end of the `EPOCH` when called by the `DonationManager`.


## **ReadME for Axelar Network Bounty:**

Fundle offers seamless cross-chain donations to be made to specific beneficiaries or directly to the main quadratic funding pool via the `BeneficiaryDonationManager` that all exists on the main chain (ETH Goerli) from both Linea and Mantle L2 chains that leverages on the following design. This cross-chain experience/capability would be more appealing for donors with liquidity fragmented over different chains.

A `GMPDonationReceiver` is deployed on the main chain that facilitates cross-chain donation function calls of the `BeneficiaryDonationManager` from side chains. Cross-chain calls are executed via `GMPDonationRelayer` that are deployed on both side-chains for donors with liquidity existing on these chains to have their funds bridged and routed to the `GMPDonationReceiver` which will interact directly with the `BeneficiaryDonationManager` in a single transaction call.

**Example Cross-Chain Donation Function Call alongside with sending token i.e. `callContractWithToken`:**
https://testnet.axelarscan.io/gmp/0x58e154094f1f926a05d346d6e4bd02b9ff2f4e980245b8648b7d5eb12fc3a048 [LINEA GOERLI to ETH GOERLI]

**Experiences:**

1. Learning how to integrate with Axelar Network was relatively smooth and interesting given the detailed documentation, example github repos stated in the documentations.
2. Unlike most SDKs, Axelar Network provides robust support on testnets with almost all chains integrated and D-Apps to support for UI interaction and learning purposes.
3. The Youtube Tutorial videos for devs were extremely helpful as it provided a live working example. The only downside to trying to integrate with Axelar is trying to debug cross-chain integration execution errors as error messages are not that helpful.
