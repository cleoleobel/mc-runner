#!/usr/bin/env bash
# ==============================================================================
# NEXUS DISTRIBUTION - DOWNLOAD BUNDLE
# Descarga la distribución server-side desde NEXUS STORAGE Privado
# ==============================================================================

set -euo pipefail

STORAGE_REPO="${STORAGE_REPO:-cleoleobel/nexus-storage}"
DOWNLOAD_DIR="download_bundle"
mkdir -p "$DOWNLOAD_DIR"

echo "=================================================="
echo "   DESCARGANDO SERVER BUNDLE DESDE NEXUS STORAGE"
echo "   Storage Repo: $STORAGE_REPO"
echo "=================================================="

# 1. Configurar token para GitHub CLI si está provisto
if [ -z "${NEXUS_STORAGE_TOKEN:-}" ]; then
    echo "[DOWNLOAD ERROR] NEXUS_STORAGE_TOKEN is required."
    exit 1
fi
export GH_TOKEN="$NEXUS_STORAGE_TOKEN"

# 2. Descargar assets de la release 'server-bundle-latest'
echo "[DOWNLOAD] Obteniendo release 'server-bundle-latest'..."

cd "$DOWNLOAD_DIR"
rm -f server-bundle.tar.gz manifest.json checksums.sha256

if command -v gh >/dev/null 2>&1; then
    gh release download server-bundle-latest --repo "$STORAGE_REPO" \
        --pattern "server-bundle.tar.gz" \
        --pattern "manifest.json" \
        --pattern "checksums.sha256" \
        --clobber
else
    echo "[DOWNLOAD ERROR] GitHub CLI (gh) no está disponible."
    exit 1
fi

cd ..

if [ -f "$DOWNLOAD_DIR/server-bundle.tar.gz" ] && [ -f "$DOWNLOAD_DIR/checksums.sha256" ]; then
    echo "[DOWNLOAD OK] Archivos descargados exitosamente en $DOWNLOAD_DIR/"
    ls -lh "$DOWNLOAD_DIR"
else
    echo "[DOWNLOAD ERROR] No se pudieron descargar los archivos del server bundle desde $STORAGE_REPO."
    exit 1
fi
