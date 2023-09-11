import hre, {ethers} from 'hardhat';

// Deployment Helpers:
import {getContractAt, deploy } from '../utils/helpers';
// ABI
import { BeneficiaryDonationManager } from '../../typechain-types';

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  // axlUSDC - 0x254d06f33bDc5b8ee05b2ea472107E300226659A (ethereum-2)
  // BeneficiaryCertificate - 0x9cC857A6291598D10e9446808d3F0DDd205E0D64
  const manager = await deploy<BeneficiaryDonationManager>(deployer,"BeneficiaryDonationManager", ["0x254d06f33bDc5b8ee05b2ea472107E300226659A", "0x9cC857A6291598D10e9446808d3F0DDd205E0D64"], true); // Goerli

  // await manager.addStrategy("");
  const tx1 = await manager.registerBeneficiary("0x29A768F1688722EcbCCa3c11C1dE41FF314265bD", 0);
  tx1.wait();

  const tx2 = await manager.registerBeneficiary("0x55bA68ccf705B07c4F067E1a02780484315Ed76e", 1);
  tx2.wait();

  const tx3 = await manager.registerBeneficiary("0x9F4ffbFBC6721D88b45422A4371eE34bbe62caEB", 2);
  tx3.wait();

  console.log("Deployed and register all beneficiaries!")
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
