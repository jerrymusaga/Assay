#!/usr/bin/env bash
# Deploy LatencyProbe to Monad mainnet, wired to the production KeystoneForwarder.
set -euo pipefail
cd "$(dirname "$0")/.."

: "${MONAD_RPC_URL:=https://rpc.monad.xyz}"
: "${DEPLOYER_PRIVATE_KEY:?set DEPLOYER_PRIVATE_KEY in .env}"

# Chainlink production KeystoneForwarder on Monad mainnet.
# Verified onchain 2 Sep 2026 via typeAndVersion() => "KeystoneForwarder 1.0.0"
FORWARDER="${FORWARDER:-0x76c9cf548b4179F8901cda1f8623568b58215E62}"

echo "RPC       : $MONAD_RPC_URL"
echo "Forwarder : $FORWARDER"

# Refuse to deploy against a forwarder that isn't actually one.
TV=$(cast call "$FORWARDER" "typeAndVersion()(string)" --rpc-url "$MONAD_RPC_URL" 2>/dev/null || echo "")
echo "Forwarder typeAndVersion: ${TV:-<none>}"
case "$TV" in
  *KeystoneForwarder*) ;;
  *) echo "ABORT: $FORWARDER is not a KeystoneForwarder on this chain." >&2; exit 1 ;;
esac

forge build >/dev/null
echo "Deploying LatencyProbe..."
forge create contracts/evm/src/LatencyProbe.sol:LatencyProbe \
  --rpc-url "$MONAD_RPC_URL" \
  --private-key "$DEPLOYER_PRIVATE_KEY" \
  --broadcast \
  --constructor-args "$FORWARDER" \
  | tee /tmp/assay-deploy.log

ADDR=$(grep -oE 'Deployed to: 0x[0-9a-fA-F]{40}' /tmp/assay-deploy.log | awk '{print $3}')
echo
echo "LatencyProbe deployed at: $ADDR"
echo
echo "Next: put it in probe/config.production.json"
echo "  probeContractAddress = $ADDR"
