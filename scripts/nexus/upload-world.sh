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
    echo "$NEXUS_STORAGE_TOKEN" | gh auth login --with-token 2>/dev/null || true
fi

# 2. Asegurar que exista la release 'world-state'
echo "[UPLOAD] Verificando release 'world-state' en $STORAGE_REPO..."
if ! gh release view world-state --repo "$STORAGE_REPO" >/dev/null 2>&1; then
    echo "[UPLOAD] Creando nueva release 'world-state'..."
    gh release create world-state --repo "$STORAGE_REPO" --title "NEXUS Persistent World State" --notes "Almacenamiento persistente del mundo NEXUS Java." || true
fi

# 3. Preservar mundo anterior (world-previous.tar.gz)
echo "[UPLOAD] Descargando estado previo para rotación..."
mkdir -p rot_temp
if gh release download world-state --repo "$STORAGE_REPO" --pattern "world-current.tar.gz" --dir rot_temp --clobber 2>/dev/null; then
    if [ -f "rot_temp/world-current.tar.gz" ]; then
        mv "rot_temp/world-current.tar.gz" "$BACKUP_DIR/world-previous.tar.gz"
        echo "[ROTATION OK] Reposicionado world-current a world-previous.tar.gz"
    fi
fi
rm -rf rot_temp

# 4. Preparar world-current.tar.gz
cp "$TEMP_BACKUP" "$BACKUP_DIR/world-current.tar.gz"

# 5. Subir lote a GitHub Release
HISTORICAL_FILE=$(find "$BACKUP_DIR" -name "world-backup-*.tar.gz" | head -n 1)

echo "[UPLOAD] Subiendo archivos de respaldo a la release 'world-state'..."

UPLOAD_FILES=("$BACKUP_DIR/world-current.tar.gz")
if [ -f "$BACKUP_DIR/world-previous.tar.gz" ]; then
    UPLOAD_FILES+=("$BACKUP_DIR/world-previous.tar.gz")
fi
if [ -n "$HISTORICAL_FILE" ] && [ -f "$HISTORICAL_FILE" ]; then
    UPLOAD_FILES+=("$HISTORICAL_FILE")
fi

gh release upload world-state "${UPLOAD_FILES[@]}" --repo "$STORAGE_REPO" --clobber

# 6. Verificación remota
echo "[UPLOAD VERIFY] Comprobando disponibilidad del backup subido..."
REMOTE_SIZE=$(gh release view world-state --repo "$STORAGE_REPO" --json assets --jq '.assets[] | select(.name=="world-current.tar.gz") | .size' 2>/dev/null || echo "0")

if [ "$REMOTE_SIZE" -gt 1000 ]; then
    echo "[UPLOAD SUCCESS] El respaldo world-current.tar.gz está verificado en GitHub Releases ($REMOTE_SIZE bytes)."
    rm -rf "$BACKUP_DIR"
    exit 0
else
    echo "[UPLOAD ERROR CRÍTICO] La subida de world-current.tar.gz falló o el archivo está incompleto."
    exit 1
fi
