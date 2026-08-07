#!/usr/bin/env bash
# ==============================================================================
# NEXUS WORLD PERSISTENCE - RESTORE WORLD
# Restaura el estado persistente del mundo desde NEXUS STORAGE
# ==============================================================================

set -euo pipefail

STORAGE_REPO="${STORAGE_REPO:-cleoleobel/nexus-storage}"
RESTORE_ENABLED="${RESTORE_WORLD:-yes}"

echo "=================================================="
echo "   RESTAURANDO ESTADO DEL MUNDO NEXUS"
echo "=================================================="

if [ "$RESTORE_ENABLED" != "yes" ]; then
    echo "[WORLD] Restauración desactivada por parámetro (RESTORE_WORLD=$RESTORE_ENABLED)."
    echo "[WORLD] Se generará un nuevo mundo o se utilizará el local existente."
    exit 0
fi

# Configurar token de GitHub CLI si está disponible
if [ -n "${NEXUS_STORAGE_TOKEN:-}" ]; then
    echo "$NEXUS_STORAGE_TOKEN" | gh auth login --with-token 2>/dev/null || true
fi

WORLD_RESTORE_DIR="world_download"
mkdir -p "$WORLD_RESTORE_DIR"

echo "[WORLD] Buscando release 'world-state' en $STORAGE_REPO..."

HAS_WORLD=false
if command -v gh >/dev/null 2>&1; then
    if gh release download world-state --repo "$STORAGE_REPO" --pattern "world-current.tar.gz" --dir "$WORLD_RESTORE_DIR" --clobber 2>/dev/null; then
        HAS_WORLD=true
    fi
fi

if [ "$HAS_WORLD" = true ] && [ -f "$WORLD_RESTORE_DIR/world-current.tar.gz" ]; then
    echo "[WORLD] Archivo de mundo encontrado (world-current.tar.gz). Extrayendo..."
    rm -rf ./world
    tar -xzf "$WORLD_RESTORE_DIR/world-current.tar.gz" -C ./
    rm -rf "$WORLD_RESTORE_DIR"
    echo "[WORLD SUCCESS] Estado del mundo restaurado exitosamente."
else
    echo "[WORLD WARN] No se encontró un mundo previo en la release 'world-state' de $STORAGE_REPO."
    echo "[WORLD INFO] Se inicializará un mundo nuevo en esta sesión."
    rm -rf "$WORLD_RESTORE_DIR"
fi
