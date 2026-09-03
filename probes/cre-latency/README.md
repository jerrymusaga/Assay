# CRE Latency Probe

Measures **end-to-end Chainlink CRE write latency on Monad mainnet**: the gap
between an event being emitted and the DON's report landing back onchain.

This exists because `docs/02-architecture.md` claims "verdict published onchain
≤ 2 blocks (~800 ms)" — and **that is an assumption, not a documented figure.**
Chainlink publishes no latency SLA for CRE. This measures the real number.

The budget it has to fit inside is **50 seconds** — the reaction window
reconstructed from the Echo Protocol incident on Monad mainnet.

## Design

`LatencyProbe.sol` is deliberately **both the trigger source and the receiver**,
so both timestamps come from the same contract on the same chain clock. There
is no cross-contract or cross-chain skew to argue about.

```
ping()  ──emits Ping(seq, block, ts)──►  CRE log trigger fires
                                              │
                                     workflow writes back
                                              │
onReport ◄──KeystoneForwarder──────────────────┘
   records writeBlock / writeTime, emits Pong(blockDelta, secondsDelta)
```

The workflow handler does **no** offchain work — no HTTP, no chain reads, no
branching. Whatever it measures is CRE's own round trip, not our logic.

## Status

| Step | State |
|---|---|
| Contract compiles (`forge build`) | ✅ |
| CRE bindings generated | ✅ |
| Workflow typechecks (`tsc --noEmit`) | ✅ |
| **Workflow compiles to WASM** (`cre workflow simulate`) | ✅ |
| Monad mainnet RPC connectivity | ✅ |
| Deploy contract | ⬜ needs a funded key |
| Run on DON + measure | ⛔ **blocked — see below** |

## ⛔ Blocker: deployment access

```
$ cre whoami
Deploy Access:   Not enabled
```

CRE deployment access is **not enabled for this organization**, so the workflow
cannot run on the DON and true production latency cannot be measured yet.

Request it interactively (needs a TTY):

```bash
cre account access
```

Until that is granted, use the fallback below — but label its number honestly.

## Runbook

```bash
cp .env.example .env      # fill in DEPLOYER_PRIVATE_KEY (needs a little MON)

# 1. deploy (verifies the forwarder really is a KeystoneForwarder first)
./scripts/deploy.sh

# 2. paste the address into probe/config.production.json
#    "probeContractAddress": "0x..."

# 3. deploy the workflow to the DON   [requires deploy access]
cre workflow deploy ./probe --target production-settings

# 4. measure
PROBE_ADDRESS=0x... DEPLOYER_PRIVATE_KEY=0x... python3 scripts/measure.py 5
```

Output is per-sample block/second deltas plus min/median/max, written to
`latency-results.json`.

### Fallback while deploy access is pending

```bash
cre workflow simulate ./probe --target production-settings --broadcast \
  --evm-tx-hash <hash of a ping() tx> --evm-event-index 0
```

This runs the workflow **locally** and broadcasts the write via
`MockKeystoneForwarder`. It gives a **lower bound only** — it excludes DON
consensus and report aggregation, which is very likely the dominant term.
**Do not quote a simulation number as CRE latency.**

## Verified addresses (Monad mainnet)

| Contract | Address | Check |
|---|---|---|
| Production `KeystoneForwarder 1.0.0` | `0x76c9cf548b4179F8901cda1f8623568b58215E62` | `typeAndVersion()` ✅ |
| `MockKeystoneForwarder 1.0.0` | `0x9eF6468C5f37b976E57d52054c693269479A784d` | `typeAndVersion()` ✅ |

Chain name `monad-mainnet`, selector **`8481857512324358265`**.

> Note: `cre workflow supported-chains` lists `0x76c9cf54…` under a column headed
> **MOCK FORWARDER**, which contradicts the docs' Production Forwarders table.
> The onchain `typeAndVersion()` check is authoritative and says it is the
> production `KeystoneForwarder`. `deploy.sh` re-checks this before deploying.

## Interpreting the result

The window is **50 seconds**. Even a slow result leaves large margin:

- ≤5 s → excellent, quote it directly
- 5–15 s → fine, still 3× margin
- >50 s → the reactive design fails and asset-level pre-screening becomes
  mandatory (already the recommended primary path)

Whatever comes back, **quote the measured number, not the estimate.** A judge
who knows CRE will pull on that thread.
