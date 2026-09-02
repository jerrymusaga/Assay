# 01 — Product

## One line

Assay maintains a continuous fund-flow graph of Monad, walks it backwards from
any incoming deposit, classifies the origin, and publishes a verdict onchain
that a guard contract enforces before value is accepted.

## User stories

### The protocol (primary customer)

> I run a lending market on Monad. I want to list more assets, but every asset
> I list is a way for someone to hand me worthless collateral and walk off with
> real value. I install the Assay guard in front of my market, choose which
> assets to screen, and set a threshold. Deposits now carry an origin verdict.
> Collateral that was minted from nothing five minutes ago is refused before I
> lend against it.

**Integration surface:** deploy guard, register screened assets, set threshold.
Everything hard lives on Assay's side.

**Named real instance:** Curvance. Monad-native, live, took the actual $816K
loss in the Echo incident.

### The venue (second customer)

> I run an order book that wants to support long-tail assets. Most new tokens
> are garbage and I cannot vet them at listing speed. New markets get created
> through a flow that screens the deployer and the initial liquidity, so I can
> open listing wider without carrying the whole downside.

**Named real instance:** Kuru. Its SDK includes a MonadDeployer that creates a
token and its market in one transaction, pairs with MON, and sets up initial
liquidity — recommended at 100 BPS tick size for meme tokens. Kuru has stated
it wants to support long-tail assets while keeping liquidity provision simple.

### The watcher (secondary, free tier)

> I hold a position in a market. Something anomalous originates upstream of an
> asset I'm exposed to. I get told in seconds, not when someone notices on
> Twitter.

Telegram / Discord alerts. Onboarding is a wallet address. This is the growth
surface and the post-hackathon distribution channel.

## Detection classes

**In scope — illegitimate value entering a system:**

| Class | Signal | Determinism |
|---|---|---|
| Unbacked / fraudulent mint | Supply anomaly with no backing event | High |
| Stolen funds being placed | Origin traces to a flagged exploit path | High |
| Fresh-contract risk | Token or deployer contract minutes/hours old | Deterministic |
| Coordinated funding | N "independent" addresses share a funding ancestor | Deterministic |
| Address poisoning | Vanity address collision + unsolicited dust | Deterministic |

**Explicitly out of scope:** oracle manipulation, reentrancy, flash loans,
logic bugs, governance attacks. In all of these the attacker's funds have clean
origin — the mechanism was abused, not the money.

## Scope discipline

**Not shipping in six weeks, and each for a specific reason:**

- **ML anomaly detection** — false positives kill an alerting product, and you
  cannot validate a model in this timeframe. Deterministic rules only.
- **The agent-facing product** (provenance checks for delegated agent spending)
  — genuinely a second product with a different customer, integration surface
  and pitch. Shares only the engine. Month three, not week five.
- **Perpl integration** — the wash-trading detector is real and uses the same
  funding-graph engine, but it is a second data pipeline and pulls the pitch
  toward trading analytics. Stretch goal for week five; drop without guilt.
- **Multi-chain** — the moat is Monad-specific history.

## Business reality

Monad is nine months old with a thin native protocol set — Kuru and Curvance
are essentially the Monad-native DeFi layer, with the rest being deployments of
Uniswap, Curve, Morpho, Aave, Euler, Gearbox. The number of protocols that
would buy this *today* is small.

That cuts both ways. Small market now, but incumbency as the ecosystem grows,
and the indexed history accumulated from day one is something a later
competitor cannot backfill.

Monad has ~38.5% of MON supply earmarked for ecosystem development and grants.
Security infrastructure is fundable after a hackathon ends.

## Competitive honesty

Forta, OpenZeppelin Defender, Tenderly Alerts and Hypernative exist. Two
differentiators, both real:

1. **Lineage, not behavioural anomaly.** They score behaviour. Assay traces
   origin. Different question.
2. **Monad-native coverage with retained history.** None of them serve Monad
   retail, and all are priced for enterprises.

Do not pretend the category is empty. Say what is different.
