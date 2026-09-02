# 03 — Evidence & Evaluation Corpus

Two detectors, two evidence bases. Present them separately. Do not claim one
model covers both.

---

## Case A — Echo Protocol (the story)

**Timeline, as publicly reported:**

| When | What |
|---|---|
| 18 May 2026, 21:21 UTC | 1,000 eBTC minted on Echo's Monad deployment via compromised admin key (~$77M notional at ~$77k BTC) |
| shortly after | 45 eBTC deposited as collateral on Curvance |
| shortly after | ~11.29 WBTC borrowed against it |
| after | bridged to Ethereum, swapped to ETH, 385 ETH into Tornado Cash |
| after | Echo regained admin key control, burned the remaining 955 eBTC |
| after | Curvance paused the affected market; Echo suspended cross-chain transactions |

**Loss:** headline ~$76.7M minted, actual extracted ~$816,000.

**Who detected it:** onchain analyst `dcfgod` flagged it first. PeckShield
mapped the laundering path. Lookonchain tracked the flow. All human, all after
the fact.

**Why it is an ideal evaluation case:**
- Publicly timestamped
- The signal is unmissable — a 1,000-unit mint against a small deployment is a
  threshold rule, not ML
- **The mint preceded the extraction**, so a detection window provably existed

**The unknown that decides the project:** how many blocks between mint and
borrow. See `tasks/task-01-delta-reconstruction.md`.

**N=1 caveat.** One protocol-level incident is a story, not a validation. Say
so before a judge does, and lean on Case B for statistics.

---

## Case B — Address poisoning (the statistics)

Spoofed token transfers hit Monad within days of mainnet launch (mainnet went
live 24 November 2025).

**Mechanism**, per SlowMist's CISO Shān Zhang: attackers generate vanity
addresses matching the first and last four characters of a target's real
exchange deposit or cold wallet address, then spam spoofed transfers from the
lookalike, betting the user will lazily copy the most recent address out of
their transaction history. He noted this works especially well during a chain
launch, when users are constantly creating wallets, bridging funds and adding
token contracts, so transaction history is empty or chaotic.

**Why this is your statistical backbone:**
- Deterministic detection — prefix/suffix collision against an address the user
  has actually transacted with, unsolicited, typically dust. Precision should
  be near-perfect.
- Thousands of instances rather than one.
- Automation is safe because false positives are near-zero.

---

## Case C — Rug volume (unverified hypothesis)

Monad has launchpads. Base rates from other ecosystems suggest large volume:
a 2026 Solana preprint identified 76,469 candidate rug-pull tokens among
100,063 issued on three DEXs in early 2025, with at least $151M in traceable
losses; Solidus Labs found 98.6% of over seven million Pump.fun tokens studied
had fallen below $1,000 in liquidity (which shows collapse, not proven fraud).

**Treat this as a hypothesis to verify against Monad's own data, not a fact.**
Rug-pull statistics vary sharply because researchers count different
behaviours, thresholds and forms of loss; there is no reliable global total.

---

## Evaluation design

**Precision/recall** comes from Case B. Backfill the address-poisoning corpus,
run the detector, report numbers with the detection rule stated in full.

**Counterfactual value** comes from Case A. "Our rule fires at block X. The
money left at block Y. Delta = Z seconds. The actual response took hours and
came from Twitter."

**Do not** merge these into a single accuracy claim.

---

## The airdrop cohort (optional side artifact)

Monad published a CSV of airdrop claimer wallets and amounts — 76,021 unique
wallets claimed, filtered by Trusta AI for sybils, eligibility determined on
pre-mainnet data (testnet activity, DeFi usage elsewhere, high-value DEX
trading, long-term NFT holdings), with claims running 14 Oct – 3 Nov 2025 and
mainnet launching 24 Nov 2025.

Because labels were fixed before any mainnet behaviour existed, all subsequent
mainnet activity is out-of-sample forward data. **Caveat: positives only** —
Trusta's rejected list is not public, so this is positive-unlabelled data.

This is not part of the product. It is a cheap, high-visibility public analysis
("did the anti-sybil filtering work? who held, who sold?") that builds
ecosystem attention during the build and teaches you Monad's onchain texture.
One indexer and a weekend. Optional.
