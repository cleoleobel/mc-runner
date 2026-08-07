# GUÍA RÁPIDA DE CONFIGURACIÓN USUARIO (NEXUS JAVA SERVER)

¡Toda la infraestructura, empaquetado, scripts y workflows de GitHub Actions para **NEXUS Java Server** ya han sido construidos, probados y publicados por el agente AI!

Tu intervención manual queda reducida a los siguientes **4 sencillos pasos**:

---

## 1. Mapeo de Puertos en Playit.gg
1. Entra al panel de tu cuenta en **[https://playit.gg](https://playit.gg)**.
2. Crea los siguientes 2 túneles:
   - **Túnel 1:** Protocolo `TCP` -> Puerto Interno `25565` (Minecraft Java)
   - **Túnel 2:** Protocolo `UDP` -> Puerto Interno `24454` (Simple Voice Chat)
3. Copia tu **Secret Key** del agente de Playit.gg.

---

## 2. Configurar GitHub Secrets
Entra en el repositorio runner:  
👉 **[https://github.com/cleoleobel/mc-runner/settings/secrets/actions](https://github.com/cleoleobel/mc-runner/settings/secrets/actions)**

Agrega o verifica los siguientes **2 secretos**:

| Nombre del Secret | Valor | Descripción |
|---|---|---|
| `NEXUS_STORAGE_TOKEN` | `ghp_...` o `github_pat_...` | Personal Access Token con permiso de escritura sobre `cleoleobel/nexus-storage` |
| `PLAYIT_SECRET` | `secret_key_...` | Clave secreta copiada de tu panel de Playit.gg |

> **Nota sobre `NEXUS_STORAGE_TOKEN`:** Puedes generarlo en 30 segundos en **GitHub > Settings > Developer Settings > Personal Access Tokens > Fine-grained tokens**, seleccionando el repo `cleoleobel/nexus-storage` con permiso `Contents: Read and write`.

---

## 3. Iniciar el Servidor desde GitHub Actions
1. Ve a la pestaña **Actions**:  
   👉 **[https://github.com/cleoleobel/mc-runner/actions](https://github.com/cleoleobel/mc-runner/actions)**
2. Selecciona el workflow: **NEXUS Java Server**
3. Haz clic en **Run workflow**:
   - `operation`: `run-server` (o `validate` para prueba rápida, o `pregen` para chunks)
   - Haz clic en el botón verde **Run workflow**.

---

## 4. ¡Entrar a Jugar!
Una vez iniciado el workflow (aproximadamente 2-3 minutos en abrir):
- Copia la IP pública que asignó **Playit.gg** para TCP `25565` e ingrésala en tu cliente Minecraft Java 1.20.1 Forge.
- El chat de voz se conectará automáticamente a través de la dirección UDP `24454` provista por Playit.

---

## Resumen de Repositorios Creados y Listos

- **Storage (Privado):** `https://github.com/cleoleobel/nexus-storage` (Contiene `server-bundle.tar.gz` e historia de mundos)
- **Runner (Público):** `https://github.com/cleoleobel/mc-runner` (Workflow `nexus.yml` y coexistencia limpia con Bedrock)
