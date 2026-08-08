#!/usr/bin/env bash
# ==============================================================================
# NEXUS WORLD PERSISTENCE - UPLOAD WORLD BACKUP
# Sube el respaldo verificado a GitHub Releases en NEXUS STORAGE Privado
# ==============================================================================

set -euo pipefail

STORAGE_REPO="${STORAGE_REPO:-cleoleobel/nexus-storage}"
BACKUP_DIR="backups_staging"
TEMP_BACKUP="$BACKUP_DIR/new-world-staging.tar.gz"

echo "=================================================="
echo "   SUBIENDO RESPALDO DEL MUNDO A NEXUS STORAGE"
echo "   Storage Repo: $STORAGE_REPO"
echo "=================================================="

if [ ! -f "$TEMP_BACKUP" ]; then
    echo "[UPLOAD ERROR] No existe el respaldo verificado $TEMP_BACKUP"
    exit 1
fi

# 1. Autenticar en GitHub CLI
if [ -n "${NEXUS_STORAGE_TOKEN:-}" ]; then
    echo "$NEXUS_STORAGE_TOKEN" | gh auth login --with-token 2>/dev/null
fi

# 2. Asegurar que exista la release 'world-state'
echo "[UPLOAD] Verificando release 'world-state' en $STORAGE_REPO..."
if ! gh release view world-state --repo "$STORAGE_REPO" >/dev/null 2>&1; then
    echo "[UPLOAD] Creando nueva release 'world-state'..."
    gh release create world-state --repo "$STORAGE_REPO" --title "NEXUS Persistent World State" --notes "Almacenamiento persistente del mundo NEXUS Java."
fi

# 3. Leer info del backup local
INFO_FILE="$BACKUP_DIR/backup-info.json"
if [ ! -f "$INFO_FILE" ]; then
    echo "[UPLOAD ERROR] Falta $INFO_FILE"
    exit 1
fi

HISTORICAL_NAME=$(grep '"archive"' "$INFO_FILE" | cut -d '"' -f 4)
LOCAL_SHA256=$(grep '"sha256"' "$INFO_FILE" | cut -d '"' -f 4)
HISTORICAL_FILE="$BACKUP_DIR/$HISTORICAL_NAME"

if [ ! -f "$HISTORICAL_FILE" ]; then
    echo "[UPLOAD ERROR] Falta el archivo histórico $HISTORICAL_FILE"
    exit 1
fi

# 4. Subir el asset único del run actual
echo "[UPLOAD] Subiendo asset único $HISTORICAL_NAME..."
gh release upload world-state "$HISTORICAL_FILE" --repo "$STORAGE_REPO" --clobber

# 5. Verificación de integridad remota (Descargar y verificar SHA-256)
echo "[UPLOAD VERIFY] Descargando asset recién subido para verificar integridad SHA-256..."
mkdir -p verify_temp
gh release download world-state --repo "$STORAGE_REPO" --pattern "$HISTORICAL_NAME" --dir verify_temp --clobber

if [ ! -f "verify_temp/$HISTORICAL_NAME" ]; then
    echo "[UPLOAD CRITICAL ERROR] No se pudo descargar el asset recién subido para verificación."
    exit 1
fi

REMOTE_SHA256=$(sha256sum "verify_temp/$HISTORICAL_NAME" | awk '{print $1}')

if [ "$LOCAL_SHA256" != "$REMOTE_SHA256" ]; then
    echo "[UPLOAD CRITICAL ERROR] SHA-256 mismatch! Local: $LOCAL_SHA256, Remoto: $REMOTE_SHA256"
    echo "[UPLOAD] La subida falló o se corrompió. world-current.tar.gz NO será actualizado."
    exit 1
else
    echo "[UPLOAD VERIFY SUCCESS] SHA-256 verificado correctamente: $REMOTE_SHA256"
fi
rm -rf verify_temp

# 6. Preservar mundo anterior y actualizar current SÓLO si la verificación fue exitosa
echo "[UPLOAD] Verificación superada. Procediendo a rotar world-current..."
mkdir -p rot_temp
if gh release download world-state --repo "$STORAGE_REPO" --pattern "world-current.tar.gz" --dir rot_temp --clobber 2>/dev/null; then
    if [ -f "rot_temp/world-current.tar.gz" ]; then
        mv "rot_temp/world-current.tar.gz" "$BACKUP_DIR/world-previous.tar.gz"
        echo "[ROTATION OK] Reposicionado world-current a world-previous.tar.gz"
    fi
fi
rm -rf rot_temp

# Preparar world-current.tar.gz localmente usando el backup verificado
cp "$HISTORICAL_FILE" "$BACKUP_DIR/world-current.tar.gz"

echo "[UPLOAD] Subiendo rotación final de world-current.tar.gz y world-previous.tar.gz..."
UPLOAD_FILES=("$BACKUP_DIR/world-current.tar.gz")
if [ -f "$BACKUP_DIR/world-previous.tar.gz" ]; then
    UPLOAD_FILES+=("$BACKUP_DIR/world-previous.tar.gz")
fi

gh release upload world-state "${UPLOAD_FILES[@]}" --repo "$STORAGE_REPO" --clobber

echo "[UPLOAD SUCCESS] Promoción remota atómica completada exitosamente."
exit 0
