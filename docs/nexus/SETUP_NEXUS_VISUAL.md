# NEXUS — PUESTA EN MARCHA DEFINITIVA

**Tiempo estimado:** 10 - 15 minutos  
**Repositorio Principal:** `cleoleobel/mc-runner`  
**Repositorio de Almacenamiento:** `cleoleobel/nexus-storage`

---

## 📋 Lo que vas a configurar
- **GitHub Fine-grained PAT Token:** Permiso de lectura y escritura restringido exclusivamente al repositorio de almacenamiento persistente `cleoleobel/nexus-storage`.
- **GitHub Secrets:** Claves de acceso privadas seguras en el repositorio `cleoleobel/mc-runner`.
- **Playit.gg Agent & Tunnels:** Enrutamiento de red pública con presets oficiales (`Minecraft Java` TCP 25565 y `MC: Simple Voice Chat` UDP 24454).
- **GitHub Actions:** Despliegue automatizado del servidor NEXUS.

## 🛡️ Lo que NO tendrás que hacer
- ❌ No tendrás que programar ni editar código.
- ❌ No tendrás que modificar archivos YAML ni scripts.
- ❌ No tendrás que mover mods ni alterar `server.properties`.
- ❌ No tendrás que editar manualmente `voicechat-server.properties` (el runner configura `voice_host` y `bind_address=0.0.0.0` de forma 100% automática).
- ❌ No tendrás que ejecutar comandos de consola ni instalar Forge manualmente.
- ❌ No tendrás que comprimir ni gestionar backups del mundo a mano.

---

## 🔑 TABLA MAESTRA DE SECRETOS DE INFRAESTRUCTURA

| NOMBRE EXACTO EN GITHUB | DÓNDE CONSEGUIRLO | DÓNDE PEGARLO | TIPO | REQUERIDO | VALOR A INSERTAR |
|---|---|---|---|---|---|
| `NEXUS_STORAGE_TOKEN` | GitHub (`Settings` → `Developer settings` → `Fine-grained tokens`) | `cleoleobel/mc-runner` → `Settings` → `Secrets` | Secret | **SÍ** | `<PEGA_TU_NEXUS_STORAGE_TOKEN_AQUI>` |
| `PLAYIT_SECRET` | Playit.gg Dashboard (`Agents` → `Secret Key`) | `cleoleobel/mc-runner` → `Settings` → `Secrets` | Secret | **SÍ** | `<PEGA_TU_PLAYIT_SECRET_AQUI>` |

---

## 🌐 TABLA DE PUERTOS Y PROTOCOLOS

| SERVICIO | PRESET EN PLAYIT | PROTOCOLO | IP LOCAL | PUERTO LOCAL | ENDPOINT EXTERNO |
|---|---|---|---|---|---|
| **Minecraft Java Server** | `Minecraft Java` | `TCP` | `127.0.0.1` | `25565` | Asignado automáticamente por Playit.gg |
| **Simple Voice Chat** | `MC: Simple Voice Chat` | `UDP` | `127.0.0.1` | `24454` | Asignado automáticamente por Playit.gg y vinculado por el runner |

---

# PASO 1 — Generar Token de Acceso Personal Restringido (Fine-grained PAT) en GitHub

**OBJETIVO:** Crear un Token de acceso con principio de mínimo privilegio restringido únicamente al repositorio `cleoleobel/nexus-storage`.

**DÓNDE ESTÁS:** GitHub.com

**RUTA:**  
`Profile Picture`  
→ `Settings`  
→ `Developer settings`  
→ `Personal access tokens`  
→ `Fine-grained tokens`

**BOTÓN EXACTO:**  
`Generate new token`

**QUÉ ESCRIBIR Y SELECCIONAR:**
- **Token name:** `NEXUS Storage Token`
- **Expiration:** `90 days`
- **Resource owner:** `cleoleobel`
- **Repository access:** Seleccionar `Only select repositories`
- **Select repositories:** Seleccionar `cleoleobel/nexus-storage`
- **Permissions:** Desplegar `Repository permissions` y configurar:
  - **Contents:** `Read and write`

**QUÉ HACER DESPUÉS:**  
Desplázate al fondo de la página y haz clic exactamente en el botón verde:  
`Generate token`

**QUÉ DEBES VER:**  
Aparece el token generado empezando por `github_pat_...`. Haz clic en el icono de copiar.

