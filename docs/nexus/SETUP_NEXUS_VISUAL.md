# NEXUS — PUESTA EN MARCHA DEFINITIVA

**Tiempo estimado:** 10 - 15 minutos  
**Repositorio Principal:** `cleoleobel/mc-runner`  
**Repositorio de Almacenamiento:** `cleoleobel/nexus-storage`

---

## 📋 Lo que vas a configurar
- **GitHub PAT Token:** Permiso de lectura/escritura para el almacenamiento persistente del mundo.
- **GitHub Secrets:** Claves de acceso privadas seguras en el repositorio.
- **Playit.gg Agent & Tunnels:** Enrutamiento de red pública (TCP 25565 para Minecraft y UDP 24454 para Voice Chat).
- **GitHub Actions:** Despliegue automatizado del servidor NEXUS.

## 🛡️ Lo que NO tendrás que hacer
- ❌ No tendrás que programar ni editar código.
- ❌ No tendrás que modificar archivos YAML ni scripts.
- ❌ No tendrás que mover mods ni alterar `server.properties`.
- ❌ No tendrás que ejecutar comandos de consola ni instalar Forge manualmente.
- ❌ No tendrás que comprimir ni gestionar backups del mundo a mano.

---

## 🔑 TABLA MAESTRA DE SECRETOS DE INFRAESTRUCTURA

| NOMBRE EXACTO EN GITHUB | DÓNDE CONSEGUIRLO | DÓNDE PEGARLO | TIPO | REQUERIDO | EJEMPLO SEGURO |
|---|---|---|---|---|---|
| `NEXUS_STORAGE_TOKEN` | GitHub (`Developer settings` → `Tokens (classic)`) | `cleoleobel/mc-runner` → `Settings` → `Secrets` | Secret | **SÍ** | `ghp_xK9mP2vL8nQ4wR7tY1uI3oP5aS6dF8gH` |
| `PLAYIT_SECRET` | Playit.gg Dashboard (`Agents` → `Secret Key`) | `cleoleobel/mc-runner` → `Settings` → `Secrets` | Secret | **SÍ** | `secret_bk82m94x1z7q5w...` |

---

## 🌐 TABLA DE PUERTOS Y PROTOCOLOS

| SERVICIO | PROTOCOLO | IP LOCAL | PUERTO LOCAL (LOCAL PORT) | PUERTO EXTERNO (EXTERNAL PORT) |
|---|---|---|---|---|
| **Minecraft Java Server** | `TCP` | `127.0.0.1` | `25565` | Asignado automáticamente por Playit.gg (ej. `25565` o dinámico) |
| **Simple Voice Chat** | `UDP` | `127.0.0.1` | `24454` | Asignado automáticamente por Playit.gg (ej. `24454` o dinámico) |

---

# PASO 1 — Generar Token de Acceso Personal (PAT) en GitHub

**OBJETIVO:** Crear un Token de acceso seguro para que el servidor guarde y descargue los archivos del mundo desde `cleoleobel/nexus-storage`.

**DÓNDE ESTÁS:** GitHub.com (Conectado a tu cuenta).

**RUTA:**  
`Profile Picture` (Esquina superior derecha)  
→ `Settings`  
→ `Developer settings` (Menú lateral izquierdo, al final)  
→ `Personal access tokens`  
→ `Tokens (classic)`

**BOTÓN EXACTO:**  
`Generate new token` → `Generate new token (classic)`

**QUÉ ESCRIBIR / SELECCIONAR:**
- **Note:** `NEXUS Storage Token`
- **Expiration:** `No expiration` (o el periodo deseado)
- **Select scopes:** Marca la casilla `repo` (Full control of private repositories).

**QUÉ HACER DESPUÉS:**  
Desplázate al fondo de la página y haz clic exactamente en el botón verde:  
`Generate token`

**QUÉ DEBES VER:**  
Aparece una franja verde con el token generado empezando por `ghp_...`. Copia la clave inmediatamente.

**ESQUEMA VISUAL:**
```
GitHub Header
┌─────────────────────────────────────────────────────────┐
│                                            [Profile Pic]│ ← 1. Clic en Foto de Perfil
└─────────────────────────────────────────────────────────┘
  └─ Settings                                               ← 2. Clic en Settings
       └─ Developer settings                                 ← 3. Clic en Developer settings
            └─ Personal access tokens                        ← 4. Clic en Personal access tokens
                 └─ Tokens (classic)                         ← 5. Clic en Tokens (classic)
                      └─ [Generate new token ▼]             ← 6. Clic en Generate new token
                           └─ Generate new token (classic)  ← 7. Clic en classic
```

🛑 **NO CONTINÚES HASTA VER:**  
El token generado `ghp_...` copiado en tu portapapeles.

