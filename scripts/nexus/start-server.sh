#!/usr/bin/env bash
# ==============================================================================
# NEXUS SERVER LAUNCHER & DYNAMIC RAM TUNER
# Inicia Forge 1.20.1 con optimización de Heap, túnel de red y monitoreo
# ==============================================================================

set -euo pipefail

LOG_DIR="logs"
mkdir -p "$LOG_DIR"
SERVER_LOG="$LOG_DIR/latest.log"

mkdir -p "session_diagnostics"
echo "⏳ INICIANDO" > "session_diagnostics/status_server.txt"

OPERATION="${1:-run-server}"
SESSION_MINUTES="${SESSION_MINUTES:-330}"

echo "=================================================="
echo "   INICIANDO SERVIDOR NEXUS FORGE 1.20.1"
echo "   Operación: $OPERATION"
echo "=================================================="

# 1. Cálculo dinámico de RAM (Heap)
TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}' || echo "8000")
echo "[JVM] Memoria RAM total disponible en sistema: ${TOTAL_RAM_MB} MB"

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

echo "[JVM] Configurando Heap dinámico: -Xms$XMS -Xmx$XMX"
cat << EOF > user_jvm_args.txt
-Xms${XMS}
-Xmx${XMX}
-XX:+UseG1GC
-XX:+UnlockExperimentalVMOptions
-XX:G1NewSizePercent=20
-XX:G1ReservePercent=20
-XX:MaxGCPauseMillis=50
-XX:G1HeapRegionSize=32M
EOF

# 2. Aceptar EULA
echo "eula=true" > eula.txt

# 3. Arrancar capa de red (Playit.gg) en segundo plano
if [ -f "scripts/network/playit.sh" ]; then
    bash scripts/network/playit.sh || echo "[PLAYIT WARN] Continuando sin agente de red Playit."
fi

# 4. Preparar Fifo / tubería de entrada para enviar comandos al servidor
FIFO_PATH="server_stdin.fifo"
rm -f "$FIFO_PATH"
mkfifo "$FIFO_PATH"
exec 3<> "$FIFO_PATH"

# 4.5. Configurar modo No Premium (online-mode=false)
if [ -f "server.properties" ]; then
    sed -i 's/^online-mode=true/online-mode=false/' server.properties
fi

# 5. Arrancar Forge Dedicated Server
chmod +x run.sh || true
echo "[MINECRAFT] Ejecutando ./run.sh nogui..."

./run.sh nogui < "$FIFO_PATH" > >(tee -a "$SERVER_LOG") 2>&1 &
SERVER_PID=$!
echo "$SERVER_PID" > "$LOG_DIR/server.pid"

echo "[MINECRAFT] Servidor lanzado con PID: $SERVER_PID. Esperando inicio de Forge..."

# 6. Monitoreo de booteo (esperar hasta ver mensaje "Done (")
BOOT_TIMEOUT=300
ELAPSED=0
BOOTED=false

while [ $ELAPSED -lt $BOOT_TIMEOUT ]; do
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "[CRASH FATAL] El proceso Java de Forge se detuvo prematuramente."
        echo "=== ÚLTIMAS 50 LÍNEAS DE LOG DE ERROR ==="
        tail -n 50 "$SERVER_LOG"
        echo "❌ CRASHED" > "session_diagnostics/status_server.txt"
        exit 1
    fi

    if grep -qE 'Done \([0-9]+\.[0-9]+s\)!|Done \([0-9]+\.[0-9]+s\)' "$SERVER_LOG"; then
        BOOTED=true
        echo "[MINECRAFT SUCCESS] Servidor Forge iniciado correctamente en ${ELAPSED}s."
        echo "✅ ONLINE" > "session_diagnostics/status_server.txt"
        break
    fi

    sleep 3
    ELAPSED=$((ELAPSED+3))
done

if [ "$BOOTED" = false ]; then
    echo "[TIMEOUT ERROR] El servidor no alcanzó el estado 'Done' dentro de ${BOOT_TIMEOUT}s."
    echo "=== ÚLTIMAS 50 LÍNEAS DE LOG ==="
    tail -n 50 "$SERVER_LOG"
    echo "❌ TIMEOUT" > "session_diagnostics/status_server.txt"
    exit 1
fi

# 7. Ejecución según la operación solicitada
if [ "$OPERATION" = "validate" ]; then
    echo "[FIRST_BOOT_TEST] Validación de booteo completada exitosamente."
    echo "[FIRST_BOOT_TEST] Ejecutando cierre limpio..."
    bash scripts/nexus/stop-server.sh
    exit 0
elif [ "$OPERATION" = "pregen" ]; then
    PREGEN_RADIUS="${PREGEN_RADIUS:-500}"
    echo "[PREGEN] Iniciando pre-generación Chunky con radio $PREGEN_RADIUS bloques..."
    echo "chunky radius $PREGEN_RADIUS" > "$FIFO_PATH"
    sleep 2
    echo "chunky start" > "$FIFO_PATH"
    sleep 10
    echo "[PREGEN] Tarea de pre-generación enviada. Esperando 120s..."
    sleep 120
    echo "[PREGEN] Guardando progreso..."
    echo "save-all" > "$FIFO_PATH"
    sleep 10
    bash scripts/nexus/stop-server.sh
    exit 0
fi

# 8. Mantenimiento de sesión para 'run-server'
echo "[SESSION] Servidor en línea. Manteniendo sesión activa durante ${SESSION_MINUTES} minutos..."
SESSION_SECONDS=$((SESSION_MINUTES * 60))
WARN_5M=$((SESSION_SECONDS - 300))
WARN_1M=$((SESSION_SECONDS - 60))

ELAPSED_SESSION=0
while [ $ELAPSED_SESSION -lt $SESSION_SECONDS ]; do
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo "[SERVER WARN] El proceso Java finalizó."
        break
    fi

    if [ $ELAPSED_SESSION -eq $WARN_5M ] && [ $WARN_5M -gt 0 ]; then
        echo 'say §c[AVISO] El servidor se reiniciará en 5 minutos para guardar progreso.' > "$FIFO_PATH"
    fi

    if [ $ELAPSED_SESSION -eq $WARN_1M ] && [ $WARN_1M -gt 0 ]; then
        echo 'say §c[AVISO CRÍTICO] El servidor se apaga en 1 minuto. Por favor guarden su avance.' > "$FIFO_PATH"
    fi

    sleep 15
    ELAPSED_SESSION=$((ELAPSED_SESSION+15))
done

echo "[SESSION] Límite de sesión alcanzado. Iniciando guardado y apagado limpio..."
bash scripts/nexus/stop-server.sh
