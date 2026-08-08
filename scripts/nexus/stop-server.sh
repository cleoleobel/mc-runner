#!/usr/bin/env bash
# Ordered NEXUS shutdown. Never declares success while Java is still alive.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

readonly LOG_DIR="logs"
readonly DIAG_DIR="session_diagnostics"
readonly SERVER_PID_FILE="$LOG_DIR/server.pid"
readonly PLAYIT_PID_FILE="$LOG_DIR/playit.pid"
readonly FIFO_PATH="server_stdin.fifo"

mkdir -p "$DIAG_DIR"
printf '%s\n' "UNVERIFIED" > "$DIAG_DIR/status_stop.txt"

read_pid() {
    local pid_file="$1"
    local process_id=""
    [ -f "$pid_file" ] || return 1
    process_id="$(cat "$pid_file" 2>/dev/null || true)"
    [[ "$process_id" =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' "$process_id"
}

echo "=================================================="
echo "   NEXUS ORDERED SHUTDOWN"
echo "=================================================="

SERVER_PID="$(read_pid "$SERVER_PID_FILE" || true)"
if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "[SHUTDOWN] Asking Minecraft to flush saves and stop (PID $SERVER_PID)."
    if [ -p "$FIFO_PATH" ]; then
        printf '%s\n' 'say [NEXUS] Saving the world and stopping the server.' > "$FIFO_PATH"
        sleep 2
        printf '%s\n' 'save-all flush' > "$FIFO_PATH"
        sleep 3
        printf '%s\n' 'stop' > "$FIFO_PATH"
    else
        echo "[SHUTDOWN WARN] Console FIFO missing; sending SIGINT."
        kill -SIGINT "$SERVER_PID" 2>/dev/null || true
    fi

    for _ in $(seq 1 30); do
        kill -0 "$SERVER_PID" 2>/dev/null || break
        sleep 2
    done

    if kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "[SHUTDOWN WARN] Java did not stop in 60s; sending SIGTERM."
        kill -TERM "$SERVER_PID" 2>/dev/null || true
        for _ in $(seq 1 15); do
            kill -0 "$SERVER_PID" 2>/dev/null || break
            sleep 1
        done
    fi

    if kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "[SHUTDOWN FATAL] Java is still alive. Backup is intentionally blocked."
        printf '%s\n' "FAIL" > "$DIAG_DIR/status_stop.txt"
        exit 1
    fi
fi
rm -f "$SERVER_PID_FILE"

PLAYIT_PID="$(read_pid "$PLAYIT_PID_FILE" || true)"
if [ -n "$PLAYIT_PID" ] && kill -0 "$PLAYIT_PID" 2>/dev/null; then
    echo "[SHUTDOWN] Stopping Playit agent (PID $PLAYIT_PID)."
    kill -TERM "$PLAYIT_PID" 2>/dev/null || true
    wait "$PLAYIT_PID" 2>/dev/null || true
fi
rm -f "$PLAYIT_PID_FILE" tools/bin/.playit-secret.*
rm -f "$FIFO_PATH"
sync

printf '%s\n' "PASS" > "$DIAG_DIR/status_stop.txt"
echo "[SHUTDOWN PASS] Server process ended and filesystems were synced."
