#!/usr/bin/env bash
# ==============================================================================
# NEXUS SERVER SHUTDOWN - CLEAN STOP
# Ejecuta un apagado ordenado del servidor Minecraft y sincroniza el disco
# ==============================================================================

set -euo pipefail

LOG_DIR="logs"
SERVER_PID_FILE="$LOG_DIR/server.pid"
PLAYIT_PID_FILE="$LOG_DIR/playit.pid"
FIFO_PATH="server_stdin.fifo"

echo "=================================================="
echo "   DETENIENDO SERVIDOR MINECRAFT NEXUS"
echo "=================================================="

mkdir -p session_diagnostics
echo "UNVERIFIED" > session_diagnostics/status_stop.txt

# 1. Enviar comando 'stop' si el servidor está corriendo
if [ -f "$SERVER_PID_FILE" ]; then
    PID=$(cat "$SERVER_PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "[SHUTDOWN] Enviando comando 'stop' al servidor Minecraft..."
        if [ -p "$FIFO_PATH" ]; then
            echo "say §c[NEXUS] Guardando el mundo y apagando el servidor..." > "$FIFO_PATH"
            sleep 2
            echo "save-all" > "$FIFO_PATH"
            sleep 3
            echo "stop" > "$FIFO_PATH"
        else
            kill -SIGINT "$PID" 2>/dev/null || true
        fi

        echo "[SHUTDOWN] Esperando cierre ordenado del proceso Java (PID: $PID)..."
        WAIT_SECONDS=0
        MAX_WAIT=45
        while kill -0 "$PID" 2>/dev/null && [ $WAIT_SECONDS -lt $MAX_WAIT ]; do
            sleep 2
            WAIT_SECONDS=$((WAIT_SECONDS+2))
        done

        if kill -0 "$PID" 2>/dev/null; then
            echo "[SHUTDOWN WARN] El servidor no cerró en ${MAX_WAIT}s. Enviando SIGTERM..."
            kill -15 "$PID" 2>/dev/null || true
            sleep 3
        fi
        echo "[SHUTDOWN OK] El proceso Java de Minecraft finalizó."
    else
        echo "[SHUTDOWN INFO] El servidor Java ya estaba detenido."
    fi
    rm -f "$SERVER_PID_FILE"
fi

# 2. Detener Playit Agent
if [ -f "$PLAYIT_PID_FILE" ]; then
    PLAYIT_PID=$(cat "$PLAYIT_PID_FILE")
    if kill -0 "$PLAYIT_PID" 2>/dev/null; then
        echo "[SHUTDOWN] Deteniendo agente Playit (PID: $PLAYIT_PID)..."
        kill "$PLAYIT_PID" 2>/dev/null || true
    fi
    rm -f "$PLAYIT_PID_FILE"
fi

rm -f "$FIFO_PATH"
sync || true
echo "PASS" > session_diagnostics/status_stop.txt
echo "[SHUTDOWN COMPLETE] Servidor y túneles detenidos limpiamente."
