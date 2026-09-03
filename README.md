# Assay

**Provenance screening for onchain value on Monad.**

Assay answers one question at the moment it matters: *where did these specific
tokens come from, and is that origin sound?*

Protocols that accept assets they did not issue — lending markets, order books,
vaults, bridges — cannot see lineage. They see a balance arrive and treat it as
real. Assay maintains a continuous fund-flow graph of Monad, walks it backwards
from any deposit, classifies the origin, and publishes a verdict onchain that a
guard contract can enforce.

Built for the Monad **Metropolis** hackathon (1 Sep – 13 Oct 2026), Track 04:
Trust, Identity & AI Infrastructure.

---

## Read these in order

| File | What it covers |
|---|---|
| `docs/00-thesis.md` | The problem, the evidence, why this is necessary |
| `docs/01-product.md` | What the product is, user stories, what it does NOT do |
| `docs/02-architecture.md` | Four layers, data flow, component responsibilities |
| `docs/03-evidence.md` | The Echo incident, address poisoning, evaluation corpus |
| `docs/05-risks.md` | Open risks and what kills the project |
| `tasks/task-01-delta-reconstruction.md` | **START HERE.** The first thing to build. |

## Current status

**Week 1 complete. Every question that could have killed the project is closed.**

Task 01 (delta reconstruction) is done. The Echo incident has been fully
reconstructed from Monad mainnet data, and the reaction window is real:

| Finding | Result |
|---|---|
| Detection window (first hard signal → funds leave) | **50 seconds** (123 blocks) |
| Historical data availability | Full history from block 0, traces included |
| Detector precision, full-chain replay | **1 firing across 25,873 events / 5,537 contracts** — and it is the Echo attack |
| Chainlink CRE on Monad mainnet | Live for production onchain writes |

The project-killing scenario in `docs/05-risks.md` §1 — mint and borrow in the
same transaction — **did not happen**. There was a window, and it is roughly
25× wider than the detect-and-publish budget.

Detailed forensics, the evaluation methodology, and the stated limits of both
are held in a working set that is not yet public.

### Next

Build the detector against the reconstructed incident, then the guard and the
CRE attestation path. Measure real CRE write latency before quoting it.

## Stack

- **Envio HyperSync** — standalone client for the forensic reconstruction
- **Envio HyperIndex** — the continuous indexer for the product
- **Monad mainnet** — chain ID 143, ~400ms blocks, ~800ms finality
- **Chainlink CRE** — publishes provenance verdicts onchain
- **Foundry** — guard contract
- **TypeScript / Node 22+** throughout