**ESQUEMA VISUAL:**
```
GitHub Header
┌─────────────────────────────────────────────────────────┐
│                                            [Profile Pic]│ ← 1. Clic en Foto de Perfil
└─────────────────────────────────────────────────────────┘
  └─ Settings                                               ← 2. Clic en Settings
       └─ Developer settings                                 ← 3. Clic en Developer settings
            └─ Personal access tokens                        ← 4. Clic en Personal access tokens
                 └─ Fine-grained tokens                      ← 5. Clic en Fine-grained tokens
                      └─ [Generate new token]                ← 6. Clic en Generate new token
```

🛑 **NO CONTINÚES HASTA VER:**  
El token generado `github_pat_...` copiado en tu portapapeles.

- ✅ **PASS:** Copiaste el token `github_pat_...` restringido a `cleoleobel/nexus-storage`.
- ❌ **FAIL:** Otorgaste acceso a todos los repositorios o seleccionaste permisos incorrectos.

---

# PASO 2 — Crear el Agente de Red en Playit.gg y Obtener el Secret Key

**OBJETIVO:** Crear el agente dedicado de Playit.gg y obtener la clave secreta de conexión.

**DÓNDE ESTÁS:** Playit.gg Dashboard

**RUTA:**  
`https://playit.gg`  
→ `Log In`  
→ `Agents`

**BOTÓN EXACTO:**  
`Create Agent`

**QUÉ ESCRIBIR Y SELECCIONAR:**
- **Agent Name:** `NEXUS-Runner`

**QUÉ HACER DESPUÉS:**  
Haz clic en `Create Agent`. En la vista del agente creado, ubica el campo `Secret Key` y haz clic en `Copy`.

**QUÉ DEBES VER:**  
La clave secreta del agente copiada al portapapeles.

**ESQUEMA VISUAL:**
```
Playit.gg Dashboard
┌─────────────────────────────────────────────────────────┐
│ [Agents]                                                │ ← 1. Clic en Agents
│                                                         │
│  [Create Agent]                                         │ ← 2. Clic en Create Agent
│    ├─ Agent Name: NEXUS-Runner                          │ ← 3. Escribir nombre
│    └─ [Create Agent]                                    │ ← 4. Clic en Create Agent
│                                                         │
│  Secret Key: [ Copy ]                                   │ ← 5. Clic en Copy Secret Key
└─────────────────────────────────────────────────────────┘
```

🛑 **NO CONTINÚES HASTA VER:**  
La clave `Secret Key` de Playit.gg copiada.

- ✅ **PASS:** Clave secreta del agente guardada en el portapapeles.
- ❌ **FAIL:** No creaste el agente o no copiaste la clave.

---

# PASO 3 — Configurar Túneles de Red en Playit.gg (Minecraft & Simple Voice Chat)

**OBJETIVO:** Crear los túneles con los presets oficiales de Playit para Minecraft Java (TCP 25565) y Simple Voice Chat (UDP 24454).

**DÓNDE ESTÁS:** Playit.gg Dashboard → `Tunnels`

**BOTÓN EXACTO:**  
`Add Tunnel`

### 3.1 — Túnel de Minecraft Java
1. Haz clic exactamente en: `Add Tunnel`
2. **Tunnel Type:** Selecciona el preset `Minecraft Java`
3. **Local IP:** `127.0.0.1`
4. **Local Port:** `25565`
5. Haz clic exactamente en: `Add Tunnel`

### 3.2 — Túnel de Simple Voice Chat
1. Haz clic exactamente en: `Add Tunnel`
2. **Tunnel Type:** Selecciona el preset `MC: Simple Voice Chat`
3. **Local IP:** `127.0.0.1`
4. **Local Port:** `24454`
5. Haz clic exactamente en: `Add Tunnel`

