# Guía de Resolución de Problemas (Troubleshooting) NEXUS Server

## 1. Error de Autenticación de Storage (NEXUS_STORAGE_TOKEN)

### Síntoma
El workflow falla en la Etapa 1 o Etapa 4 con error `404 Not Found` o `Resource not accessible by integration`.

### Causa
El token `NEXUS_STORAGE_TOKEN` no está configurado en Secrets o carece de permisos de lectura/escritura sobre el repositorio privado `cleoleobel/nexus-storage`.

### Solución
1. Ve a tu cuenta de GitHub > **Settings > Developer Settings > Personal Access Tokens > Fine-Grained Tokens**.
2. Genera un nuevo token asignado al repositorio `cleoleobel/nexus-storage`.
3. Permisos requeridos:
   - `Repository permissions > Contents: Read and write`
4. Copia el token generado.
5. En el repositorio runner `cleoleobel/mc-runner` ve a **Settings > Secrets and variables > Actions > Secrets** y actualiza `NEXUS_STORAGE_TOKEN`.

---

## 2. El servidor abre pero los jugadores no pueden conectarse por Playit.gg

### Síntoma
En el resumen de ejecución (Step Summary) aparece `Minecraft TCP 25565: OK`, pero los jugadores reciben `Connection Refused` o `Timed Out` al intentar entrar.

### Causa
Falta el secreto `PLAYIT_SECRET` o no se configuraron los mapeos de puerto en el panel de Playit.gg.

### Solución
1. Entra a [https://playit.gg](https://playit.gg) y accede a tu panel de control.
2. Comprueba que tengas creados dos túneles:
   - **Túnel 1:** Custom / Minecraft Java `TCP 25565` -> `127.0.0.1:25565`
   - **Túnel 2:** Custom `UDP 24454` -> `127.0.0.1:24454` (Simple Voice Chat)
3. Copia tu Secret Key de Playit e ingrésala en GitHub Secrets de `mc-runner` como `PLAYIT_SECRET`.

---

## 3. Crash de Servidor al Iniciar (Mixin Fatal o ClassNotFound)

### Síntoma
Forge no llega al mensaje `Done (...)!` y el workflow cancela por crash.

### Causa
Inclusión accidental de un mod exclusivo de cliente o mod prohibido (ej: `IronsArms` o `Embeddium`).

### Solución
1. Ve a la pestaña **Actions > Run > Artifacts** y descarga el archivo `nexus-session-diagnostics-runX.zip`.
2. Abre `latest.log` o `crash-reports/`.
3. Revisa la sección `SERVER_MOD_MANIFEST.md` para verificar que el mod problemático esté marcado como cliente o incompatible.
4. Vuelve a ejecutar `tools/nexus/publish-server-bundle.ps1` desde tu entorno local para re-generar una distribución limpia sin ese mod.

---

## 4. Fallo de Backup o Cierre Inesperado del Runner

### Síntoma
El job de GitHub Actions alcanza el límite de tiempo (350 min) y se cancela.

### Causa
Límite duro de GitHub Actions (máximo 6 horas por job).

### Solución
- La infraestructura de NEXUS guarda automáticamente el mundo en las etapas finales (`always()`).
- Si el runner cae de golpe, el último estado válido permanecerá a salvo en la release `world-state` como `world-current.tar.gz` o `world-previous.tar.gz`.
- Para restaurar el estado anterior en caso de inconvenientes, cambia temporalmente el asset en `cleoleobel/nexus-storage`.
