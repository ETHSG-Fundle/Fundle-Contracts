import {Contract} from 'ethers';
import {getContractAt} from './helpers';
import {ERC4337_CONTRACT_ACCOUNT_FACTORY} from './const';

export async function getCounterFactualAddress(owner: string): Promise<string> {
  const contractAccountFactory = await getContractAt<Contract>(
    'ContractAccountFactory',
    ERC4337_CONTRACT_ACCOUNT_FACTORY,
  );
  const salt: number = 0;

  const counterFactualAddress = await contractAccountFactory.getAddress(owner, salt);
  console.log(`Counter Factual Address: ${counterFactualAddress}`);
  return counterFactualAddress;
}