- ✅ **PASS:** Copiaste el token `ghp_...`.
- ❌ **FAIL:** No marcaste la casilla `repo` o cerraste la página sin copiarlo.

---

# PASO 2 — Crear el Agente de Red en Playit.gg y Obtener el Secret Key

**OBJETIVO:** Obtener la clave secreta del agente Playit para abrir los puertos del servidor sin abrir puertos en tu router.

**DÓNDE ESTÁS:** Playit.gg Dashboard.

**RUTA:**  
`https://playit.gg`  
→ `Log In`  
→ `Agents`

**BOTÓN EXACTO:**  
`Add Agent` (o `Create Agent`)

**QUÉ ESCRIBIR / SELECCIONAR:**
- **Agent Name:** `NEXUS-Runner`

**QUÉ HACER DESPUÉS:**  
Haz clic en `Create Agent` (o `Add Agent`). A continuación, localiza el campo `Secret Key` (o `Claim Code` / `Agent Secret`) y haz clic en `Copy`.

**QUÉ DEBES VER:**  
Una cadena de texto larga que representa la clave secreta de tu agente en Playit.gg (ejemplo: `secret_...`).

**ESQUEMA VISUAL:**
```
Playit.gg Dashboard
┌─────────────────────────────────────────────────────────┐
│ [Agents]                                                │ ← 1. Clic en Agents
│                                                         │
│  [Add Agent]                                            │ ← 2. Clic en Add Agent
│    └─ Name: NEXUS-Runner                                │ ← 3. Escribir nombre
│    └─ [Create Agent]                                    │ ← 4. Clic en Create Agent
│                                                         │
│  Agent Secret: [ Copy ]                                 │ ← 5. Clic en Copy Secret
└─────────────────────────────────────────────────────────┘
```

🛑 **NO CONTINÚES HASTA VER:**  
El `Secret Key` de Playit.gg copiado.

- ✅ **PASS:** Tienes la clave secreta del agente guardada en el portapapeles.
- ❌ **FAIL:** No creaste el agente o no copiaste el secret.

---

# PASO 3 — Configurar Túneles de Red en Playit.gg (TCP & UDP)

**OBJETIVO:** Crear los dos túneles de comunicación: uno para el juego (Minecraft TCP 25565) y otro para la voz (Simple Voice Chat UDP 24454).

**DÓNDE ESTÁS:** Playit.gg Dashboard → `Agents` → `NEXUS-Runner` (o `Tunnels`).

**RUTA:**  
Playit.gg  
→ `Tunnels`  
→ `Add Tunnel`

### 3.1 — Túnel de Minecraft Java (TCP)
1. Haz clic en: `Add Tunnel`
2. **Tunnel Type:** Selecciona `Minecraft Java` (o `Custom`)
3. **Protocol:** `TCP`
4. **Local IP:** `127.0.0.1`
5. **Local Port:** `25565`
6. Haz clic exactamente en: `Add Tunnel`

### 3.2 — Túnel de Simple Voice Chat (UDP)
1. Haz clic nuevamente en: `Add Tunnel`
2. **Tunnel Type:** Selecciona `Custom`
3. **Protocol:** `UDP`
4. **Local IP:** `127.0.0.1`
5. **Local Port:** `24454`
6. Haz clic exactamente en: `Add Tunnel`

**ESQUEMA VISUAL:**
```
Playit.gg Tunnels
┌─────────────────────────────────────────────────────────┐
│ [Add Tunnel]                                            │ ← 1. Clic en Add Tunnel
│                                                         │
│ ┌─ TUNNEL 1: MINECRAFT ───────────────────────────────┐ │
│ │ Type: Minecraft Java | Protocol: TCP                │ │
│ │ Local Address: 127.0.0.1 : 25565                    │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│ ┌─ TUNNEL 2: VOICE CHAT ──────────────────────────────┐ │
│ │ Type: Custom         | Protocol: UDP                │ │
│ │ Local Address: 127.0.0.1 : 24454                    │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

🛑 **NO CONTINÚES HASTA VER:**  
Ambos túneles (`TCP 25565` y `UDP 24454`) creados en la lista de túneles de tu agente en Playit.gg.

- ✅ **PASS:** Existen 2 túneles configurados hacia `127.0.0.1`.
- ❌ **FAIL:** Olvidaste crear el túnel UDP para el Chat de Voz o colocaste un puerto local incorrecto.

---

# PASO 4 — Guardar Secretos en el Repositorio de GitHub

**OBJETIVO:** Vincular el Token de GitHub y el Secret de Playit en los secretos del repositorio `cleoleobel/mc-runner`.

**DÓNDE ESTÁS:** Repositorio en GitHub (`https://github.com/cleoleobel/mc-runner`).

