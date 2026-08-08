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
mkdir -p session_diagnostics
echo "UNVERIFIED" > session_diagnostics/status_restore_sha.txt

echo "[WORLD] Buscando puntero 'current-manifest.json' en release 'world-state'..."

if command -v gh >/dev/null 2>&1; then
    if gh release download world-state --repo "$STORAGE_REPO" --pattern "current-manifest.json" --dir "$WORLD_RESTORE_DIR" --clobber 2>/dev/null; then
        if [ -f "$WORLD_RESTORE_DIR/current-manifest.json" ]; then
            echo "[WORLD] Manifest encontrado. Analizando..."
            MANIFEST_FILE="$WORLD_RESTORE_DIR/current-manifest.json"
            TARGET_ASSET=$(grep '"asset"' "$MANIFEST_FILE" | cut -d '"' -f 4)
            EXPECTED_SHA=$(grep '"sha256"' "$MANIFEST_FILE" | cut -d '"' -f 4)
            
            if [ -z "$TARGET_ASSET" ] || [ -z "$EXPECTED_SHA" ]; then
                echo "[WORLD CRITICAL ERROR] El manifest está corrupto o le faltan campos."
                exit 1
            fi
            
            echo "[WORLD] Descargando snapshot apuntado: $TARGET_ASSET..."
            if gh release download world-state --repo "$STORAGE_REPO" --pattern "$TARGET_ASSET" --dir "$WORLD_RESTORE_DIR" --clobber 2>/dev/null; then
                if [ -f "$WORLD_RESTORE_DIR/$TARGET_ASSET" ]; then
                    echo "[WORLD] Calculando SHA-256 local..."
                    LOCAL_SHA=$(sha256sum "$WORLD_RESTORE_DIR/$TARGET_ASSET" | awk '{print $1}')
                    
                    if [ "$LOCAL_SHA" != "$EXPECTED_SHA" ]; then
                        echo "[WORLD CRITICAL ERROR] SHA-256 mismatch en restore!"
                        echo "Esperado: $EXPECTED_SHA"
                        echo "Calculado: $LOCAL_SHA"
                        echo "ABORTANDO para evitar extraer mundo corrupto."
                        exit 1
                    fi
                    
                    echo "[WORLD VERIFY SUCCESS] SHA-256 coincide perfectamente ($LOCAL_SHA)."
                    echo "PASS" > session_diagnostics/status_restore_sha.txt
                    echo "[WORLD] Extrayendo en staging aislado..."
                    
                    STAGING_DIR="world_staging_restore"
                    mkdir -p "$STAGING_DIR"
                    tar -xzf "$WORLD_RESTORE_DIR/$TARGET_ASSET" -C "$STAGING_DIR"
                    
                    # Dependiendo de cómo se comprimió (./world o el contenido), verificamos
                    if [ -d "$STAGING_DIR/world" ] && [ -f "$STAGING_DIR/world/level.dat" ]; then
                        echo "[WORLD] Estructura válida (level.dat encontrado en ./world)."
                        rm -rf ./world
                        mv "$STAGING_DIR/world" ./world
                    elif [ -f "$STAGING_DIR/level.dat" ]; then
                        echo "[WORLD] Estructura válida (level.dat encontrado en raíz)."
                        rm -rf ./world
                        mv "$STAGING_DIR" ./world
                    else
                        echo "[WORLD CRITICAL ERROR] Estructura del mundo inválida (level.dat no encontrado)."
                        exit 1
                    fi
                    
                    rm -rf "$WORLD_RESTORE_DIR" "$STAGING_DIR"
                    echo "[WORLD SUCCESS] Estado del mundo restaurado exitosamente desde $TARGET_ASSET."
                    exit 0
                fi
            fi
            echo "[WORLD CRITICAL ERROR] Fallo al descargar el asset $TARGET_ASSET especificado en el manifest."
            exit 1
        fi
    fi
fi

echo "[WORLD WARN] No se encontró 'current-manifest.json' o no se pudo descargar."
echo "[WORLD INFO] Se inicializará un mundo nuevo en esta sesión."
rm -rf "$WORLD_RESTORE_DIR"
