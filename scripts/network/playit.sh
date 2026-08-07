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
if [ -z "${PLAYIT_SECRET:-}" ]; then
    echo "[PLAYIT ERROR] PLAYIT_SECRET no está configurada en los Secrets del Repositorio."
    echo "[PLAYIT WARN] El túnel no iniciará automáticamente. El servidor solo escuchará en localhost."
    exit 1
fi

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
            exit 1
            ;;
    esac

    echo "[PLAYIT] Descargando agente Playit para $ARCH..."
    curl -sSL -o "$PLAYIT_BIN" "$DOWNLOAD_URL" || {
        # Fallback a URL alternativa v0.17.1 si latest falla
        echo "[PLAYIT WARN] Fallback a versión recomendada Playit v0.17.1..."
        curl -sSL -o "$PLAYIT_BIN" "https://github.com/playit-cloud/playit-agent/releases/download/v0.17.1/playit-linux-amd64"
    }
    chmod +x "$PLAYIT_BIN"
    echo "[PLAYIT] Agente descargado en $PLAYIT_BIN"
fi

# 3. Arrancar agente con sanitización de secrets
echo "[PLAYIT] Iniciando daemon de Playit..."

# Arrancar en segundo plano filtrando la clave secreta de los logs
("$PLAYIT_BIN" --secret "$PLAYIT_SECRET" daemon 2>&1 | sed -u "s/$PLAYIT_SECRET/[REDACTED]/g" > "$PLAYIT_LOG") &
PLAYIT_PID=$!
echo "$PLAYIT_PID" > "$LOG_DIR/playit.pid"

echo "[PLAYIT] Agente corriendo en segundo plano (PID: $PLAYIT_PID)."

# 4. Esperar verificación de conexión inicial
echo "[PLAYIT] Comprobando establecimiento de túneles (esperando 5s)..."
sleep 5

if kill -0 "$PLAYIT_PID" 2>/dev/null; then
    echo "[PLAYIT OK] El proceso de Playit está activo."
    echo "[PLAYIT INFO] Mappings requeridos en Panel de Playit:"
    echo "  - Minecraft Java:  TCP 25565 -> External Host"
    echo "  - Simple Voice:    UDP 24454 -> External Host"
    exit 0
else
    echo "[PLAYIT ERROR] El agente Playit se detuvo inesperadamente. Revisa $PLAYIT_LOG"
    exit 1
fi
