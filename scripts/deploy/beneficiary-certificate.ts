import {Contract} from 'ethers';
import hre, {ethers} from 'hardhat';
import {unhexify} from '../../helpers/misc';
import {
  SEPOLIA_NETWORK_ID,
  ERC6551_REGISTRY_SEPOLIA,
  EXAMPLE_721_SEPOLIA,
  BASE_ERC6551_ACCOUNT_IMPLEMENTATION,
} from '../utils/const';

import {getCounterFactualAddress} from '../utils/erc6551-related';

// Deployment Helpers:
import {getContractAt, deploy, deployUUPSUpgradableContract, upgradeUUPSUpgradeableContract} from '../utils/helpers';
// ABI
import {BaseERC6551Account, ContractAccountFactory, ERC6551Registry, ExampleERC721, BeneficiaryCertificate} from '../../typechain-types';

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  await deploy<BeneficiaryCertificate>(deployer,"BeneficiaryCertificate", [], true);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
