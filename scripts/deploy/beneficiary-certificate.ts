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

  const beneficiaryCertificate = await deploy<BeneficiaryCertificate>(deployer,"BeneficiaryCertificate", [], true);
  const tx1 = await beneficiaryCertificate.awardBeneficiaryCertificate("0x29A768F1688722EcbCCa3c11C1dE41FF314265bD");
  tx1.wait();

  const tx2 = await beneficiaryCertificate.awardBeneficiaryCertificate("0x55bA68ccf705B07c4F067E1a02780484315Ed76e");
  tx2.wait();

  const tx3 = await beneficiaryCertificate.awardBeneficiaryCertificate("0x9F4ffbFBC6721D88b45422A4371eE34bbe62caEB")
  tx3.wait();

  console.log("Done assigning all 3 addresses!");

  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
