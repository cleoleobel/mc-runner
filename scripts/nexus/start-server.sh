#!/usr/bin/env bash
# NEXUS Forge 1.20.1 launcher for the ephemeral GitHub Actions runner.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

readonly LOG_DIR="logs"
readonly DIAG_DIR="session_diagnostics"
readonly SERVER_LOG="$LOG_DIR/latest.log"
readonly FIFO_PATH="server_stdin.fifo"
readonly NEXUS_DATAPACK_SOURCE="src/datapacks/nexus_progression"
readonly NEXUS_DATAPACK_TARGET="world/datapacks/nexus_progression"

mkdir -p "$LOG_DIR" "$DIAG_DIR"
printf '%s\n' "STARTING" > "$DIAG_DIR/status_server.txt"
printf '%s\n' "UNVERIFIED" > "$DIAG_DIR/status_runtime_errors.txt"

OPERATION="${1:-run-server}"
SESSION_MINUTES="${SESSION_MINUTES:-325}"

if ! [[ "$SESSION_MINUTES" =~ ^[0-9]+$ ]] || [ "$SESSION_MINUTES" -lt 1 ]; then
    echo "[SESSION ERROR] SESSION_MINUTES must be a positive integer."
    exit 1
fi
if [ "$SESSION_MINUTES" -gt 330 ]; then
    echo "[SESSION ERROR] SESSION_MINUTES=$SESSION_MINUTES exceeds the safe 330-minute ceiling."
    exit 1
fi

case "$OPERATION" in
    run-server|validate|pregen) ;;
    *) echo "[OPERATION ERROR] Unsupported operation: $OPERATION"; exit 1 ;;
esac

update_server_property() {
    local key="$1"
    local value="$2"
    if grep -q "^${key}=" server.properties; then
        sed -i "s|^${key}=.*|${key}=${value}|" server.properties
    else
        # A few historical bundles ended server.properties without a final
        # newline. Ensure an appended key never becomes part of the last value.
        if [ -s server.properties ] && [ "$(tail -c 1 server.properties | wc -l)" -eq 0 ]; then
            printf '\n' >> server.properties
        fi
        printf '%s=%s\n' "$key" "$value" >> server.properties
    fi
}

set_forge_boolean_false() {
    local file="$1"
    local key="$2"
    local temp_file=""

    if grep -q "^[[:space:]]*${key}[[:space:]]*=" "$file"; then
        sed -i -E "s/^[[:space:]]*${key}[[:space:]]*=.*/\t${key} = false/" "$file"
        return
    fi

    temp_file="$(mktemp "${file}.XXXXXX")"
    awk -v wanted_key="$key" '
        /^\[general\][[:space:]]*$/ && !inserted {
            print
            printf "\t%s = false\n", wanted_key
            inserted = 1
            next
        }
        { print }
        END {
            if (!inserted) {
                print ""
                print "[general]"
                printf "\t%s = false\n", wanted_key
            }
        }
    ' "$file" > "$temp_file"
    mv "$temp_file" "$file"
}

audit_runtime_log() {
    local error_count=0

    if [ ! -f "$SERVER_LOG" ]; then
        echo "[LOG AUDIT ERROR] $SERVER_LOG does not exist."
        printf '%s\n' "FAIL" > "$DIAG_DIR/status_runtime_errors.txt"
        return 1
    fi

    error_count="$(grep -Ec '\[[^]]+/ERROR\]' "$SERVER_LOG" || true)"
    if [ "$error_count" -gt 0 ]; then
        echo "[LOG AUDIT ERROR] Forge emitted $error_count ERROR entries:"
        grep -E '\[[^]]+/ERROR\]' "$SERVER_LOG" \
            | sed -E 's/^\[[^]]+\][[:space:]]*//' \
            | sort | uniq -c | sort -nr | head -n 50
        printf '%s\n' "FAIL" > "$DIAG_DIR/status_runtime_errors.txt"
        return 1
    fi

    printf '%s\n' "PASS" > "$DIAG_DIR/status_runtime_errors.txt"
    echo "[LOG AUDIT PASS] Forge emitted no ERROR entries."
}

echo "=================================================="
echo "   NEXUS FORGE 1.20.1 - $OPERATION"
echo "=================================================="

# Keep native memory headroom for Forge, Netty, compression and the OS.
TOTAL_RAM_MB="$(free -m | awk '/^Mem:/{print $2}')"
if [ "$TOTAL_RAM_MB" -ge 14000 ]; then
    XMX="10G"
    XMS="4G"
elif [ "$TOTAL_RAM_MB" -ge 7000 ]; then
    XMX="5G"
    XMS="3G"
else
    XMX="3G"
    XMS="2G"
fi

