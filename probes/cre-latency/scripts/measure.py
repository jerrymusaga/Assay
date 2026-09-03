#!/usr/bin/env python3
"""
Measure Chainlink CRE end-to-end write latency on Monad mainnet.

Fires N ping() transactions against the deployed LatencyProbe and waits for the
DON's report to land back onchain, recording the block and second gap for each.

Both timestamps come from the same contract on the same chain, so there is no
clock skew to argue about.

Usage:
  DEPLOYER_PRIVATE_KEY=0x.. PROBE_ADDRESS=0x.. python3 scripts/measure.py [samples]
"""
import json, os, subprocess, sys, time, statistics

RPC = os.environ.get("MONAD_RPC_URL", "https://rpc.monad.xyz")
PROBE = os.environ.get("PROBE_ADDRESS")
PK = os.environ.get("DEPLOYER_PRIVATE_KEY")
N = int(sys.argv[1]) if len(sys.argv) > 1 else 5
TIMEOUT = int(os.environ.get("SAMPLE_TIMEOUT", "300"))

if not PROBE or not PK:
    sys.exit("set PROBE_ADDRESS and DEPLOYER_PRIVATE_KEY")

def cast(*args):
    r = subprocess.run(["cast", *args, "--rpc-url", RPC],
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip()[:300])
    return r.stdout.strip()

def get_sample(seq):
    out = cast("call", PROBE, "getSample(uint256)(uint64,uint64,uint64,uint64,bool,uint64,uint64)", str(seq))
    parts = [p.strip().split()[0] for p in out.splitlines() if p.strip()]
    tb, tt, wb, wt, done, bd, sd = parts
    return dict(triggerBlock=int(tb), triggerTime=int(tt), writeBlock=int(wb),
                writeTime=int(wt), complete=done.lower() == "true",
                blockDelta=int(bd), secondsDelta=int(sd))

print(f"probe   : {PROBE}")
print(f"rpc     : {RPC}")
print(f"samples : {N}\n")

results = []
for i in range(1, N + 1):
    print(f"[{i}/{N}] ping()...", flush=True)
    subprocess.run(["cast", "send", PROBE, "ping()", "--rpc-url", RPC,
                    "--private-key", PK, "--json"],
                   capture_output=True, text=True, check=True)
    seq = int(cast("call", PROBE, "seq()(uint256)").split()[0])
    print(f"      seq={seq}, waiting for CRE report (timeout {TIMEOUT}s)...", flush=True)

    t0 = time.time()
    got = None
    while time.time() - t0 < TIMEOUT:
        s = get_sample(seq)
        if s["complete"]:
            got = s
            break
        time.sleep(2)

    if not got:
        print(f"      TIMEOUT after {TIMEOUT}s — no report landed\n")
        results.append(None)
        continue

    wall = time.time() - t0
    print(f"      trigger blk {got['triggerBlock']:,} -> write blk {got['writeBlock']:,}")
    print(f"      Δ {got['blockDelta']} blocks / {got['secondsDelta']}s onchain  (wall {wall:.1f}s)\n")
    results.append(got)

ok = [r for r in results if r]
print("=" * 58)
print(f"completed {len(ok)}/{N}")
if ok:
    bd = [r["blockDelta"] for r in ok]
    sd = [r["secondsDelta"] for r in ok]
    print(f"  blocks   min={min(bd)}  median={statistics.median(bd):.0f}  max={max(bd)}")
    print(f"  seconds  min={min(sd)}  median={statistics.median(sd):.0f}  max={max(sd)}")
    print()
    print(f"  Echo detection window was 50s (role grant -> borrow).")
    worst = max(sd)
    print(f"  worst observed CRE round trip: {worst}s")
    print(f"  -> {'FITS' if worst < 50 else 'DOES NOT FIT'} inside the window"
          f" ({50 - worst}s margin)" if worst < 50 else "")
json.dump([r for r in results], open("latency-results.json", "w"), indent=2)
print("\nwrote latency-results.json")