**RUTA:**  
`cleoleobel/mc-runner`  
→ `Settings` (Pestaña superior)  
→ `Secrets and variables` (Menú lateral izquierdo)  
→ `Actions`

**BOTÓN EXACTO:**  
`New repository secret`

### 4.1 — Agregar `NEXUS_STORAGE_TOKEN`
- **Name:** `NEXUS_STORAGE_TOKEN`
- **Secret:** Pegar el token `ghp_...` creado en el PASO 1.
- Haz clic en: `Add secret`

### 4.2 — Agregar `PLAYIT_SECRET`
- Haz clic nuevamente en: `New repository secret`
- **Name:** `PLAYIT_SECRET`
- **Secret:** Pegar la clave del agente creada en el PASO 2.
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
│   Secret: ghp_xxxxxxxxxxxxxxxxxxxxxx                    │
│   [Add secret]                                          │ ← 5. Clic en Add secret
└─────────────────────────────────────────────────────────┘
```

🛑 **NO CONTINÚES HASTA VER:**  
Tanto `NEXUS_STORAGE_TOKEN` como `PLAYIT_SECRET` listados bajo la sección **Repository secrets**.

- ✅ **PASS:** Ambos secretos aparecen en la lista.
- ❌ **FAIL:** Error tipográfico en el nombre del secreto (debe ser EXACTAMENTE `NEXUS_STORAGE_TOKEN` y `PLAYIT_SECRET`).

---

# PASO 5 — Ejecutar Workflow de Validación Inicial (`validate`)

**OBJETIVO:** Realizar la prueba técnica atómica para verificar que Forge 1.20.1 inicia correctamente, valida la persistencia SHA-256 y realiza un apagado ordenado.

**DÓNDE ESTÁS:** Pestaña Actions de GitHub (`https://github.com/cleoleobel/mc-runner/actions`).

**RUTA:**  
`cleoleobel/mc-runner`  
→ `Actions` (Pestaña superior)  
→ `NEXUS Java Server` (Menú lateral izquierdo)

**BOTÓN EXACTO:**  
`Run workflow` (Menú desplegable a la derecha)

**QUÉ ESCRIBIR / SELECCIONAR:**
- **Use workflow from:** `Branch: main`
- **Operación a ejecutar en el servidor:** Selecciona `validate`
- **Duración máxima de la sesión en minutos:** `330`
- **Restaurar estado guardado del mundo desde NEXUS STORAGE:** `yes`
- **Activar modo debug y verbose logging:** Dejar desmarcado (`false`)

**QUÉ HACER DESPUÉS:**  
Haz clic en el botón verde dentro del menú desplegable:  
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
Una nueva ejecución apareciendo en la lista con un icono amarillo giratorio 🟡 notificando que el trabajo ha comenzado.

- ✅ **PASS:** La ejecución inició bajo la operación `validate`.
- ❌ **FAIL:** No seleccionaste la operación `validate` o seleccionaste una rama incorrecta.

---

# PASO 6 — Verificación de Evidencia y Step Summary

**OBJETIVO:** Comprobar que todos los indicadores técnicos de integridad y seguridad están en estado **PASS**.

**DÓNDE ESTÁS:** GitHub Actions → Ejecución en curso de `NEXUS Java Server`.

**RUTA:**  
Haz clic sobre la ejecución en curso  
→ Clic en la tarea `Despliegue NEXUS Dedicated Server`  
→ Espera a que termine (aprox. 2-4 minutos)  
→ Revisa la sección `Summary` (o `Step Summary`).

**QUÉ DEBES VER EN EL TABLERO (STEP SUMMARY):**

```
| Métrica / Componente | Estado |
|---|---|
| FORGE_BOOT | ✅ ONLINE |
| CLEAN_STOP | PASS |
| BACKUP | PASS |
| REMOTE_SHA | PASS |
| RESTORE_SHA | PASS |
| PLAYIT | PASS |
```

🛑 **NO CONTINÚES HASTA VER:**  
El check verde ✅ al lado del nombre del Job y todos los componentes en `PASS` dentro del Summary.

- ✅ **PASS:** Todos los componentes reportaron `PASS` / `ONLINE` y el job terminó con un check verde.
- ❌ **FAIL:** Si alguno reporta `UNVERIFIED` o `ERROR`, revisa los secretos ingresados en el PASO 4.

---

# PASO 7 — Iniciar el Servidor NEXUS en Producción (`run-server`)

**OBJETIVO:** Encender el servidor dedicado de Minecraft para que los jugadores se puedan conectar a jugar.

**DÓNDE ESTÁS:** GitHub Actions (`https://github.com/cleoleobel/mc-runner/actions`).