echo "[JVM] RAM=${TOTAL_RAM_MB}MB; heap -Xms${XMS} -Xmx${XMX}."
cat << EOF > user_jvm_args.txt
-Xms${XMS}
-Xmx${XMX}
-XX:+UseG1GC
-XX:+ParallelRefProcEnabled
-XX:MaxGCPauseMillis=200
-XX:+DisableExplicitGC
-XX:+AlwaysPreTouch
-XX:+PerfDisableSharedMem
-XX:+UseStringDeduplication
-XX:+ExitOnOutOfMemoryError
-Xlog:gc*:file=logs/gc.log:time,uptime,level,tags:filecount=5,filesize=20M
EOF

printf '%s\n' "eula=true" > eula.txt

if [ -f "scripts/network/playit.sh" ]; then
    if ! bash scripts/network/playit.sh; then
        if [ "$OPERATION" = "run-server" ]; then
            echo "[PLAYIT FATAL] Public session aborted without verified TCP and UDP tunnels."
            exit 1
        fi
        echo "[PLAYIT WARN] Network verification failed during local operation '$OPERATION'."
    fi
fi

rm -f "$FIFO_PATH"
mkfifo "$FIFO_PATH"
exec 3<> "$FIFO_PATH"

if [ ! -f server.properties ]; then
    : > server.properties
fi

NEXUS_ONLINE_MODE="${NEXUS_ONLINE_MODE:-true}"
if [ "$NEXUS_ONLINE_MODE" != "true" ] && [ "$NEXUS_ONLINE_MODE" != "false" ]; then
    echo "[SECURITY ERROR] NEXUS_ONLINE_MODE must be true or false."
    exit 1
fi
if [ "$NEXUS_ONLINE_MODE" = "false" ]; then
    echo "[SECURITY WARN] Offline mode allows username impersonation."
fi

update_server_property "online-mode" "$NEXUS_ONLINE_MODE"
update_server_property "enable-rcon" "false"
update_server_property "rcon.password" ""
update_server_property "view-distance" "${NEXUS_VIEW_DISTANCE:-6}"
update_server_property "simulation-distance" "${NEXUS_SIMULATION_DISTANCE:-4}"
update_server_property "entity-broadcast-range-percentage" "${NEXUS_ENTITY_RANGE_PERCENT:-50}"
update_server_property "network-compression-threshold" "${NEXUS_COMPRESSION_THRESHOLD:-512}"

# Preserve nexus-core as the targeted vaccine. Forge must not silently delete
# a mod entity or block entity when an unrelated exception occurs.
mkdir -p world/serverconfig
FORGE_SERVER_CONFIG="world/serverconfig/forge-server.toml"
if [ ! -f "$FORGE_SERVER_CONFIG" ]; then
    cat << 'EOF' > "$FORGE_SERVER_CONFIG"
[general]
	removeErroringEntities = false
	removeErroringBlockEntities = false
EOF
else
    set_forge_boolean_false "$FORGE_SERVER_CONFIG" "removeErroringEntities"
    set_forge_boolean_false "$FORGE_SERVER_CONFIG" "removeErroringBlockEntities"
fi

# Install the repository-owned datapack after restoring the world. World packs
# override mod-provided data, allowing NEXUS to repair malformed third-party
# loot tables without modifying or redistributing their JARs.
if [ ! -f "$NEXUS_DATAPACK_SOURCE/pack.mcmeta" ]; then
    echo "[DATAPACK ERROR] Missing $NEXUS_DATAPACK_SOURCE/pack.mcmeta."
    exit 1
fi
mkdir -p "$(dirname "$NEXUS_DATAPACK_TARGET")"
rm -rf "$NEXUS_DATAPACK_TARGET"
cp -a "$NEXUS_DATAPACK_SOURCE" "$NEXUS_DATAPACK_TARGET"
echo "[DATAPACK PASS] Installed file/nexus_progression into the restored world."

# The signed/checksummed bundle is the only source of runtime mods. Downloading
# jars during every boot made deployments non-reproducible and bypassed review.
if find mods -maxdepth 1 -type f -iname '*radium*.jar' -print -quit 2>/dev/null | grep -q .; then
    echo "[MOD ERROR] Radium is prohibited for this Cataclysm/Citadel pack."
    exit 1
fi
if ! find mods -maxdepth 1 -type f -iname '*ferritecore*.jar' -print -quit 2>/dev/null | grep -q .; then
    echo "[OPTIMIZER WARN] FerriteCore is absent from the verified bundle."
fi
if ! find mods -maxdepth 1 -type f -iname '*modernfix*.jar' -print -quit 2>/dev/null | grep -q .; then
    echo "[OPTIMIZER WARN] ModernFix is absent from the verified bundle."
fi

if [ ! -f run.sh ]; then
    echo "[MINECRAFT ERROR] run.sh is missing from the verified bundle."
    exit 1
fi
chmod +x run.sh
: > "$SERVER_LOG"

