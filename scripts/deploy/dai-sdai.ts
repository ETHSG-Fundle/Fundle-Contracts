import hre from 'hardhat';

// Deployment Helpers:
import { deploy } from '../utils/helpers';
// ABI
import { DAI, SavingsDAI } from '../../typechain-types';

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  const dai = await deploy<DAI>(deployer,"DAI", [], true); // Goerli

  await deploy<SavingsDAI>(deployer,"SavingsDAI", [dai.address], true); // Goerli
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
