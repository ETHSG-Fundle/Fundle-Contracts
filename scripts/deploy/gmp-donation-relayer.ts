import hre, {ethers} from 'hardhat';

// Deployment Helpers:
import {getContractAt, deploy } from '../utils/helpers';
// ABI
import { GmpDonationRelayer } from '../../typechain-types';

async function main() {
  const [deployer] = await hre.ethers.getSigners();

/*
[LINEA]
ID - linea
Gateway - 0xe432150cce91c13a887f7D836923d5597adD8E31
GasService - 0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6
axlUSDC - 0x254d06f33bDc5b8ee05b2ea472107E300226659A

[MANTLE]
ID - mantle
Gateway - 0xe432150cce91c13a887f7D836923d5597adD8E31
GasService - 0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6
axlUSDC - 0x254d06f33bDc5b8ee05b2ea472107E300226659A
*/
  await deploy<GmpDonationRelayer>(deployer,"GmpDonationRelayer", ["0xe432150cce91c13a887f7D836923d5597adD8E31","0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6", "0x254d06f33bDc5b8ee05b2ea472107E300226659A" ], true); // MANTLE
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
