#!/usr/bin/env bash
# NEXUS post-boot health check. UDP is verified locally at the socket layer;
# Playit mapping and SVC advertisement are verified by scripts/network/playit.sh.

set -euo pipefail

readonly LOG_DIR="logs"
readonly DIAG_DIR="session_diagnostics"
readonly SERVER_PID_FILE="$LOG_DIR/server.pid"
readonly PLAYIT_PID_FILE="$LOG_DIR/playit.pid"
readonly VOICE_CONFIG="config/voicechat/voicechat-server.properties"

mkdir -p "$DIAG_DIR"

JAVA_STATUS="FAIL"
TCP_STATUS="FAIL"
UDP_STATUS="FAIL"
PLAYIT_STATUS="FAIL"
SVC_STATUS="FAIL"

pid_is_live() {
    local pid_file="$1"
    local process_id=""
    [ -f "$pid_file" ] || return 1
    process_id="$(cat "$pid_file" 2>/dev/null || true)"
    [[ "$process_id" =~ ^[0-9]+$ ]] && kill -0 "$process_id" 2>/dev/null
}

udp_port_is_listening() {
    command -v ss >/dev/null 2>&1 || return 1
    ss -H -lun | awk '
        {
            for (i = 1; i <= NF; i++) {
                if ($i ~ /:24454$/) found = 1
            }
        }
        END { exit(found ? 0 : 1) }
    '
}

if pid_is_live "$SERVER_PID_FILE"; then
    JAVA_STATUS="PASS"
fi

if (echo > /dev/tcp/127.0.0.1/25565) 2>/dev/null \
    || (command -v nc >/dev/null 2>&1 && nc -z -w 2 127.0.0.1 25565 2>/dev/null); then
    TCP_STATUS="PASS"
fi

if udp_port_is_listening; then
    UDP_STATUS="PASS"
fi
printf '%s\n' "$UDP_STATUS" > "$DIAG_DIR/status_voice_udp_socket.txt"

if pid_is_live "$PLAYIT_PID_FILE"; then
    PLAYIT_STATUS="PASS"
fi

if [ -f "$VOICE_CONFIG" ]; then
    CONF_PORT="$(sed -n 's/^[[:space:]]*port[[:space:]]*=[[:space:]]*//p' "$VOICE_CONFIG" | tail -n 1)"
    CONF_BIND="$(sed -n 's/^[[:space:]]*bind_address[[:space:]]*=[[:space:]]*//p' "$VOICE_CONFIG" | tail -n 1)"
    CONF_HOST="$(sed -n 's/^[[:space:]]*voice_host[[:space:]]*=[[:space:]]*//p' "$VOICE_CONFIG" | tail -n 1)"
    if [ "$CONF_PORT" = "24454" ] \
        && [ "$CONF_BIND" = "*" ] \
        && [[ "$CONF_HOST" =~ ^([A-Za-z0-9-]+\.)+(playit\.gg|ply\.gg)(:[0-9]+)?$ ]]; then
        SVC_STATUS="PASS"
    fi
fi

RAM_USAGE="$(free -h | awk '/^Mem:/{print $3 "/" $2}')"
DISK_USAGE="$(df -h . | awk 'NR==2{print $3 "/" $2 " (" $5 ")"}')"

echo "=================================================="
echo "   NEXUS POST-BOOT HEALTH CHECK"
echo "=================================================="
printf '%-30s %s\n' "Java server process:" "$JAVA_STATUS"
printf '%-30s %s\n' "Minecraft TCP 25565 socket:" "$TCP_STATUS"
printf '%-30s %s\n' "Simple Voice Chat UDP 24454:" "$UDP_STATUS"
printf '%-30s %s\n' "Playit agent process:" "$PLAYIT_STATUS"
printf '%-30s %s\n' "SVC advertised public host:" "$SVC_STATUS"
printf '%-30s %s\n' "RAM:" "$RAM_USAGE"
printf '%-30s %s\n' "Disk:" "$DISK_USAGE"

if [ "$JAVA_STATUS" = "PASS" ] \
    && [ "$TCP_STATUS" = "PASS" ] \
    && [ "$UDP_STATUS" = "PASS" ] \
    && [ "$PLAYIT_STATUS" = "PASS" ] \
    && [ "$SVC_STATUS" = "PASS" ]; then
    echo "[HEALTHCHECK PASS] TCP, UDP, Playit and SVC advertisement are ready."
    exit 0
fi

echo "[HEALTHCHECK FAIL] One or more required runtime checks failed."
exit 1