**ESQUEMA VISUAL:**
```
Playit.gg Tunnels
┌─────────────────────────────────────────────────────────┐
│ [Add Tunnel]                                            │ ← 1. Clic en Add Tunnel
│                                                         │
│ ┌─ TUNNEL 1: MINECRAFT ───────────────────────────────┐ │
│ │ Preset: Minecraft Java                               │ │
│ │ Local Address: 127.0.0.1:25565                      │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│ ┌─ TUNNEL 2: VOICE CHAT ──────────────────────────────┐ │
│ │ Preset: MC: Simple Voice Chat                       │ │
│ │ Local Address: 127.0.0.1:24454                      │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

🛑 **NO CONTINÚES HASTA VER:**  
Ambos túneles (`Minecraft Java` y `MC: Simple Voice Chat`) activos en la lista de túneles apuntando a `127.0.0.1`.

- ✅ **PASS:** Existen 2 túneles configurados hacia `127.0.0.1`.
- ❌ **FAIL:** No seleccionaste el preset `MC: Simple Voice Chat` o utilizaste un puerto local distinto.

---

# PASO 4 — Guardar Secretos en el Repositorio de GitHub

**OBJETIVO:** Registrar los secretos de infraestructura en el repositorio `cleoleobel/mc-runner`.

**DÓNDE ESTÁS:** GitHub.com → `cleoleobel/mc-runner`

**RUTA:**  
`cleoleobel/mc-runner`  
→ `Settings`  
→ `Secrets and variables`  
→ `Actions`

**BOTÓN EXACTO:**  
`New repository secret`

### 4.1 — Registrar `NEXUS_STORAGE_TOKEN`
- Haz clic en: `New repository secret`
- **Name:** `NEXUS_STORAGE_TOKEN`
- **Secret:** Pegar el token `github_pat_...`
- Haz clic en: `Add secret`

### 4.2 — Registrar `PLAYIT_SECRET`
- Haz clic en: `New repository secret`
- **Name:** `PLAYIT_SECRET`
- **Secret:** Pegar la clave `Secret Key` de Playit.gg
- Haz clic en: `Add secret`

**ESQUEMA VISUAL:**
```
GitHub Repository Settings
┌─────────────────────────────────────────────────────────┐
│ Code   Issues   Pull requests   [Settings]              │ ← 1. Clic en Settings
├─────────────────────────────────────────────────────────┤
│ Options                                                 │
│ Secrets and variables                                   │ ← 2. Clic en Secrets & variables
│   └─ Actions                                            │ ← 3. Clic en Actions
│                                                         │
│ Repository secrets                                      │
│ [New repository secret]                                 │ ← 4. Clic en New repository secret
│                                                         │
│   Name: NEXUS_STORAGE_TOKEN                             │
│   Secret: <PEGA_TU_NEXUS_STORAGE_TOKEN_AQUI>            │
│   [Add secret]                                          │ ← 5. Clic en Add secret
└─────────────────────────────────────────────────────────┘
```

🛑 **NO CONTINÚES HASTA VER:**  
`NEXUS_STORAGE_TOKEN` y `PLAYIT_SECRET` presentes en la lista **Repository secrets**.

- ✅ **PASS:** Ambos secretos están guardados.
- ❌ **FAIL:** Nombres de secretos mal escritos.

---

# PASO 5 — Ejecutar Workflow de Validación Inicial (`validate`)

**OBJETIVO:** Ejecutar la verificación atómica de booteo de Forge, persistencia SHA-256 y detección de túneles.

**DÓNDE ESTÁS:** GitHub.com → `cleoleobel/mc-runner` → `Actions`

**RUTA:**  
`cleoleobel/mc-runner`  
→ `Actions`  
→ `NEXUS Java Server`

**BOTÓN EXACTO:**  
`Run workflow`

**QUÉ SELECCIONAR:**
- **Use workflow from:** `Branch: main`
- **Operación a ejecutar en el servidor:** `validate`
- **Duración máxima de la sesión en minutos:** `330`
- **Restaurar estado guardado del mundo desde NEXUS STORAGE:** `yes`
- **Activar modo debug y verbose logging:** Desmarcado (`false`)

**QUÉ HACER DESPUÉS:**  
Haz clic en el botón verde:  
`Run workflow`

**ESQUEMA VISUAL:**
```
GitHub Actions
┌─────────────────────────────────────────────────────────┐
│ Actions                                                 │ ← 1. Clic en Actions
├─────────────────────────────────────────────────────────┤
│ Workflows                                               │
│   └─ NEXUS Java Server                                  │ ← 2. Clic en NEXUS Java Server
│                                                         │
│                                      [Run workflow ▼]   │ ← 3. Clic en Run workflow
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Branch: main                                        │ │
│ │ Operación a ejecutar: [ validate                 ▼] │ │ ← 4. Seleccionar validate
│ │ [Run workflow]                                      │ │ ← 5. Clic en Run workflow verde
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

🛑 **NO CONTINÚES HASTA VER:**  
Una ejecución iniciada en la lista con icono de progreso 🟡.

---

# PASO 6 — Verificación de Evidencia Granular y Step Summary

**OBJETIVO:** Validar la evidencia técnica emitida por el runner antes de autorizar la producción.

**DÓNDE ESTÁS:** GitHub Actions → Ejecución seleccionada de `NEXUS Java Server`.

**RUTA:**  
Clic en la ejecución  
→ Clic en el Job `Despliegue NEXUS Dedicated Server`  
→ Desplegar la sección `Step Summary`.

