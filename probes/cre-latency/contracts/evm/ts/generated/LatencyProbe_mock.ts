// Code generated — DO NOT EDIT.
import type { Address } from 'viem'
import { addContractMock, type ContractMock, type EvmMock } from '@chainlink/cre-sdk/test'

import { LatencyProbeABI } from './LatencyProbe'

export type LatencyProbeMock = {
  getExpectedAuthor?: () => `0x${string}`
  getExpectedWorkflowId?: () => `0x${string}`
  getExpectedWorkflowName?: () => `0x${string}`
  getForwarderAddress?: () => `0x${string}`
  getSample?: (seqNo: bigint) => readonly [bigint, bigint, bigint, bigint, boolean, bigint, bigint]
  owner?: () => `0x${string}`
  samples?: (arg0: bigint) => readonly [bigint, bigint, bigint, bigint]
  seq?: () => bigint
  supportsInterface?: (interfaceId: `0x${string}`) => boolean
} & Pick<ContractMock<typeof LatencyProbeABI>, 'writeReport'>

export function newLatencyProbeMock(address: Address, evmMock: EvmMock): LatencyProbeMock {
  return addContractMock(evmMock, { address, abi: LatencyProbeABI }) as LatencyProbeMock
}

