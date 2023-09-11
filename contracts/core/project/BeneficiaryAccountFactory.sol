// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./BeneficiaryAccount.sol";
import "./IBeneficiaryCertificate.sol";
import "./IBeneficiaryDonationManager.sol";

/**
 * A sample factory contract for BeneficiaryAccount
 * A UserOperations "initCode" holds the address of the factory, and a method call (to createAccount, in this sample factory).
 * The factory's createAccount returns the target account address even if it is already installed.
 * This way, the entryPoint.getSenderAddress() can be called either before or after the account is created.
 */
contract BeneficiaryAccountFactory {
    BeneficiaryAccount public immutable accountImplementation;
    address public immutable BENEFICIARY_CERTIFICATE;

    modifier _validateCertifiedBeneficiary(address account) {
        uint256 balance = IBeneficiaryCertificate(BENEFICIARY_CERTIFICATE).balanceOf(account);
        require(balance == 1, "No beneficiary cetificate");
        _;
    }

    constructor(IEntryPoint _entryPoint, address _beneficiaryCertificate) {
        BENEFICIARY_CERTIFICATE = _beneficiaryCertificate;
        accountImplementation = new BeneficiaryAccount(_entryPoint); // Mock account implementation for initCode
        
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
     */
    function createAccount(address owner,uint256 salt) public returns (BeneficiaryAccount ret) {
        address addr = getAddress(owner, salt);
        uint codeSize = addr.code.length;
        if (codeSize > 0) {
            return BeneficiaryAccount(payable(addr));
        }

        uint256 certificateId = getBeneficiaryCetificate(owner);
        ret = BeneficiaryAccount(payable(new ERC1967Proxy{salt : bytes32(salt)}(
                address(accountImplementation),
                abi.encodeCall(BeneficiaryAccount.initialize, (owner,BENEFICIARY_CERTIFICATE, certificateId))
            )));
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(address owner,uint256 salt) public _validateCertifiedBeneficiary(owner) view returns (address) {
        uint256 certificateId = getBeneficiaryCetificate(owner);

        return Create2.computeAddress(bytes32(salt), keccak256(abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(
                    address(accountImplementation),
                    abi.encodeCall(BeneficiaryAccount.initialize, (owner, BENEFICIARY_CERTIFICATE, certificateId))
                )
            )));
    }


    function getBeneficiaryCetificate(address account) public view returns (uint256) {
        uint256 tokenId = IBeneficiaryCertificate(BENEFICIARY_CERTIFICATE).tokenOfOwnerByIndex(account, 0); // 0th Index
        return tokenId;
    }
}


/*
BeneficiaryCertificate -> Soulbound token for KYC-ed wallets given by certified NPOs

KYC-ed Wallet A -> Approved (received a SBT from BeneficiaryCertificate) -> Eligible to create AA on BeneficiaryAccountFactory -> Create BeneficiaryAccount (AA)
*/