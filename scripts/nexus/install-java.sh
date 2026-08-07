#!/usr/bin/env bash
# ==============================================================================
# NEXUS ENVIRONMENT SETUP - JAVA 17 INSTALLER
# Verifica e instala OpenJDK 17 en Linux Runner
# ==============================================================================

set -euo pipefail

echo "=== VERIFICANDO ENTORNO JAVA 17 ==="

NEED_INSTALL=true

if command -v java >/dev/null 2>&1; then
    JAVA_VER=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
    if [ "$JAVA_VER" = "17" ]; then
        echo "[JAVA OK] Java 17 ya está instalado: $(java -version 2>&1 | head -n 1)"
        NEED_INSTALL=false
    else
        echo "[JAVA WARN] Java $JAVA_VER detectado. Se requiere exactamente Java 17."
    fi
fi

if [ "$NEED_INSTALL" = true ]; then
    echo "[JAVA] Instalando OpenJDK 17..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq openjdk-17-jre-headless tar zstd curl
    else
        echo "[JAVA ERROR] Administrador de paquetes no compatible. Instala Java 17 manualmente."
        exit 1
    fi
    echo "[JAVA SUCCESS] Java 17 instalado correctamente: $(java -version 2>&1 | head -n 1)"
fi
