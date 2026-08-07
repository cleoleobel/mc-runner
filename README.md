# Repositorio Runner de Servidores (Bedrock & NEXUS Java)

Repositorio **público** que contiene los workflows de GitHub Actions y scripts de despliegue.

## Servidores Soportados en este Runner

1. **Servidor Bedrock** (`.github/workflows/servidor.yml`)
2. **NEXUS Java Dedicated Server 1.20.1 Forge** (`.github/workflows/nexus.yml`)

---

## ⚔️ NEXUS Java Dedicated Server (Minecraft 1.20.1 Forge 47.4.0)

### Arquitectura NEXUS (Dual Repository)

| Componente | Repositorio | Visibilidad | Descripción |
|---|---|---|---|
| **Runner** | `cleoleobel/mc-runner` | **Público** | Contiene los scripts POSIX, herramientas PowerShell y workflow `.github/workflows/nexus.yml`. |
| **Storage** | `cleoleobel/nexus-storage` | **Privado** | Almacena los paquetes inmutables `server-bundle.tar.gz` y el estado persistente del mundo (`world-current.tar.gz`). |

### Configuración de Secretos en GitHub

En `Settings → Secrets and variables → Actions → Secrets`:

- `NEXUS_STORAGE_TOKEN`: Personal Access Token (Fine-Grained) con permiso `Contents: Read and write` en `cleoleobel/nexus-storage`.
- `PLAYIT_SECRET`: Secret Key de Playit.gg para enrutamiento público (TCP 25565 + UDP 24454).

### Arranque del Servidor NEXUS
`Actions → NEXUS Java Server → Run workflow`
- **operation**: `run-server` (normal), `pregen` (pre-generación de chunks), `validate` (prueba rápida sin jugadores).

---

## 🧱 Servidor Bedrock

Repositorio público que contiene el workflow Bedrock. Los packs viven en el repositorio privado `villasori466-hub/server-minecraft-bedrock`.

### Configuración Bedrock

**Variable (`Settings → Variables`):**
- `REPO_PACKS`: `villasori466-hub/server-minecraft-bedrock`

**Secretos (`Settings → Secrets`):**
- `PACKS_TOKEN`: `Contents: read` sobre el repo de packs.
- `CHAIN_TOKEN`: `Actions: read and write` sobre este repo.
- `PORTMAP_OVPN`: Fichero `.ovpn` entero de portmap.io.
- `PLAYIT_SECRET`: Secret Key de Playit.gg.

### Arranque Bedrock
`Actions → Servidor Bedrock → Run workflow`

---

## Documentación NEXUS

- [Guía de Configuración de Usuario](SETUP_NEXUS.md)
- [Arquitectura Técnica de NEXUS](docs/nexus/ARCHITECTURE.md)
- [Manifiesto de Mods y Auditoría Server-Side](docs/nexus/SERVER_MOD_MANIFEST.md)
- [Guía de Resolución de Problemas](docs/nexus/TROUBLESHOOTING.md)
- [Migración 24/7 a Oracle Cloud A1](docs/nexus/MIGRATION_TO_ORACLE.md)
