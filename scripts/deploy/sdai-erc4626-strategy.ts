import hre from 'hardhat';

// Deployment Helpers:
import { deploy } from '../utils/helpers';
// ABI
import { ERC4626Strategy } from '../../typechain-types';

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  // axlUSDC - 0x254d06f33bDc5b8ee05b2ea472107E300226659A (ethereum-2)
  // sDAI - 0xaEcB1B62E8C3e6d0DeD2706c0e3A41b29B3Fdb73
   // BeneficiaryManager - 0x27aB44cA2bdEE4567050Ebb739691739C8149f03
  await deploy<ERC4626Strategy>(deployer,"ERC4626Strategy", ["Savings DAI Lossless Strategy","sDAI LS", "0xaEcB1B62E8C3e6d0DeD2706c0e3A41b29B3Fdb73", "0x27aB44cA2bdEE4567050Ebb739691739C8149f03"], true); // Goerli
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
