import hre, {ethers} from 'hardhat';

// Deployment Helpers:
import {getContractAt, deploy } from '../utils/helpers';
// ABI
import { ERC4626Strategy } from '../../typechain-types';

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  // axlUSDC - 0x254d06f33bDc5b8ee05b2ea472107E300226659A (ethereum-2)
  // BeneficiaryCertificate - 0x47f576b1E1EfD61c3a07F4576a177b8a20602B4b
  // sDAI - 0xD8134205b0328F5676aaeFb3B2a0DC15f4029d8C 
  await deploy<ERC4626Strategy>(deployer,"ERC4626Strategy", ["Savings DAI Lossless Strategy","sDAI LS", "0xD8134205b0328F5676aaeFb3B2a0DC15f4029d8C", "0x483a1075E1989fB0c8ffF69391134013Fb3e71ce"], true); // Goerli
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
