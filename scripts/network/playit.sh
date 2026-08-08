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

# 1. Comprobar secrecía e inicializar estados
DIAG_DIR="session_diagnostics"
mkdir -p "$DIAG_DIR"

echo "UNVERIFIED" > "$DIAG_DIR/status_playit_secret.txt"
echo "UNVERIFIED" > "$DIAG_DIR/status_playit_agent.txt"
echo "UNVERIFIED" > "$DIAG_DIR/status_minecraft_tunnel.txt"
echo "UNVERIFIED" > "$DIAG_DIR/status_voice_tunnel.txt"
echo "UNVERIFIED" > "$DIAG_DIR/status_svc_config.txt"

# Función auxiliar para actualizar propiedades de forma idempotente conservando comentarios
update_property() {
    local file="$1"
    local key="$2"
    local val="$3"

    if [ ! -f "$file" ]; then
        mkdir -p "$(dirname "$file")"
        touch "$file"
    fi

    if grep -q "^[[:space:]]*${key}[[:space:]]*=" "$file"; then
        sed -i "s|^[[:space:]]*${key}[[:space:]]*=.*|${key}=${val}|" "$file"
    else
        echo "${key}=${val}" >> "$file"
    fi
}

# Asegurar configuración base para Simple Voice Chat
update_property "config/voicechat/voicechat-server.properties" "port" "24454"
update_property "config/voicechat/voicechat-server.properties" "bind_address" "*"

if [ -z "${PLAYIT_SECRET:-}" ]; then
    echo "[PLAYIT WARN] PLAYIT_SECRET no está configurada en los Secrets del Repositorio."
    echo "NOT_CONFIGURED" > "$DIAG_DIR/status_playit_secret.txt"
    echo "NOT_CONFIGURED" > "$DIAG_DIR/status_svc_config.txt"
    echo "[PLAYIT WARN] El túnel no iniciará automáticamente. El servidor solo escuchará en localhost."
    exit 0
fi

echo "PASS" > "$DIAG_DIR/status_playit_secret.txt"

# 2. Descargar binario oficial de Playit si no existe
if [ ! -f "$PLAYIT_BIN" ]; then
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            DOWNLOAD_URL="https://github.com/playit-cloud/playit-agent/releases/download/v0.15.26/playit-linux-amd64"
            ;;
        aarch64|arm64)
            DOWNLOAD_URL="https://github.com/playit-cloud/playit-agent/releases/download/v0.15.26/playit-linux-arm64"
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

("$PLAYIT_BIN" --secret "$PLAYIT_SECRET" start 2>&1 | sed -u "s/$PLAYIT_SECRET/[REDACTED]/g" > "$PLAYIT_LOG") &
PLAYIT_PID=$!
echo "$PLAYIT_PID" > "$LOG_DIR/playit.pid"

echo "[PLAYIT] Agente lanzado en segundo plano (PID: $PLAYIT_PID)."

# 4. Esperar autenticación y verificación de conexión inicial
echo "[PLAYIT] Esperando autenticación y establecimiento de túneles (15s)..."
sleep 15

if ! kill -0 "$PLAYIT_PID" 2>/dev/null; then
    echo "[PLAYIT ERROR] El agente Playit se detuvo prematuramente."
    echo "FAIL" > "$DIAG_DIR/status_playit_agent.txt"
    exit 1
fi

# Verificar autenticación/conexión real en los logs
if grep -iE "agent connected|connected|registered|authenticated|tunnel runner|established" "$PLAYIT_LOG" >/dev/null 2>&1; then
    echo "[PLAYIT SUCCESS] Evidencia de conexión/autenticación del agente Playit confirmada en logs."
    echo "PASS" > "$DIAG_DIR/status_playit_agent.txt"
else
    echo "[PLAYIT WARN] No se encontró evidencia explícita de autenticación en logs. Agente en verificación."
    echo "UNVERIFIED" > "$DIAG_DIR/status_playit_agent.txt"
fi

# 5. Detección y verificación de túneles específicos y endpoints
MC_ENDPOINT=$(grep -iE "25565|minecraft" "$PLAYIT_LOG" | grep -oE "([a-zA-Z0-9.-]+\.playit\.gg:[0-9]+|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+)" | head -n 1 || true)
if [ -n "$MC_ENDPOINT" ]; then
    echo "[PLAYIT] Túnel Minecraft TCP 25565 verificado con endpoint: $MC_ENDPOINT"
    echo "PASS" > "$DIAG_DIR/status_minecraft_tunnel.txt"
else
    echo "[PLAYIT INFO] Túnel Minecraft TCP 25565 pendiente o no detectado aún en logs."
    echo "UNVERIFIED" > "$DIAG_DIR/status_minecraft_tunnel.txt"
fi

VOICE_ENDPOINT=$(grep -iE "24454|voice" "$PLAYIT_LOG" | grep -oE "([a-zA-Z0-9.-]+\.playit\.gg:[0-9]+|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+)" | head -n 1 || true)

if [ -n "$VOICE_ENDPOINT" ]; then
    echo "[PLAYIT] Túnel Voice Chat UDP 24454 verificado con endpoint: $VOICE_ENDPOINT"
    update_property "config/voicechat/voicechat-server.properties" "voice_host" "$VOICE_ENDPOINT"
fi

# 6. Re-leer y confirmar configuración de Simple Voice Chat
CONF_PORT=$(grep "^[[:space:]]*port=" "config/voicechat/voicechat-server.properties" | cut -d '=' -f 2- | tr -d ' ' || true)
CONF_BIND=$(grep "^[[:space:]]*bind_address=" "config/voicechat/voicechat-server.properties" | cut -d '=' -f 2- | tr -d ' ' || true)
CONF_HOST=$(grep "^[[:space:]]*voice_host=" "config/voicechat/voicechat-server.properties" | cut -d '=' -f 2- | tr -d ' ' || true)

if [ "$CONF_PORT" = "24454" ] && [ "$CONF_BIND" = "*" ] && [ -n "$CONF_HOST" ] && [ -n "$VOICE_ENDPOINT" ]; then
    echo "[SVC SUCCESS] Configuración SVC validada: bind_address=* | voice_host=$CONF_HOST"
    echo "PASS" > "$DIAG_DIR/status_voice_tunnel.txt"
    echo "PASS" > "$DIAG_DIR/status_svc_config.txt"
else
    echo "[SVC INFO] Configuración base verificada (bind_address=* | port=24454). Pendiente de endpoint de túnel activo."
    echo "UNVERIFIED" > "$DIAG_DIR/status_voice_tunnel.txt"
    echo "UNVERIFIED" > "$DIAG_DIR/status_svc_config.txt"
fi

exit 0
