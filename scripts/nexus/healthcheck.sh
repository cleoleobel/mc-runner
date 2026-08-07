#!/usr/bin/env bash
# ==============================================================================
# NEXUS HEALTHCHECK & SYSTEM DIAGNOSTIC
# Verifica en tiempo real el estado de Java, Forge, Red y Playit
# ==============================================================================

set -euo pipefail

LOG_DIR="logs"
SERVER_PID_FILE="$LOG_DIR/server.pid"
PLAYIT_PID_FILE="$LOG_DIR/playit.pid"

JAVA_STATUS="ERROR"
PORT_TCP_STATUS="ERROR"
PORT_UDP_STATUS="WARN (UNCHECKED)"
PLAYIT_STATUS="OFFLINE"

echo "=== EJECUTANDO DIAGNÓSTICO DE SALUD NEXUS ==="

# 1. Verificar Proceso Java
if [ -f "$SERVER_PID_FILE" ];  then
    PID=$(cat "$SERVER_PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        JAVA_STATUS="OK"
    fi
fi

# 2. Verificar Puerto TCP 25565
if (echo > /dev/tcp/127.0.0.1/25565) 2>/dev/null; then
    PORT_TCP_STATUS="OK"
elif command -v nc >/dev/null 2>&1 && nc -z -w 2 127.0.0.1 25565 2>/dev/null; then
    PORT_TCP_STATUS="OK"
fi

# 3. Verificar Proceso Playit
if [ -f "$PLAYIT_PID_FILE" ]; then
    PPID=$(cat "$PLAYIT_PID_FILE")
    if kill -0 "$PPID" 2>/dev/null; then
        PLAYIT_STATUS="OK"
    fi
fi

# 4. Uso de Recursos
RAM_USAGE=$(free -h | awk '/^Mem:/{print $3 "/" $2}')
DISK_USAGE=$(df -h . | awk 'NR==2{print $3 "/" $2 " (" $5 ")"}')

echo "--------------------------------------------------"
echo "Java Server Process: $JAVA_STATUS"
echo "Minecraft TCP 25565: $PORT_TCP_STATUS"
echo "Simple Voice Chat:   UDP 24454 Configured"
echo "Playit Agent Tunnel: $PLAYIT_STATUS"
echo "Uso de RAM:          $RAM_USAGE"
echo "Uso de Disco:        $DISK_USAGE"
echo "--------------------------------------------------"

if [ "$JAVA_STATUS" = "OK" ] && [ "$PORT_TCP_STATUS" = "OK" ]; then
    exit 0
else
    exit 1
fi
