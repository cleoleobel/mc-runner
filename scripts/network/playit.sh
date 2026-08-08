#!/usr/bin/env bash
# NEXUS network layer: verified Playit agent + Simple Voice Chat endpoint wiring.

set -euo pipefail

readonly PLAYIT_VERSION="0.17.1"
readonly LOG_DIR="logs"
readonly DIAG_DIR="session_diagnostics"
readonly BINARY_DIR="tools/bin"
readonly PLAYIT_BIN="$BINARY_DIR/playit"
readonly PLAYIT_LOG="$LOG_DIR/playit.log"
readonly VOICE_CONFIG="config/voicechat/voicechat-server.properties"

mkdir -p "$LOG_DIR" "$DIAG_DIR" "$BINARY_DIR" "$(dirname "$VOICE_CONFIG")"

for status in playit_secret playit_agent minecraft_tunnel voice_tunnel svc_config voice_udp_socket; do
    printf '%s\n' "UNVERIFIED" > "$DIAG_DIR/status_${status}.txt"
done

echo "=================================================="
echo "   NEXUS NETWORK LAYER - PLAYIT.GG"
echo "=================================================="

update_property() {
    local file="$1"
    local key="$2"
    local value="$3"

    if [ ! -f "$file" ]; then
        : > "$file"
    fi

    if grep -q "^[[:space:]]*${key}[[:space:]]*=" "$file"; then
        sed -i "s|^[[:space:]]*${key}[[:space:]]*=.*|${key}=${value}|" "$file"
    else
        printf '%s=%s\n' "$key" "$value" >> "$file"
    fi
}

plain_playit_log() {
    # Playit can emit ANSI sequences even when stdout is redirected.
    sed -E $'s/\\x1B\\[[0-9;?]*[ -/]*[@-~]//g' "$PLAYIT_LOG" 2>/dev/null || true
}

mapping_endpoint() {
    local local_port="$1"
    plain_playit_log \
        | grep -E "=>[[:space:]]+(127\\.0\\.0\\.1|localhost):${local_port}([[:space:]]|$)" \
        | grep -oE '([A-Za-z0-9-]+\.)+(playit\.gg|ply\.gg)(:[0-9]+)?' \
        | head -n 1 \
        || true
}

is_public_endpoint() {
    local endpoint="$1"
    [ -n "$endpoint" ] \
        && [[ "$endpoint" =~ ^([A-Za-z0-9-]+\.)+(playit\.gg|ply\.gg)(:[0-9]+)?$ ]] \
        && [[ ! "$endpoint" =~ ^(localhost|127\.|0\.0\.0\.0|\[?::1\]?) ]]
}

# SVC must listen on all container/runner interfaces. voice_host is populated only
# after the matching public UDP tunnel has been observed in the Playit log.
update_property "$VOICE_CONFIG" "port" "24454"
update_property "$VOICE_CONFIG" "bind_address" "*"
update_property "$VOICE_CONFIG" "codec" "VOIP"
update_property "$VOICE_CONFIG" "voice_host" ""

if [ -z "${PLAYIT_SECRET:-}" ]; then
    echo "[PLAYIT ERROR] PLAYIT_SECRET is required for a public NEXUS session."
    printf '%s\n' "NOT_CONFIGURED" > "$DIAG_DIR/status_playit_secret.txt"
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_playit_agent.txt"
    exit 1
fi
printf '%s\n' "PASS" > "$DIAG_DIR/status_playit_secret.txt"

case "$(uname -m)" in
    x86_64|amd64)
        PLAYIT_ASSET="playit-linux-amd64"
        PLAYIT_SHA256="e78d463d93aa1e3ec36a06ded5a1f4fe879905fdceb865df8f4cef6124f8a555"
        ;;
    aarch64|arm64)
        PLAYIT_ASSET="playit-linux-aarch64"
        PLAYIT_SHA256="cd3fa1cedac40a71d80a120e6353e08836308840340b58e659e8f25d00601f66"
        ;;
    *)
        echo "[PLAYIT ERROR] Unsupported architecture: $(uname -m)"
        printf '%s\n' "FAIL" > "$DIAG_DIR/status_playit_agent.txt"
        exit 1
        ;;
esac

download_playit() {
    local temp_binary="$PLAYIT_BIN.download"
    local url="https://github.com/playit-cloud/playit-agent/releases/download/v${PLAYIT_VERSION}/${PLAYIT_ASSET}"

    rm -f "$temp_binary"
    echo "[PLAYIT] Downloading official agent v${PLAYIT_VERSION} for $(uname -m)..."
    curl --fail --show-error --silent --location --retry 3 --retry-all-errors \
        --proto '=https' --tlsv1.2 "$url" --output "$temp_binary"
    printf '%s  %s\n' "$PLAYIT_SHA256" "$temp_binary" | sha256sum --check --strict
    install -m 0755 "$temp_binary" "$PLAYIT_BIN"
    rm -f "$temp_binary"
}

if [ -x "$PLAYIT_BIN" ]; then
    INSTALLED_SHA256="$(sha256sum "$PLAYIT_BIN" | awk '{print $1}')"
else
    INSTALLED_SHA256=""
fi

if [ "$INSTALLED_SHA256" != "$PLAYIT_SHA256" ]; then
    download_playit
else
    echo "[PLAYIT] Verified cached agent v${PLAYIT_VERSION}."
fi

if [ -f "$LOG_DIR/playit.pid" ]; then
    OLD_PLAYIT_PID="$(cat "$LOG_DIR/playit.pid" 2>/dev/null || true)"
    if [[ "$OLD_PLAYIT_PID" =~ ^[0-9]+$ ]] && kill -0 "$OLD_PLAYIT_PID" 2>/dev/null; then
        echo "[PLAYIT ERROR] An existing Playit process is still running (PID $OLD_PLAYIT_PID)."
        exit 1
    fi
    rm -f "$LOG_DIR/playit.pid"
