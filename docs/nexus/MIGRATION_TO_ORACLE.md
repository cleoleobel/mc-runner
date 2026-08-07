# Guía de Migración de NEXUS a VPS 24/7 (Oracle Cloud A1 / Ubuntu 22.04)

Toda la infraestructura de scripts de **NEXUS** ha sido construida para ser **100% portable** y funcionar idénticamente en un VPS dedicado de **Oracle Cloud Infrastructure (A1 Ampere ARM64 o x86_64)**.

---

## 1. Requisitos del VPS
- **Sistema Operativo:** Ubuntu 22.04 LTS
- **CPU:** 4 vCPU (Recomendado Oracle A1 Flex)
- **RAM:** 12 GB a 24 GB RAM (Totalmente gratis en Oracle Always Free)
- **Disco:** 50 GB NVMe

---

## 2. Instalación y Despliegue en 3 Comandos

Conéctate vía SSH a tu servidor Ubuntu y ejecuta:

```bash
# 1. Clonar el repositorio runner
git clone https://github.com/cleoleobel/mc-runner.git /opt/nexus
cd /opt/nexus

# 2. Configurar variables de entorno
export NEXUS_STORAGE_TOKEN="tu_github_token_aqui"
export PLAYIT_SECRET="tu_playit_secret_aqui"

# 3. Lanzar el bootstrapper de NEXUS
bash scripts/nexus/bootstrap.sh --operation run-server --restore-world yes
```

El script `bootstrap.sh` se encargará automáticamente de:
1. Instalar Java 17 OpenJDK.
2. Descargar el server bundle oficial desde `cleoleobel/nexus-storage`.
3. Verificar la firma SHA-256.
4. Restaurar la partida guardada actual.
5. Iniciar Forge 1.20.1 con cálculo dinámico de RAM.
6. Iniciar el agente de túnel Playit.gg.

---

## 3. Configuración como Servicio de Systemd (Ejecución 24/7)

Para que el servidor se mantenga activo de forma continua y se inicie automáticamente con el sistema, crea el archivo `/etc/systemd/system/nexus.service`:

```ini
[Unit]
Description=NEXUS Dedicated Minecraft Java Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/nexus
Environment="NEXUS_STORAGE_TOKEN=tu_token_aqui"
Environment="PLAYIT_SECRET=tu_playit_secret_aqui"
ExecStart=/bin/bash /opt/nexus/scripts/nexus/bootstrap.sh --operation run-server --restore-world yes
ExecStop=/bin/bash /opt/nexus/scripts/nexus/stop-server.sh
Restart=on-failure
RestartSec=30s

[Transient]
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

### Activar y Arrancar Servicio:
```bash
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus
```

### Comprobar Estado y Logs:
```bash
sudo systemctl status nexus
journalctl -u nexus -f
```
