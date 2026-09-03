import {
	bytesToHex,
	cre,
	getNetwork,
	TxStatus,
	type Runtime,
} from '@chainlink/cre-sdk'
import { type Address, encodeAbiParameters, parseAbiParameters } from 'viem'
import { z } from 'zod'
import {
	LatencyProbe,
	type DecodedLog,
	type PingDecoded,
} from '../contracts/evm/ts/generated/LatencyProbe'

// ─── Config ─────────────────────────────────────────────────
export const configSchema = z.object({
	chainSelectorName: z.string(),
	probeContractAddress: z.string(),
	isTestnet: z.boolean().default(false),
})
type Config = z.infer<typeof configSchema>

const getProbe = (config: Config) => {
	const network = getNetwork({
		chainFamily: 'evm',
		chainSelectorName: config.chainSelectorName,
		isTestnet: config.isTestnet,
	})
	if (!network) throw new Error(`Network not found: ${config.chainSelectorName}`)

	const evmClient = new cre.capabilities.EVMClient(network.chainSelector.selector)
	return new LatencyProbe(evmClient, config.probeContractAddress as Address)
}

// ─── Handler ────────────────────────────────────────────────
// Deliberately does NO offchain work: no HTTP, no chain reads, no branching.
// Whatever this measures is CRE's own round trip, not our logic.
export const onPing = (
	runtime: Runtime<Config>,
	payload: DecodedLog<PingDecoded>,
): string => {
	const { seqNo, blockNumber } = payload.data
	runtime.log(`Ping seq=${seqNo} emitted at block ${blockNumber} — writing back immediately`)

	const probe = getProbe(runtime.config)

	// Report body is just the sequence number. The contract already recorded the
	// trigger block on ping(), so the write side only has to identify the sample.
	const report = encodeAbiParameters(parseAbiParameters('uint256 seqNo'), [seqNo])

	const writeResult = probe.writeReport(runtime, report)

	if (writeResult.txStatus !== TxStatus.SUCCESS) {
		throw new Error(
			`write failed for seq=${seqNo}: ${writeResult.errorMessage || writeResult.txStatus}`,
		)
	}

	const txHash = bytesToHex(writeResult.txHash || new Uint8Array(32))
	runtime.log(`seq=${seqNo} written back — tx ${txHash}`)
	return `seq=${seqNo} tx=${txHash}`
}

// ─── Init ───────────────────────────────────────────────────
export function initWorkflow(config: Config) {
	const probe = getProbe(config)
	return [cre.handler(probe.logTriggerPing(), onPing)]
}
