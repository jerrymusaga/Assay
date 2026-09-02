# 04 — Hackathon

**Event:** Monad Metropolis, 1 Sep – 13 Oct 2026. $250,000+ prize pool.
Monad mainnet, chain ID 143.

## Track

**Track 04 — Trust, Identity & AI Infrastructure.** $30k.

Rationale: provenance is trust infrastructure, unambiguously. Track 04 also
self-gates by advertising for teams comfortable with cryptography, protocol
design or agent frameworks, which thins the field. Track 02 (Consumer Products
& Payments) is the crowded one — it requires no domain expertise, so expect the
highest submission volume there.

Track 01 (Onchain Finance & Trading) is arguable since the customers are
lending markets, but it explicitly favours teams who have shipped a trading or
lending product before.

**Check before committing:** whether the rules permit only one track
submission. Bounties usually stack across tracks regardless.

## Bounties

**Taking:**

| Sponsor | Prize | Fit |
|---|---|---|
| Envio | $1,000 | Load-bearing, not decorative. Strongest honest case in the field. |
| Chainlink CRE | $3,000 | The workflow that publishes verdicts onchain. Natural. |
| Nansen | $5,000 | Address labels as classifier input — mixers, exchanges, flagged clusters. |
| Kuru | $5,000 | "Bring New Assets and Markets" — screened listing flow via MonadDeployer. ~3–4 days extra work. |

≈ **$14k** on top of the $30k track.

**Stretch (week 5, drop without guilt):**

| Perpl | $3,000 | "Best Analytics / Risk Tool" — wash-trading detection by joining their Fill/Order streams to your funding graph. |

**Rejected, with reasons:**

- **MetaMask $2,500 (Best Agent Wallet Plugin)** — reaching. Would require
  strapping an agent onto the front, which adds a component judges have seen a
  thousand times, weakens the deterministic story, and reads as bounty-farming.
- **Perpl $5,000 (Best use of API)** — structural mismatch. Perps need only a
  price oracle and a stablecoin for margin, so there is no arbitrary-collateral
  surface for provenance to screen.
- **Monad $5,000 (Best Community Team Project)** — requires a team.
- **Mera bounties** — no passkey/account surface in this product.

## Sponsor technical notes

**Perpl API** (if pursuing the stretch): REST + WebSocket. Public
`/v1/pub/context` endpoint gives markets, tokens and chain config with no auth.
Typed messages: account update `mt: 21`, Order `mt: 24`, Fill `mt: 25`. Fee
fields — `f` is gross total (protocol + builder), with builder portion broken
out as `bfa`; never add them together. Connection cap of 4 keyed on the owning
wallet, not the individual key, with browser sessions counting against the same
budget. Trading and market-data servers have separate limits. API keys are
trade-only and can never withdraw funds.

**Kuru SDK**: TypeScript (`@kuru-labs/kuru-sdk`) and Python (`kuru-sdk-py`).
MonadDeployer creates a token and its market in one transaction, paired with
MON, with initial liquidity set up automatically (100 BPS tick recommended for
meme tokens). Three onchain components: Orderbook contract (emits
`OrderCreated`, `OrdersCanceled`, `Trade`), margin account contract (orders
consume margin balances, not wallet balances), MM Entrypoint (EIP-7702
delegation for batched cancel/replace).

## Six weeks

| Week | Deliverable |
|---|---|
| 1 | **Task 01 delta reconstruction.** Then HyperIndex scaffold, transfers + traces ingesting. |
| 2 | Fund-flow graph. Backwards provenance walk, bounded, cached. |
| 3 | Classifiers. Address-poisoning detector (deterministic, high volume). |
| 4 | GraphQL scoring API. Backfill + evaluation run on Case B corpus. |
| 5 | Guard contract, CRE attestation workflow, Kuru listing flow. |
| 6 | Echo replay demo, evaluation writeup, polish, submission. |

## Non-negotiables

- **Deploy on mainnet, not testnet.** Fees are low enough to afford it and it
  separates you from the demo-video tier.
- **Build in public across the six weeks.** Monad's team watches; familiarity
  at judging time is worth real points.

## The demo

**Act 1 — the replay.** Echo against the live system. The block where the
detector fires. The block where the money actually left. The gap in seconds.
Then who was watching instead: an analyst on Twitter.

**Act 2 — live enforcement.** Deploy a token and market through the Kuru
listing flow. Hand it collateral with poisoned origin. Watch the guard refuse
it, on mainnet, in front of the judge.

**Act 3 — the numbers.** Precision on the address-poisoning corpus, rule stated
in full.

Nobody else in the field will demo a real incident on the judges' own chain.