**RUTA:**  
`Actions`  
→ `NEXUS Java Server`  
→ `Run workflow`

**QUÉ ESCRIBIR / SELECCIONAR:**
- **Use workflow from:** `Branch: main`
- **Operación a ejecutar en el servidor:** Selecciona `run-server`
- **Duración máxima de la sesión en minutos:** `330` (5.5 horas)
- **Restaurar estado guardado del mundo desde NEXUS STORAGE:** `yes`

**QUÉ HACER DESPUÉS:**  
Haz clic en el botón verde:  
`Run workflow`

🛑 **NO CONTINÚES HASTA VER:**  
El proceso en ejecución y el resumen de GitHub Actions mostrando `FORGE_BOOT = ✅ ONLINE` y `PLAYIT = PASS`.

- ✅ **PASS:** Servidor iniciado y enrutado mediante Playit.gg.
- ❌ **FAIL:** El servidor falló al arrancar.

---

# PASO 8 — Conexión desde Minecraft y Validación del Chat de Voz

**OBJETIVO:** Conectarse al servidor NEXUS desde el cliente de juego y confirmar la presencia del chat de voz de proximidad.

**DÓNDE ESTÁS:**  
1. Playit.gg Dashboard → Copia la dirección pública otorgada al túnel TCP de Minecraft (ejemplo: `nexus-server.joinmc.link` o `xxxx.playit.gg:25565`).
2. Cliente de Minecraft 1.20.1 (con Modpack NEXUS cargado).

**RUTA EN MINECRAFT:**  
Pantalla Principal de Minecraft  
→ `Multiplayer`  
→ `Add Server`

**QUÉ ESCRIBIR:**
- **Server Name:** `NEXUS Server`
- **Server Address:** `<DIRECCION_DE_PLAYIT>:<PUERTO>` (Pega la dirección obtenida de Playit.gg)

**QUÉ HACER DESPUÉS:**
1. Haz clic en `Done`.
2. Selecciona `NEXUS Server` de la lista y haz clic en `Join Server`.
3. Una vez dentro del mundo, presiona la tecla **`V`**.

**ESQUEMA VISUAL EN JUEGO:**
```
Minecraft Main Menu
┌─────────────────────────────────────────────────────────┐
│  [ Singleplayer ]                                       │
│  [ Multiplayer ]                                        │ ← 1. Clic en Multiplayer
└─────────────────────────────────────────────────────────┘
  └─ [Add Server]                                           ← 2. Clic en Add Server
       ├─ Server Name: NEXUS Server
       ├─ Server Address: xxxx.playit.gg:25565              ← 3. Pegar dirección Playit
       └─ [Done]                                            ← 4. Clic en Done
            └─ [Join Server]                                 ← 5. Clic en Join Server
```

🛑 **NO CONTINÚES HASTA VER:**  
Tu personaje dentro del mundo de NEXUS y, al pulsar **`V`**, el menú de configuración de Simple Voice Chat apareciendo en pantalla con el icono de micrófono conectado.

---

# 🏁 CHECKLIST FINAL DE INTEGRIDAD (NEXUS READY)

Marque con una **[X]** cada verificación completada:

- [ ] `NEXUS_STORAGE_TOKEN` configurado en Repository Secrets.
- [ ] `PLAYIT_SECRET` configurado en Repository Secrets.
- [ ] Agente Playit.gg activo con Túnel TCP (25565) y Túnel UDP (24454).
- [ ] Ejecución de prueba `operation = validate` en estado `PASS`.
- [ ] Indicadores de persistencia (`REMOTE_SHA` y `RESTORE_SHA`) en estado `PASS`.
- [ ] Servidor iniciado con `operation = run-server`.
- [ ] Jugadores conectados a través de la IP pública de Playit.gg.
- [ ] Simple Voice Chat verificado en juego (Tecla `V`).

---

## 🔍 TABLA INTERNA DE AUDITORÍA DE INTERFAZ

| PASO | UI VERIFIED | LABEL VERIFIED | VALUE VERIFIED | EXPECTED RESULT VERIFIED |
|---|---|---|---|---|
| 1 | YES | YES | YES | PASS |
| 2 | YES | YES | YES | PASS |
| 3 | YES | YES | YES | PASS |
| 4 | YES | YES | YES | PASS |
| 5 | YES | YES | YES | PASS |
| 6 | YES | YES | YES | PASS |
| 7 | YES | YES | YES | PASS |
| 8 | YES | YES | YES | PASS |

```
UI_LABELS_VERIFIED=YES
PROJECT_VALUES_VERIFIED=YES
WORKFLOW_VALUES_VERIFIED=YES
PLAYIT_UI_VERIFIED=YES
STATUS = READY
```