fi

# Use a mode-0600 file instead of exposing the secret in the process list.
PLAYIT_SECRET_FILE="$(mktemp "$BINARY_DIR/.playit-secret.XXXXXX")"
chmod 600 "$PLAYIT_SECRET_FILE"
printf '%s' "$PLAYIT_SECRET" > "$PLAYIT_SECRET_FILE"
: > "$PLAYIT_LOG"

"$PLAYIT_BIN" --stdout --secret_path "$PLAYIT_SECRET_FILE" start > "$PLAYIT_LOG" 2>&1 &
PLAYIT_PID=$!
printf '%s\n' "$PLAYIT_PID" > "$LOG_DIR/playit.pid"

# The agent reads the secret before entering its tunnel loop.
sleep 2
rm -f "$PLAYIT_SECRET_FILE"
unset PLAYIT_SECRET_FILE

echo "[PLAYIT] Agent started as PID $PLAYIT_PID; waiting for both tunnel mappings..."

MC_ENDPOINT=""
VOICE_ENDPOINT=""
for _ in $(seq 1 30); do
    if ! kill -0 "$PLAYIT_PID" 2>/dev/null; then
        echo "[PLAYIT ERROR] Agent stopped before its tunnels became ready."
        tail -n 50 "$PLAYIT_LOG" || true
        printf '%s\n' "FAIL" > "$DIAG_DIR/status_playit_agent.txt"
        exit 1
    fi

    MC_ENDPOINT="$(mapping_endpoint 25565)"
    VOICE_ENDPOINT="$(mapping_endpoint 24454)"
    if [ -n "$MC_ENDPOINT" ] && [ -n "$VOICE_ENDPOINT" ]; then
        break
    fi
    sleep 3
done

if [ -z "$MC_ENDPOINT" ] || [ -z "$VOICE_ENDPOINT" ]; then
    echo "[PLAYIT ERROR] Required mappings were not observed within 90 seconds."
    echo "[PLAYIT ERROR] Minecraft='$MC_ENDPOINT' Voice='$VOICE_ENDPOINT'"
    tail -n 80 "$PLAYIT_LOG" || true
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_playit_agent.txt"
    [ -n "$MC_ENDPOINT" ] && printf '%s\n' "PASS" > "$DIAG_DIR/status_minecraft_tunnel.txt" \
        || printf '%s\n' "FAIL" > "$DIAG_DIR/status_minecraft_tunnel.txt"
    [ -n "$VOICE_ENDPOINT" ] && printf '%s\n' "PASS" > "$DIAG_DIR/status_voice_tunnel.txt" \
        || printf '%s\n' "FAIL" > "$DIAG_DIR/status_voice_tunnel.txt"
    exit 1
fi

if ! is_public_endpoint "$VOICE_ENDPOINT"; then
    echo "[PLAYIT ERROR] Refusing invalid voice endpoint: $VOICE_ENDPOINT"
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_voice_tunnel.txt"
    exit 1
fi

if [ -n "${VOICECHAT_PUBLIC_HOST:-}" ] && [ "$VOICECHAT_PUBLIC_HOST" != "$VOICE_ENDPOINT" ]; then
    echo "[PLAYIT ERROR] VOICECHAT_PUBLIC_HOST does not match the active Playit UDP endpoint."
    echo "[PLAYIT ERROR] Configured='$VOICECHAT_PUBLIC_HOST' Active='$VOICE_ENDPOINT'"
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_svc_config.txt"
    exit 1
fi

update_property "$VOICE_CONFIG" "voice_host" "$VOICE_ENDPOINT"
printf '%s\n' "$VOICE_ENDPOINT" > "$DIAG_DIR/voicechat-public-endpoint.txt"
printf '%s\n' "$MC_ENDPOINT" > "$DIAG_DIR/minecraft-public-endpoint.txt"

CONF_PORT="$(sed -n 's/^[[:space:]]*port[[:space:]]*=[[:space:]]*//p' "$VOICE_CONFIG" | tail -n 1)"
CONF_BIND="$(sed -n 's/^[[:space:]]*bind_address[[:space:]]*=[[:space:]]*//p' "$VOICE_CONFIG" | tail -n 1)"
CONF_HOST="$(sed -n 's/^[[:space:]]*voice_host[[:space:]]*=[[:space:]]*//p' "$VOICE_CONFIG" | tail -n 1)"

if [ "$CONF_PORT" != "24454" ] || [ "$CONF_BIND" != "*" ] || [ "$CONF_HOST" != "$VOICE_ENDPOINT" ]; then
    echo "[SVC ERROR] Generated voice configuration did not pass validation."
    printf '%s\n' "FAIL" > "$DIAG_DIR/status_svc_config.txt"
    exit 1
fi

printf '%s\n' "PASS" > "$DIAG_DIR/status_playit_agent.txt"
printf '%s\n' "PASS" > "$DIAG_DIR/status_minecraft_tunnel.txt"
printf '%s\n' "PASS" > "$DIAG_DIR/status_voice_tunnel.txt"
printf '%s\n' "PASS" > "$DIAG_DIR/status_svc_config.txt"

echo "[PLAYIT SUCCESS] Minecraft TCP: $MC_ENDPOINT => 127.0.0.1:25565"
echo "[PLAYIT SUCCESS] Voice UDP:     $VOICE_ENDPOINT => 127.0.0.1:24454"
echo "[SVC SUCCESS] voice_host=$VOICE_ENDPOINT | bind_address=* | port=24454/udp"
