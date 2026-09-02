# 05 — Risks

Ordered by how badly each one hurts.

## 1. The delta is zero — PROJECT-DEFINING

If the eBTC mint and the Curvance borrow happened in the same transaction,
there was never a reaction window and no real-time system could have helped.

**Mitigation:** run `tasks/task-01-delta-reconstruction.md` in week 1, before
building anything.

**If it happens:** the product shifts from *reaction* to *pre-acceptance
screening* — the guard consults a verdict computed on the *asset and its mint
history* rather than reacting to a live event. Still viable, different pitch,
and the demo changes from "we were faster" to "we would have refused it".
Know this in week one, not week five.

## 2. False positives

An alert system that cries wolf gets muted within a week, and a guard that
refuses legitimate collateral gets uninstalled the same day.

**Mitigation:** deterministic rules only. No ML, no inferred threat scoring.
Every verdict carries a human-readable reason string. Automated *blocking* is
scoped to the highest-precision rules (fresh mint, address poisoning);
everything else is alert-only.

## 3. Fungibility undermines "these specific tokens"

Tracing "the same tokens" through a pooled balance is a fiction. Any accounting
convention is a choice, not a truth.

**Mitigation:** pick FIFO on the receiving address's balance, state it
explicitly in the docs and the pitch, and be ready to defend it as a
convention rather than a fact. Judges respect a named limitation more than a
glossed one.

## 4. No protocol grants pause authority to a hackathon project

Real, and pretending otherwise is worse than admitting it.

**Mitigation:** ship as a self-hosted guard module with open detection rules.
Demo against a market you deployed yourself via Kuru's MonadDeployer. Say this
out loud in the pitch.

## 5. N=1 on protocol-level incidents

One Echo is a story, not a validation.

**Mitigation:** the address-poisoning corpus carries the statistical weight.
Present two detectors with two evidence bases; never merge them into one
accuracy claim.

## 6. Small addressable market today

Monad is ~9 months old. Kuru and Curvance are roughly the Monad-native DeFi
layer; the rest are deployments of Uniswap, Curve, Morpho, Aave, Euler,
Gearbox. TVL has been cooling with net bridge outflows.

**Mitigation:** frame as incumbency plus an unbackfillable history moat. Note
Monad's ~38.5% ecosystem/grants allocation as the realistic post-hackathon
funding path.

## 7. Scope creep

Four tempting adjacent products: agent provenance, Perpl wash trading,
multi-chain, ML scoring. Each is genuinely good. Each costs you the core.

**Mitigation:** the "not shipping" list in `01-product.md` is a commitment, not
a preference. Revisit only in week 5, and only if the core is airtight.

## 8. Adversarial disclosure

Publishing detection rules publishes an evasion manual.

**Mitigation:** open rules are a deliberate choice for a hackathon (auditability
beats obscurity at this stage), but have the answer ready and note which
signals are inherently hard to evade — a fresh mint cannot be aged, and a
funding ancestor cannot be un-shared without cost.

## 9. Existing competitors

Forta, OpenZeppelin Defender, Tenderly Alerts, Hypernative.

**Mitigation:** differentiate on lineage-vs-behaviour and Monad-native retained
history. Do not claim the category is empty.
