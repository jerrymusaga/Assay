# 00 — Thesis

## The gap

A smart contract cannot see where value came from.

A lending market lists an asset. Someone deposits it. The market checks the
price, applies the collateral factor, permits the borrow. It never asks where
those particular tokens originated, because the question is unanswerable inside
a contract call. Every protocol that accepts assets it did not itself issue has
this hole: order books, vaults, bridges on the receiving side, treasuries.

## The evidence

**Echo Protocol, Monad, 18 May 2026.**

At 21:21 UTC an attacker used a compromised admin key to mint 1,000
unauthorized eBTC on Echo Protocol's Monad deployment — roughly $77M of
unbacked wrapped Bitcoin created from nothing. They deposited 45 eBTC as
collateral on Curvance, borrowed approximately 11.29 WBTC against it, bridged
to Ethereum, swapped to ETH, and routed 385 ETH through Tornado Cash.

Headline exposure was ~$76.7M. Actual extracted value was closer to $816,000 —
the difference being that most of the fake eBTC had nowhere to go.

**The important detail: Curvance did nothing wrong.** It observed eBTC arrive,
valued it correctly, and lent against it. The information it lacked was not
about behaviour or price. It was lineage — that this specific collateral had
been minted from nothing minutes earlier by an anomalous privileged call.

**The second important detail: detection was human and retrospective.** An
onchain analyst flagged the incident first; PeckShield mapped the laundering
path afterwards; Curvance paused the affected market once people had noticed.
Monad co-founder Keone Hon confirmed the network itself was unaffected.

On a chain producing blocks every ~400ms with ~800ms finality, the defence
layer everyone actually relies on is people reading a social timeline.

## Why this is a Monad-specific product

Monad's throughput creates a data problem that does not exist elsewhere. The
chain can grow at a theoretical maximum of ~6TB per day, which exhausts SSD
capacity, so nodes prune aggressively and retain only a few weeks of historical
state. Anyone needing older data must archive it themselves. Subgraphs on Monad
were failing on redeployment because the data was simply gone at the RPC layer,
and parallel scans overwhelmed even high-end nodes.

Two consequences:

1. **You cannot query lineage on demand.** The naive approach — look up history
   when a deposit arrives — fails, because the history is not there. You must
   have been indexing continuously. That is a real moat: a competitor arriving
   later cannot backfill what the chain has already discarded.

2. **Envio is not a sponsor integration here, it is load-bearing.** Everywhere
   else HyperSync is a speed optimisation. On Monad it is the access path to
   data that no longer exists at the RPC layer. This is the strongest honest
   "why Envio" claim available in this hackathon.

## What Assay claims

Assay answers: *is this incoming value legitimate in origin?*

It does **not** answer: *was this contract used correctly?* Oracle
manipulation, reentrancy, flash-loan attacks, logic bugs and governance attacks
all involve funds with perfectly clean lineage. Overclaiming here is the fastest
way to lose a judging Q&A. State the boundary before anyone else does.

## What it prevents

Assay does not stop the exploit. Echo still loses its admin key; 1,000 fake
eBTC still exist. What it stops is the fake collateral converting into $816,000
of somebody else's real money.

**You defend the second victim.** That is where the money actually goes.
