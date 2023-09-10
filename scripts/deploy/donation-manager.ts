import hre, {ethers} from 'hardhat';

// Deployment Helpers:
import {getContractAt, deploy } from '../utils/helpers';
// ABI
import { BeneficiaryDonationManager } from '../../typechain-types';

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  // axlUSDC - 0x254d06f33bDc5b8ee05b2ea472107E300226659A (ethereum-2)
  // BeneficiaryCertificate - 0x47f576b1E1EfD61c3a07F4576a177b8a20602B4b
  await deploy<BeneficiaryDonationManager>(deployer,"BeneficiaryDonationManager", ["0x254d06f33bDc5b8ee05b2ea472107E300226659A", "0x47f576b1E1EfD61c3a07F4576a177b8a20602B4b"], true); // Goerli
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
