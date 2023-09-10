import {Contract} from 'ethers';
import {getContractAt} from './helpers';
import {ERC6551_REGISTRY_SEPOLIA} from './const';

export async function getCounterFactualAddress(
  tokenId: number,
  tokenContract: string,
  chainId: number,
  implementationAddress: string,
): Promise<string> {
  const registry = await getContractAt<Contract>('ERC6551Registry', ERC6551_REGISTRY_SEPOLIA);
  const salt: number = 0;

  const counterFactualAddress = await registry.account(implementationAddress, chainId, tokenContract, tokenId, salt);
  console.log(`Counter Factual Address: ${counterFactualAddress}`);
  return counterFactualAddress;
}