echo "[MINECRAFT] Starting Forge..."
./run.sh nogui < "$FIFO_PATH" > >(tee -a "$SERVER_LOG") 2>&1 &
SERVER_PID=$!
printf '%s\n' "$SERVER_PID" > "$LOG_DIR/server.pid"
echo "[MINECRAFT] Java PID: $SERVER_PID"

BOOT_TIMEOUT=300
ELAPSED=0
BOOTED=false
while [ "$ELAPSED" -lt "$BOOT_TIMEOUT" ]; do
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "[CRASH FATAL] Forge stopped before completing startup."
        tail -n 80 "$SERVER_LOG" || true
        printf '%s\n' "CRASHED" > "$DIAG_DIR/status_server.txt"
        exit 1
    fi

    if grep -qE 'Done \([0-9]+\.[0-9]+s\)!|Done \([0-9]+\.[0-9]+s\)' "$SERVER_LOG"; then
        BOOTED=true
        printf '%s\n' "ONLINE" > "$DIAG_DIR/status_server.txt"
        echo "[MINECRAFT SUCCESS] Forge reached Done in ${ELAPSED}s."
        break
    fi
    sleep 3
    ELAPSED=$((ELAPSED + 3))
done

if [ "$BOOTED" != "true" ]; then
    echo "[TIMEOUT ERROR] Forge did not reach Done within ${BOOT_TIMEOUT}s."
    tail -n 80 "$SERVER_LOG" || true
    printf '%s\n' "TIMEOUT" > "$DIAG_DIR/status_server.txt"
    exit 1
fi

HEALTHY=false
if [ -f "scripts/nexus/healthcheck.sh" ]; then
    for _ in $(seq 1 5); do
        if bash scripts/nexus/healthcheck.sh; then
            HEALTHY=true
            break
        fi
        sleep 2
    done
else
    echo "[HEALTHCHECK ERROR] scripts/nexus/healthcheck.sh is missing."
fi

if [ "$HEALTHY" != "true" ]; then
    if [ "$OPERATION" = "run-server" ]; then
        echo "[HEALTHCHECK FATAL] Public session aborted because TCP/UDP readiness is incomplete."
        exit 1
    fi
    echo "[HEALTHCHECK WARN] Readiness incomplete during '$OPERATION'."
fi

if ! audit_runtime_log; then
    echo "[LOG AUDIT FATAL] Public startup is not clean."
    exit 1
fi

if [ "$OPERATION" = "validate" ]; then
    echo "[VALIDATE] Boot validation completed; stopping cleanly."
    bash scripts/nexus/stop-server.sh
    exit 0
fi

if [ "$OPERATION" = "pregen" ]; then
    PREGEN_RADIUS="${PREGEN_RADIUS:-500}"
    echo "[PREGEN] Starting Chunky radius $PREGEN_RADIUS."
    printf '%s\n' "chunky radius $PREGEN_RADIUS" > "$FIFO_PATH"
    sleep 2
    printf '%s\n' "chunky start" > "$FIFO_PATH"
    sleep 120
    printf '%s\n' "save-all" > "$FIFO_PATH"
    sleep 10
    bash scripts/nexus/stop-server.sh
    exit 0
fi

echo "[SESSION] Public server online for at most ${SESSION_MINUTES} minutes."
SESSION_SECONDS=$((SESSION_MINUTES * 60))
WARN_5M=$((SESSION_SECONDS - 300))
WARN_1M=$((SESSION_SECONDS - 60))
ELAPSED_SESSION=0
SERVER_EXITED=false

while [ "$ELAPSED_SESSION" -lt "$SESSION_SECONDS" ]; do
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "[SERVER ERROR] Java exited during the public session."
        printf '%s\n' "CRASHED" > "$DIAG_DIR/status_server.txt"
        SERVER_EXITED=true
        break
    fi

    if [ "$ELAPSED_SESSION" -eq "$WARN_5M" ] && [ "$WARN_5M" -gt 0 ]; then
        printf '%s\n' 'say [NEXUS] Restart in 5 minutes; world backup will follow.' > "$FIFO_PATH"
    fi
    if [ "$ELAPSED_SESSION" -eq "$WARN_1M" ] && [ "$WARN_1M" -gt 0 ]; then
        printf '%s\n' 'say [NEXUS] Restart in 1 minute; please finish current actions.' > "$FIFO_PATH"
    fi
    if [ $((ELAPSED_SESSION % 300)) -eq 0 ] && [ "$ELAPSED_SESSION" -gt 0 ]; then
        echo "[KEEP-ALIVE] $((ELAPSED_SESSION / 60)) minutes elapsed."
    fi

    sleep 15
    ELAPSED_SESSION=$((ELAPSED_SESSION + 15))
done

echo "[SESSION] Stopping and syncing before the persistence stage."
bash scripts/nexus/stop-server.sh

if [ "$SERVER_EXITED" = "true" ]; then
    exit 1
fi

if ! audit_runtime_log; then
    exit 1
fi
