# 02 — Architecture

Four layers. Each is independently testable.

```
┌─────────────────────────────────────────────────────────┐
│ 4. ENFORCE    guard contract  ·  Kuru listing flow      │
│               reads verdict, refuses / throttles / flags │
├─────────────────────────────────────────────────────────┤
│ 3. ATTEST     Chainlink CRE workflow                     │
│               publishes verdict onchain                  │
├─────────────────────────────────────────────────────────┤
│ 2. CLASSIFY   origin rules → verdict + reason string     │
│               GraphQL scoring API                        │
├─────────────────────────────────────────────────────────┤
│ 1. INGEST     Envio HyperIndex on Monad                  │
│               transfers · traces · deployments · factories│
│               → fund-flow graph                          │
└─────────────────────────────────────────────────────────┘
```

## Layer 1 — Ingest

**Envio HyperIndex**, continuous, on Monad mainnet (chain ID 143).

Required capabilities and why each is load-bearing:

- **Traces.** Native MON transfers emit no logs. Funding trails run through
  them. HyperIndex indexes transaction traces directly via HyperSync including
  native transfers, and Monad is on the supported list. Without traces the
  graph is incomplete by construction.
- **Wildcard indexing.** You are watching contracts you do not own. This is the
  inversion of the normal hackathon pattern (deploy a contract, index it).
- **Factory / dynamic contracts.** Pools, vaults and markets are
  factory-deployed. HyperIndex supports data from over a million dynamically
  registered contracts including nested factories.
- **Block handlers.** Rolling baselines and time-series aggregation — custom
  logic every block or at defined intervals, unlocking aggregations and bulk
  SQL updates. "Anomalous" needs a baseline to be anomalous against.
- **Effect API.** External calls from inside handlers (eth_call via viem,
  fetch, IPFS) with automatic batching, memoization, deduplication and opt-in
  persistence via `cache: true`. Use for price lookups and Nansen label
  enrichment *at index time* rather than in a separate backend.

**Note on preload optimisation:** it is always enabled in HyperIndex V3 and
makes handlers run twice. Use the Effect API for external calls rather than
`context.isPreload` guards. This is a known footgun — read the docs page before
writing handlers.

**Output:** a fund-flow graph. Nodes are addresses and contracts; edges are
value movements with block, token, amount, and transaction hash.

## Layer 2 — Classify

**The provenance walk.** Given `(address, token, amount, block)`, walk edges
backwards up to N hops and resolve where this value originated.

This is the hard engineering. Design considerations:

- Fungibility means "these specific tokens" is a fiction. Choose an accounting
  convention (FIFO on the receiving address's balance is the simplest
  defensible one) and state it explicitly. A judge may ask.
- Bound the walk. N hops, or a value-fraction threshold below which a branch is
  ignored. Unbounded walks explode.
- Cache aggressively. Most addresses resolve to the same handful of origins.

**The classifiers.** Each is a pure function over a resolved origin, returning
a verdict plus a human-readable reason. Deterministic rules only:

- `fresh_mint` — token minted with no corresponding backing/lock event
- `fresh_contract` — origin contract deployed within threshold
- `mixer_adjacent` — origin path touches known mixer addresses
- `flagged_path` — origin path touches a previously flagged address
- `shared_ancestor` — this address shares a funding ancestor with N others
- `clean` — none of the above fired

**Output:** GraphQL scoring API.

## Layer 3 — Attest

**Chainlink CRE** runs the workflow that writes verdicts onchain. Contracts
cannot call an offchain indexer synchronously, so this is the bridge.

Design: verdicts are published per (asset, address) with a block-stamped
freshness. The guard reads the latest verdict and applies its own staleness
policy.

## Layer 4 — Enforce

**Guard contract.** Sits in front of a protected market. On deposit, reads the
latest verdict for the depositing address and asset, and refuses, throttles or
flags according to the protocol's configured threshold.

Ship this as a **self-hosted module with open detection rules**. No protocol
hands a hackathon project pause authority over its live market. Demo against a
market you deployed yourself. Do not pretend otherwise — a judge will ask.

**Kuru listing flow.** Wrap Kuru's MonadDeployer so new markets are screened at
creation: the deployer address and the initial liquidity both get a provenance
verdict. Kuru's on-chain components: an Orderbook contract emitting
`OrderCreated`, `OrdersCanceled` and `Trade`; a margin account contract holding
trading balances; and an MM Entrypoint using EIP-7702 delegation for batched
cancel/replace.

This also solves a practical demo problem — you need a market to protect, and
MonadDeployer gives you one you control.

## Timing budget

At ~400ms blocks and ~800ms finality:

- deposit lands → detector fires: target ≤ 2 blocks
- verdict published onchain: target ≤ 2 blocks
- guard enforces on next interaction

Whole loop closes in ~1–2 seconds. This is the argument for why the product
lives on Monad and nowhere else.
