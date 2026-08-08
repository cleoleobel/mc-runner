#!/usr/bin/env bash
# Create a verified, immutable NEXUS state snapshot after a confirmed stop.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

readonly BACKUP_DIR="backups_staging"
readonly DIAG_DIR="session_diagnostics"
readonly TEMP_BACKUP="$BACKUP_DIR/new-world-staging.tar.gz"

mkdir -p "$BACKUP_DIR" "$DIAG_DIR"
printf '%s\n' "UNVERIFIED" > "$DIAG_DIR/status_backup.txt"

RUN_NUMBER="${GITHUB_RUN_NUMBER:-manual}"
RUN_NUMBER="${RUN_NUMBER//[^A-Za-z0-9._-]/_}"
CREATED_AT="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

echo "=================================================="
echo "   NEXUS VERIFIED STATE BACKUP"
echo "   Run: $RUN_NUMBER | UTC: $CREATED_AT"
echo "=================================================="

if [ "${GITHUB_ACTIONS:-false}" = "true" ]; then
    SERVER_STATUS="$(cat "$DIAG_DIR/status_server.txt" 2>/dev/null || true)"
    STOP_STATUS="$(cat "$DIAG_DIR/status_stop.txt" 2>/dev/null || true)"
    if [ "$SERVER_STATUS" != "ONLINE" ] || [ "$STOP_STATUS" != "PASS" ]; then
        echo "[BACKUP ERROR] Refusing remote promotion after an unhealthy session."
        echo "[BACKUP ERROR] server=$SERVER_STATUS stop=$STOP_STATUS"
        printf '%s\n' "FAIL" > "$DIAG_DIR/status_backup.txt"
        exit 1
    fi
fi

if [ ! -f world/level.dat ]; then
    echo "[BACKUP ERROR] world/level.dat does not exist. Refusing an empty snapshot."
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_backup.txt"
    exit 1
fi

if [ -f logs/server.pid ]; then
    SERVER_PID="$(cat logs/server.pid 2>/dev/null || true)"
    if [[ "$SERVER_PID" =~ ^[0-9]+$ ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "[BACKUP ERROR] Java PID $SERVER_PID is still alive; a consistent snapshot is impossible."
        printf '%s\n' "FAIL" > "$DIAG_DIR/status_backup.txt"
        exit 1
    fi
fi

BACKUP_ITEMS=(world)
for state_file in whitelist.json ops.json banned-ips.json banned-players.json usercache.json; do
    if [ -f "$state_file" ]; then
        BACKUP_ITEMS+=("$state_file")
    fi
done

sync
rm -f "$TEMP_BACKUP"
echo "[BACKUP] Archiving: ${BACKUP_ITEMS[*]}"
tar -czf "$TEMP_BACKUP" -- "${BACKUP_ITEMS[@]}"

if ! tar -tzf "$TEMP_BACKUP" >/dev/null 2>&1; then
    echo "[BACKUP ERROR] Generated tarball failed its integrity test."
    rm -f "$TEMP_BACKUP"
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_backup.txt"
    exit 1
fi
if ! tar -tzf "$TEMP_BACKUP" | grep -E '^\.?/?world/level\.dat$' >/dev/null; then
    echo "[BACKUP ERROR] Generated tarball does not contain world/level.dat."
    rm -f "$TEMP_BACKUP"
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_backup.txt"
    exit 1
fi

HASH="$(sha256sum "$TEMP_BACKUP" | awk '{print $1}')"
HISTORICAL_NAME="world-run-${RUN_NUMBER}-${HASH}.tar.gz"
cp "$TEMP_BACKUP" "$BACKUP_DIR/$HISTORICAL_NAME"

cat << EOF > "$BACKUP_DIR/backup-info.json"
{
  "format_version": 2,
  "run_id": "$RUN_NUMBER",
  "created_at": "$CREATED_AT",
  "asset": "$HISTORICAL_NAME",
  "sha256": "$HASH",
  "includes": ["world", "whitelist.json", "ops.json", "banned-ips.json", "banned-players.json", "usercache.json"]
}
EOF

printf '%s\n' "PASS" > "$DIAG_DIR/status_backup.txt"
echo "[BACKUP PASS] $BACKUP_DIR/$HISTORICAL_NAME"
