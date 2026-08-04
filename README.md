# Runner del servidor Bedrock en GitHub Actions

Este repositorio **público** contiene únicamente el workflow. Los packs viven en
el repositorio **privado** y se clonan en cada ejecución.

## Por qué está partido en dos repositorios

| | Repo público (este) | Repo privado (los packs) |
|---|---|---|
| Contiene | solo el workflow | los 16 packs del modpack |
| Minutos de Actions | **ilimitados** | 2.000/mes → se para a las 33 h |
| Licencias | no publica nada de terceros | Aplok Guns es CC BY-NC-ND, queda privado |

Si metieras los packs aquí, publicarías contenido con licencia *NoDerivatives*.
Si ejecutaras el workflow en el privado, el servidor moriría a los día y medio.
Partirlo resuelve las dos cosas.

---

## Lo que hay que configurar

### 1. Variable del repositorio

`Settings → Secrets and variables → Actions → Variables → New variable`

| Nombre | Valor |
|---|---|
| `REPO_PACKS` | `villasori466-hub/server-minecraft-bedrock` |

### 2. Secretos

`Settings → Secrets and variables → Actions → Secrets → New secret`

| Nombre | Qué es | Dónde se saca |
|---|---|---|
| `PACKS_TOKEN` | Token personal con permiso para leer el repo privado y lanzar workflows | GitHub → Settings → Developer settings → Personal access tokens |
| `PLAYIT_SECRET` | Clave del agente de playit.gg | Panel de playit.gg, al crear el túnel |

Para `PACKS_TOKEN`, si usas un *fine-grained token* dale acceso a **los dos**
repositorios con permisos de **Contents: read** y **Actions: read and write**.

> Estas dos claves las creas y las pegas tú en la interfaz de GitHub.
> No se guardan en ningún archivo del proyecto.

### 3. Primer arranque

`Actions → Servidor Bedrock → Run workflow`

A partir de ahí se encadena solo: al terminar cada sesión lanza la siguiente.

Para **pararlo del todo**: `Actions → Servidor Bedrock → ··· → Disable workflow`.
Si no lo desactivas, se relanza indefinidamente.

---

## Lo que obtienes de verdad

| | |
|---|---|
| Duración de cada sesión | **~5 h 35 min** |
| Corte entre sesiones | 3-5 min (descargar servidor, montar packs, restaurar mundo) |
| Reinicios al día | **~4** |
| Dirección para tus amigos | **Fija**, la del túnel de playit (va atada a tu cuenta, no a la máquina) |
| El mundo | Se guarda en la release `mundo` de este repo y se restaura en cada arranque |
| Aviso a los jugadores | El servidor avisa por chat 5 min y 1 min antes de reiniciar |

## Lo que NO obtienes

- **No es 24/7 real.** El límite de 6 horas por job es duro y no se puede saltar.
- Si un reinicio pilla a alguien a media Blood Moon, pierde esa noche de horda.
- El mundo se guarda **al final de cada sesión**. Si un runner se cae de golpe,
  se pierde lo jugado en esa sesión. Es la limitación más seria de este montaje.
- **Esto va contra las Acceptable Use Policies de GitHub**, que prohíben usar
  Actions para cualquier cosa ajena a compilar, probar o desplegar el proyecto.
  Alojar un servidor de juego encaja de lleno. GitHub suspende cuentas por esto.

## La alternativa, para tenerla presente

Un VPS x86 de 2 núcleos y 4 GB cuesta unos **4,50 €/mes**: sin cortes, sin
perder partidas, sin riesgo para tu cuenta, con IP pública propia y sin
necesitar playit. Además sale más barato que la electricidad de dejar un PC
encendido todo el mes.
