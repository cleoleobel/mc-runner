#!/bin/bash
echo "=================================================="
echo "   INICIANDO SERVIDOR MINECRAFT FORGE (NIVEL 1000x)"
echo "=================================================="

# 1. Asegurar permisos de ejecución en scripts
chmod +x scripts/*.sh || true

# 2. Instalar Forge y preparar archivos si no están listos
bash scripts/install_forge.sh

# 3. Afinación del Kernel OS (Sysctl, Network, TCP) (Silencioso si no hay sudo)
if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    echo "[KERNEL] Aplicando optimizaciones extremas TCP/IP en Sysctl..."
    sudo sysctl -w net.ipv4.tcp_window_scaling=1 2>/dev/null
    sudo sysctl -w net.core.rmem_max=16777216 2>/dev/null
    sudo sysctl -w net.core.wmem_max=16777216 2>/dev/null
    sudo sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216" 2>/dev/null
    sudo sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216" 2>/dev/null
fi

# 4. RAMDisk (Cero Latencia I/O) para la carpeta World
WORLD_DIR="dist/NEXUS_SERVER_READY/world"
if [ ! -d "$WORLD_DIR" ]; then
    mkdir -p "$WORLD_DIR"
fi

if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    # Verificar si ya esta montado
    if ! mountpoint -q "$WORLD_DIR"; then
        echo "[RAMDISK] Montando carpeta World en Memoria RAM (tmpfs)..."
        # Respaldamos datos si hay a una carpeta temporal antes de montar
        mkdir -p "${WORLD_DIR}_backup"
        cp -r "$WORLD_DIR/"* "${WORLD_DIR}_backup/" 2>/dev/null || true
        sudo mount -t tmpfs -o size=2G tmpfs "$WORLD_DIR"
        cp -r "${WORLD_DIR}_backup/"* "$WORLD_DIR/" 2>/dev/null || true
    fi
else
    echo "[RAMDISK] ADVERTENCIA: Sin permisos sudo root, saltando montaje de RAMDisk. El SSD será usado."
fi

# 5. Restaurar el mundo desde almacenamiento externo
bash scripts/restore_world.sh

# 6. Iniciar el túnel Playit.gg
if [ -n "$PLAYIT_SECRET_KEY" ]; then
    echo "[PLAYIT.GG] Iniciando agente con clave de secreto..."
    playit --secret "$PLAYIT_SECRET_KEY" daemon > playit.log 2>&1 &
    PLAYIT_PID=$!
    echo "[PLAYIT.GG] Agente corriendo (PID: $PLAYIT_PID)."
else
    echo "[PLAYIT.GG] ADVERTENCIA: PLAYIT_SECRET_KEY no está configurada."
fi

# 7. Configurar trampa SIGTERM / SIGINT
cleanup() {
    echo "=================================================="
    echo " Interrupción detectada. Deteniendo servidor, guardando RAMDisk y saliendo..."
    echo "=================================================="
    bash scripts/backup_world.sh
    
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        if mountpoint -q "$WORLD_DIR"; then
            cp -r "$WORLD_DIR/"* "${WORLD_DIR}_backup/" 2>/dev/null || true
            sudo umount "$WORLD_DIR" 2>/dev/null || true
            # Sync to actual disk
            cp -r "${WORLD_DIR}_backup/"* "$WORLD_DIR/" 2>/dev/null || true
        fi
    fi

    if [ -n "$PLAYIT_PID" ]; then
        kill $PLAYIT_PID 2>/dev/null || true
    fi
    exit 0
}

trap cleanup SIGTERM SIGINT

# Bucle infinito para mantener el servidor 24/7
while true; do
    echo "[MINECRAFT] Iniciando Java Forge 1.20.1 (Motor Nivel 1000x)..."
    ./run.sh &
    SERVER_PID=$!

    # 8. Afinidad de CPU y Prioridad (Taskset & Renice)
    if command -v taskset >/dev/null 2>&1; then
        echo "[CPU PINNING] Aislando servidor a nucleos específicos para retener L3 Cache..."
        taskset -cp 0-3 $SERVER_PID 2>/dev/null || true
    fi
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        echo "[KERNEL] Elevando prioridad del proceso de Minecraft al máximo (-20)..."
        sudo renice -n -20 -p $SERVER_PID 2>/dev/null || true
    fi

    # 9. Monitoreo: backup periódico (15 min) y reinicio automático (6 hrs)
    START_TIME=$(date +%s)
    LAST_BACKUP=$START_TIME
    
    while kill -0 $SERVER_PID 2>/dev/null; do
        sleep 60
        CURRENT_TIME=$(date +%s)
        
        # Backup cada 15 minutos (900 segundos)
        if (( CURRENT_TIME - LAST_BACKUP >= 900 )); then
            echo "[MONITOR] Realizando respaldo periódico desde la RAMDisk al Disco Fisico..."
            bash scripts/backup_world.sh
            
            if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
                if mountpoint -q "$WORLD_DIR"; then
                    # Sincronizamos la RAMDisk al disco fisico en background
                    rsync -a --delete "$WORLD_DIR/" "${WORLD_DIR}_backup/" 2>/dev/null &
                fi
            fi

            LAST_BACKUP=$CURRENT_TIME
        fi
        
        # Reinicio cada 6 horas (21600 segundos)
        if (( CURRENT_TIME - START_TIME >= 21600 )); then
            echo "[MONITOR] 6 horas alcanzadas. Purga Termodinámica en curso..."
            kill -TERM $SERVER_PID
            wait $SERVER_PID 2>/dev/null
            break
        fi
    done

    wait $SERVER_PID 2>/dev/null
    echo "[MINECRAFT] El servidor Java se ha detenido."
    bash scripts/backup_world.sh
    
    echo "[MONITOR] Reiniciando entorno en 10 segundos..."
    sleep 10
done
