#!/usr/bin/env bash
# ==============================================================================
# NEXUS NETWORK AGENT - PLAYIT.GG INTEGRATION & ABSTRACTION
# Configura y arranca la capa de red pública Playit.gg
# ==============================================================================

set -euo pipefail

LOG_DIR="logs"
mkdir -p "$LOG_DIR"
PLAYIT_LOG="$LOG_DIR/playit.log"
BINARY_DIR="tools/bin"
mkdir -p "$BINARY_DIR"
PLAYIT_BIN="$BINARY_DIR/playit"

echo "=================================================="
echo "   NEXUS NETWORK LAYER — PLAYIT.GG INTEGRATION"
echo "=================================================="

# 1. Comprobar secrecía
DIAG_DIR="session_diagnostics"
mkdir -p "$DIAG_DIR"

echo "UNVERIFIED" > "$DIAG_DIR/status_playit_secret.txt"
echo "UNVERIFIED" > "$DIAG_DIR/status_playit_agent.txt"
echo "UNVERIFIED" > "$DIAG_DIR/status_minecraft_tunnel.txt"
echo "UNVERIFIED" > "$DIAG_DIR/status_voice_tunnel.txt"

if [ -z "${PLAYIT_SECRET:-}" ]; then
    echo "[PLAYIT WARN] PLAYIT_SECRET no está configurada en los Secrets del Repositorio."
    echo "NOT_CONFIGURED" > "$DIAG_DIR/status_playit_secret.txt"
    echo "[PLAYIT WARN] El túnel no iniciará automáticamente. El servidor solo escuchará en localhost."
    exit 0
fi

echo "PASS" > "$DIAG_DIR/status_playit_secret.txt"

# 2. Descargar binario oficial de Playit si no existe
if [ ! -f "$PLAYIT_BIN" ]; then
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            DOWNLOAD_URL="https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-amd64"
            ;;
        aarch64|arm64)
            DOWNLOAD_URL="https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-arm64"
            ;;
        *)
            echo "[PLAYIT ERROR] Arquitectura no soportada: $ARCH"
            echo "FAIL" > "$DIAG_DIR/status_playit_agent.txt"
            exit 1
            ;;
    esac

    echo "[PLAYIT] Descargando agente Playit para $ARCH..."
    curl -sSL -o "$PLAYIT_BIN" "$DOWNLOAD_URL" || {
        echo "[PLAYIT WARN] Fallback a versión recomendada Playit v0.17.1..."
        curl -sSL -o "$PLAYIT_BIN" "https://github.com/playit-cloud/playit-agent/releases/download/v0.17.1/playit-linux-amd64"
    }
    chmod +x "$PLAYIT_BIN"
    echo "[PLAYIT] Agente descargado en $PLAYIT_BIN"
fi

# 3. Arrancar agente con sanitización de secrets
echo "[PLAYIT] Iniciando daemon de Playit..."

("$PLAYIT_BIN" --secret "$PLAYIT_SECRET" daemon 2>&1 | sed -u "s/$PLAYIT_SECRET/[REDACTED]/g" > "$PLAYIT_LOG") &
PLAYIT_PID=$!
echo "$PLAYIT_PID" > "$LOG_DIR/playit.pid"

echo "[PLAYIT] Agente corriendo en segundo plano (PID: $PLAYIT_PID)."

# 4. Esperar verificación de conexión inicial
echo "[PLAYIT] Comprobando establecimiento de túneles (esperando 6s)..."
sleep 6

if kill -0 "$PLAYIT_PID" 2>/dev/null; then
    echo "[PLAYIT OK] El proceso de Playit está activo."
    echo "PASS" > "$DIAG_DIR/status_playit_agent.txt"

    # Inspeccionar log para verificar túneles TCP 25565 y UDP 24454
    if grep -iE "25565|minecraft" "$PLAYIT_LOG" >/dev/null 2>&1; then
        echo "PASS" > "$DIAG_DIR/status_minecraft_tunnel.txt"
        echo "[PLAYIT] Túnel de Minecraft (TCP 25565) detectado en logs."
    fi

    if grep -iE "24454|voice" "$PLAYIT_LOG" >/dev/null 2>&1; then
        echo "PASS" > "$DIAG_DIR/status_voice_tunnel.txt"
        echo "[PLAYIT] Túnel de Voice Chat (UDP 24454) detectado en logs."

        # Extraer endpoint externo si está presente en logs (ej. host.playit.gg:12345)
        VOICE_ENDPOINT=$(grep -iE "24454|voice" "$PLAYIT_LOG" | grep -oE "([a-zA-Z0-9.-]+\.playit\.gg:[0-9]+|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+)" | head -n 1 || true)

        if [ -n "$VOICE_ENDPOINT" ]; then
            echo "[PLAYIT] Configurando automáticamente voice_host=$VOICE_ENDPOINT en config/voicechat/voicechat-server.properties..."
            mkdir -p config/voicechat
            cat << EOF > config/voicechat/voicechat-server.properties
port=24454
bind_address=0.0.0.0
voice_host=$VOICE_ENDPOINT
EOF
        fi
    fi

    # Garantizar que config/voicechat/voicechat-server.properties existe con bind_address=0.0.0.0
    mkdir -p config/voicechat
    if [ ! -f "config/voicechat/voicechat-server.properties" ]; then
        cat << EOF > config/voicechat/voicechat-server.properties
port=24454
bind_address=0.0.0.0
voice_host=
EOF
    fi

    exit 0
else
    echo "[PLAYIT ERROR] El agente Playit se detuvo inesperadamente. Revisa $PLAYIT_LOG"
    echo "FAIL" > "$DIAG_DIR/status_playit_agent.txt"
    exit 1
fi
