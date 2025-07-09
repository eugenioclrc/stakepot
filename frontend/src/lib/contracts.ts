import { config } from '../routes/init';
import { writeContract } from '@wagmi/core/actions'; // v2 path
import { parseAbi, parseEther } from 'viem';
import { get } from 'svelte/store';

export const RAFFLE = '0x4C3B188b2DF090592C26eA1850B72dA0c7A749e4' as `0x${string}`;

const abi = parseAbi([
	'function buyTickets() external payable'
]);

export async function buyTickets(numberTickets: number) {
    // tickets price is 0.0001 ether
    const amount = parseEther('0.0001') * (BigInt(numberTickets));
	
	const wagmiConfig = get(config);
	if (!wagmiConfig) throw new Error('wagmiConfig not found');
	
	// Use writeContract with the wagmi config
	const data = await writeContract(wagmiConfig, {
		address: RAFFLE,
		abi,
		functionName: 'buyTickets',
		args: [],
		value: amount // For payable functions, use value instead of args
	});

	return data;
}
