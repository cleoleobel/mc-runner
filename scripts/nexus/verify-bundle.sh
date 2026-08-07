#!/usr/bin/env bash
# ==============================================================================
# NEXUS DISTRIBUTION - VERIFY BUNDLE SHA-256
# Valida la integridad criptográfica del server bundle descargado
# ==============================================================================

set -euo pipefail

DOWNLOAD_DIR="download_bundle"

echo "=== VERIFICANDO INTEGRIDAD DEL SERVER BUNDLE ==="

if [ ! -d "$DOWNLOAD_DIR" ]; then
    echo "[VERIFY ERROR] No existe el directorio $DOWNLOAD_DIR"
    exit 1
fi

cd "$DOWNLOAD_DIR"

if [ -f "checksums.sha256" ]; then
    echo "[VERIFY] Comprobando suma de verificación SHA-256..."
    sha256sum -c checksums.sha256
    echo "[VERIFY SUCCESS] El archivo server-bundle.tar.gz es válido y su firma coincide."
else
    echo "[VERIFY ERROR] No se encontró checksums.sha256"
    exit 1
fi

if [ -f "manifest.json" ]; then
    echo "[VERIFY MANIFEST] Información de distribución:"
    cat manifest.json
fi

cd ..
