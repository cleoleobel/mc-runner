#!/usr/bin/env bash
# ==============================================================================
# NEXUS WORLD PERSISTENCE - BACKUP WORLD
# Empaqueta y verifica el estado del mundo sin arriesgar backups anteriores
# ==============================================================================

set -euo pipefail

RUN_NUMBER="${GITHUB_RUN_NUMBER:-manual}"
DATE_STR=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backups_staging"
mkdir -p "$BACKUP_DIR"
mkdir -p session_diagnostics
echo "UNVERIFIED" > session_diagnostics/status_backup.txt

# El nombre final del archivo se determinará después de calcular el hash

echo "=================================================="
echo "   GENERANDO RESPALDO DE MUNDO ROBUSTO NEXUS"
echo "   Run: $RUN_NUMBER | Timestamp: $DATE_STR"
echo "=================================================="

if [ ! -d "./world" ]; then
    echo "[BACKUP ERROR] No existe el directorio ./world para respaldar."
    exit 1
fi

# 1. Sincronizar disco
echo "[BACKUP] Sincronizando sistema de archivos..."
sync

# 2. Comprimir nuevo mundo en archivo temporal aislado
TEMP_BACKUP="$BACKUP_DIR/new-world-staging.tar.gz"
rm -f "$TEMP_BACKUP"

echo "[BACKUP] Comprimiendo ./world a $HISTORICAL_NAME..."
tar -czf "$TEMP_BACKUP" ./world

# 3. Comprobar integridad criptográfica y del archivo comprimido
echo "[BACKUP] Verificando integridad del archivo comprimido..."
if tar -tzf "$TEMP_BACKUP" >/dev/null 2>&1; then
    echo "[BACKUP INTEGRITY OK] La estructura del archivo .tar.gz es correcta."
else
    echo "[BACKUP CRITICAL ERROR] El archivo comprimido generado está corrupto. ABORTANDO."
    rm -f "$TEMP_BACKUP"
    exit 1
fi

# 4. Calcular hash SHA-256
HASH=$(sha256sum "$TEMP_BACKUP" | awk '{print $1}')
echo "[BACKUP HASH] SHA-256: $HASH"

HISTORICAL_NAME="world-run-${RUN_NUMBER}-${HASH}.tar.gz"

# 5. Promover backup temporal a histórico y preparar lote para upload
cp "$TEMP_BACKUP" "$BACKUP_DIR/$HISTORICAL_NAME"

# Guardar información de verificación
cat << EOF > "$BACKUP_DIR/backup-info.json"
{
  "run_id": "$RUN_NUMBER",
  "created_at": "$DATE_STR",
  "asset": "$HISTORICAL_NAME",
  "sha256": "$HASH"
}
EOF

mkdir -p session_diagnostics
echo "PASS" > session_diagnostics/status_backup.txt

echo "[BACKUP LOCAL SUCCESS] Backup generado exitosamente en $BACKUP_DIR/$HISTORICAL_NAME"
exit 0
