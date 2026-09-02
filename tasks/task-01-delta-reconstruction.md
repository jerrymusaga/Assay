# Task 01 — Delta Reconstruction

**Status:** not started
**Blocks:** everything else
**Estimated effort:** one afternoon, most of it spent finding contract addresses

---

## Goal

Produce one number: how many Monad blocks elapsed between the unauthorized eBTC
mint on Echo Protocol and the first WBTC borrow against it on Curvance.

Convert to wall-clock seconds at ~400ms per block.

This is a **throwaway forensic script**. It is not part of the product. Write
it, run it, record the answer in `reference/findings.md`, move on.

## Why it matters

The entire product thesis is that a machine could have detected this before the
money left. If the gap is minutes, that claim is proven against a real incident
on the judges' own chain. If the mint and the borrow shared a transaction,
there was no window and the product must be re-pitched as pre-acceptance
screening rather than real-time reaction. See `docs/05-risks.md` §1.

---

## Inputs required from the user

**Do not guess these.** Ask if missing.

- `EBTC_ADDRESS` — eBTC token contract on Monad
- `CURVANCE_MARKET_ADDRESS` — the Curvance market that accepted eBTC collateral
- Optionally `ATTACKER_ADDRESS` if already known from public reporting

Sources: Monad block explorer, Echo Protocol docs, Curvance docs, or the
PeckShield / Lookonchain public post-mortems.

**Verify before trusting:** fetch one known transaction against each address
and confirm it looks like the right contract. A plausible-looking wrong address
produces empty results that resemble a finding.

---

## Approach

Use **Envio HyperSync standalone**, not HyperIndex. This is a one-off historical
query, not a continuous indexer. HyperSync provides logs, transactions, traces
and blocks, with clients for TypeScript, Python, Rust and Go, and is documented
as up to 2000x faster than RPC for bulk historical reads.

Critically: Monad nodes prune to a few weeks of state, so a plain RPC provider
very likely **cannot** serve May 2026 data at all. HyperSync is the access path.

### Step 1 — timestamp to block

Target: **18 May 2026, 21:21 UTC**.

Blocks land roughly every 400ms (~2.5/second). Take a known reference block and
timestamp, compute an estimate, then binary-search block timestamps to land
within a few blocks of the target.

Query a generous window — ±20,000 blocks is only about two hours of chain time
and HyperSync handles it comfortably.

### Step 2 — locate the mint

Query eBTC `Transfer` logs in the window where `from == 0x0000...0000`, looking
for 1,000 units at the token's decimals.

Record: `N_mint`, transaction hash, recipient (the attacker address).

**Expected failure mode:** a bridge mint may not emit a standard zero-address
`Transfer`. If logs come back empty, **do not conclude the mint did not
happen** — re-query using **traces** instead. Native and internal value
movement does not appear in logs. Hitting this early is useful: the trace
pipeline is load-bearing for the real product.

### Step 3 — follow the attacker

Query all logs from `N_mint` forward where the attacker address appears in the
indexed topics, ordered by block.

Looking for:
- the 45 eBTC deposit into Curvance → `N_deposit`
- the ~11.29 WBTC borrow → `N_borrow`

Also pull **traces** across the same window to capture native MON movement
(gas funding, any value transfers) which will not appear in logs.

### Step 4 — compute

```
Δ_deposit = N_deposit - N_mint
Δ_borrow  = N_borrow  - N_mint

seconds ≈ Δ * 0.4
```

Also record actual block timestamps and compute the real elapsed time rather
than relying solely on the 400ms assumption.

### Step 5 — sanity check

PeckShield mapped the laundering path publicly and Lookonchain tracked the
flow. Compare your reconstructed sequence against those public accounts before
trusting your own first pass.

---

## Output

Write `reference/findings.md` containing:

- Block numbers and timestamps for mint, deposit, borrow
- Both deltas, in blocks and seconds
- The attacker address and transaction hashes
- Whether the mint appeared in logs or only in traces
- Any discrepancy against public reporting
- A one-line verdict: **window exists** / **no window**

Log intermediate results generously as the script runs. The reasoning trail
matters more than the final number.

---

## Deliverables

```
scripts/delta-reconstruction.ts
.env.example
package.json          (with an npm script to run it)
reference/findings.md (written after the run)
```

Node 22+. TypeScript, ESM, strict.

---

## Do not

- Do not scaffold the indexer, contracts or API yet.
- Do not invent addresses.
- Do not report an empty query as a finding.
- Do not build abstractions. This is one file.
