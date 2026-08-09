#!/usr/bin/env bash
# Compatibility entry point. The old RAM-disk/infinite-loop launcher bypassed
# the verified Playit, shutdown and persistence safeguards.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "[NEXUS] Delegating legacy entry point to scripts/nexus/start-server.sh."
exec bash scripts/nexus/start-server.sh "${1:-run-server}"
