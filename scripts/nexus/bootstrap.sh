#!/usr/bin/env bash
# ==============================================================================
# NEXUS MASTER BOOTSTRAPPER
# Orquestador principal de despliegue para GitHub Actions y VPS (Oracle A1 / Ubuntu)
# ==============================================================================

set -euo pipefail

OPERATION="run-server"
SESSION_MINUTES="330"
RESTORE_WORLD="yes"
DEBUG_MODE="false"

# Procesar argumentos
while [[ $# -gt 0 ]]; do
  case $1 in
    --operation)
      OPERATION="$2"
      shift 2
      ;;
    --session-minutes)
      SESSION_MINUTES="$2"
      shift 2
      ;;
    --restore-world)
      RESTORE_WORLD="$2"
      shift 2
      ;;
    --debug)
      DEBUG_MODE="$2"
      shift 2
      ;;
    *)
      echo "Opción desconocida: $1"
      exit 1
      ;;
  esac
done

export SESSION_MINUTES
export RESTORE_WORLD

if [ "$DEBUG_MODE" = "true" ]; then
    set -x
fi

echo "=================================================="
echo "   NEXUS INFRASTRUCTURE BOOTSTRAPPER"
echo "   Operación: $OPERATION | Sesión: ${SESSION_MINUTES}m | Restore World: $RESTORE_WORLD"
echo "=================================================="

chmod +x scripts/nexus/*.sh scripts/network/*.sh 2>/dev/null || true

# ETAPA 1: Entorno Java 17
echo "[STAGE 1/8] Verificando e instalando Java 17..."
bash scripts/nexus/install-java.sh

# ETAPA 2: Descargar Server Bundle
echo "[STAGE 2/8] Descargando Server Bundle..."
bash scripts/nexus/download-bundle.sh

# ETAPA 3: Verificar Integredad SHA-256
echo "[STAGE 3/8] Verificando firma SHA-256..."
bash scripts/nexus/verify-bundle.sh

# ETAPA 4: Extraer Servidor
echo "[STAGE 4/8] Extrayendo distribución del servidor..."
tar -xzf download_bundle/server-bundle.tar.gz -C ./
rm -rf download_bundle

# ETAPA 5: Restaurar Estado del Mundo
echo "[STAGE 5/8] Restaurando estado del mundo persistente..."
bash scripts/nexus/restore-world.sh

# ETAPA 6: Iniciar Servidor Forge y Red
echo "[STAGE 6/8] Arrancando Servidor NEXUS Forge y Túnel..."
bash scripts/nexus/start-server.sh "$OPERATION"

# ETAPA 7: Generar Respaldo del Mundo
echo "[STAGE 7/8] Empaquetando nuevo respaldo de mundo verificado..."
bash scripts/nexus/backup-world.sh

# ETAPA 8: Subir Respaldo a Almacenamiento Remoto
echo "[STAGE 8/8] Subiendo respaldo del mundo a NEXUS STORAGE..."
bash scripts/nexus/upload-world.sh

echo "=================================================="
echo "   BOOTSTRAPPER DE NEXUS COMPLETADO CON ÉXITO"
echo "=================================================="