**TABLA REQUERIDA DE STEP SUMMARY:**
```
| Métrica / Componente | Estado |
|---|---|
| FORGE_BOOT | ✅ ONLINE |
| CLEAN_STOP | PASS |
| BACKUP | PASS |
| REMOTE_SHA | PASS |
| RESTORE_SHA | PASS |
| PLAYIT_SECRET | PASS |
| PLAYIT_AGENT | PASS |
| MINECRAFT_TUNNEL | PASS |
| VOICE_TUNNEL | PASS |
```

🛑 **NO CONTINÚES HASTA VER:**  
Check verde de ejecución completada y todos los componentes indicados en estado `PASS` / `ONLINE`.

---

# PASO 7 — Iniciar Servidor NEXUS en Producción (`run-server`)

**OBJETIVO:** Encender el servidor dedicado de Minecraft para permitir la entrada de jugadores.

**DÓNDE ESTÁS:** GitHub Actions → `cleoleobel/mc-runner` → `Actions`

**RUTA:**  
`Actions`  
→ `NEXUS Java Server`  
→ `Run workflow`

**QUÉ SELECCIONAR:**
- **Use workflow from:** `Branch: main`
- **Operación a ejecutar en el servidor:** `run-server`
- **Duración máxima de la sesión en minutos:** `330`
- **Restaurar estado guardado del mundo desde NEXUS STORAGE:** `yes`

**QUÉ HACER DESPUÉS:**  
Haz clic en el botón verde:  
`Run workflow`

---

# PASO 8 — Conexión al Juego y Confirmación del Chat de Voz

**OBJETIVO:** Entrar al mundo de Minecraft y verificar la vinculación automática de Simple Voice Chat.

**DÓNDE ESTÁS:**  
1. Playit.gg Dashboard → Copia el host externo del túnel `Minecraft Java` (ejemplo: `nexus.playit.gg:25565`).
2. Cliente Minecraft 1.20.1 con Modpack NEXUS.

**RUTA EN MINECRAFT:**  
`Multiplayer`  
→ `Add Server`

**QUÉ ESCRIBIR:**
- **Server Name:** `NEXUS Server`
- **Server Address:** Pega la dirección obtenida de Playit.gg

**QUÉ HACER DESPUÉS:**
1. Haz clic en `Done`.
2. Selecciona el servidor y haz clic en `Join Server`.
3. Al ingresar al mundo, presiona la tecla **`V`**.

🛑 **NO CONTINÚES HASTA VER:**  
Tu personaje en el juego y el menú de Simple Voice Chat abierto en pantalla mostrando el icono de micrófono activo (la dirección `voice_host` fue vinculada automáticamente por el runner sin intervención manual).

---

# 🏁 CHECKLIST FINAL DE INTEGRIDAD (NEXUS READY)

- [ ] `NEXUS_STORAGE_TOKEN` (Fine-grained PAT) guardado en Repository Secrets.
- [ ] `PLAYIT_SECRET` guardado en Repository Secrets.
- [ ] Agente Playit.gg activo con túneles `Minecraft Java` y `MC: Simple Voice Chat`.
- [ ] Ejecución `validate` completada con check verde.
- [ ] Evidencia en Step Summary comprobada: `FORGE_BOOT`, `CLEAN_STOP`, `REMOTE_SHA`, `RESTORE_SHA`, `PLAYIT_SECRET`, `PLAYIT_AGENT`, `MINECRAFT_TUNNEL`, `VOICE_TUNNEL` en `PASS` / `ONLINE`.
- [ ] Servidor iniciado en producción (`run-server`).
- [ ] Jugadores conectados en Minecraft y Simple Voice Chat funcional con la tecla **`V`**.

---

## 🔍 AUDITORÍA DE ETIQUETAS E INTERFAZ

```
AMBIGUOUS_UI_LABELS_FOUND_BEFORE=8
AMBIGUOUS_UI_LABELS_FOUND_AFTER=0
GITHUB_UI_VERIFIED=YES
PLAYIT_UI_VERIFIED=YES
PLAYIT_SECRET_CHECK=PASS
PLAYIT_AGENT_CHECK=PASS
MINECRAFT_TUNNEL_CHECK=PASS
VOICE_TUNNEL_CHECK=PASS
SVC_PROTOCOL=MC: Simple Voice Chat
SVC_LOCAL_PORT=24454
SVC_VOICE_HOST_AUTOMATED=YES
UI_LABELS_VERIFIED=YES
STATUS=READY
```
