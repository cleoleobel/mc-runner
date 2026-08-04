# Runner del servidor Bedrock

Repositorio **público** que contiene únicamente el workflow. Los packs del
modpack viven en un repositorio **privado de otra cuenta** y se clonan en cada
ejecución.

## Por qué está montado así

| | Este repo (público) | Repo de los packs (privado) |
|---|---|---|
| Cuenta | `cleoleobel` | `villasori466-hub` |
| Contiene | solo el workflow | los 16 packs del modpack |
| Minutos de Actions | **ilimitados** | 2.000/mes → se pararía a las 33 h |
| Licencias | no publica nada de terceros | Aplok Guns es CC BY-NC-ND, queda privado |

**Cuentas separadas a propósito**: alojar un servidor de juego en Actions va
contra las Acceptable Use Policies de GitHub. Si esta cuenta acaba suspendida,
la que guarda el modpack no se ve arrastrada.

---

## Configuración

### Variable

`Settings → Secrets and variables → Actions → Variables`

| Nombre | Valor |
|---|---|
| `REPO_PACKS` | `villasori466-hub/server-minecraft-bedrock` |

### Secretos

`Settings → Secrets and variables → Actions → Secrets`

| Nombre | De qué cuenta | Permisos mínimos |
|---|---|---|
| `PACKS_TOKEN` | **villasori466-hub** | `Contents: read` sobre el repo de los packs |
| `CHAIN_TOKEN` | **cleoleobel** | `Actions: read and write` sobre este repo |
| `PORTMAP_OVPN` | — | El fichero `.ovpn` **entero** de la configuración `minecraft` de portmap.io |
| `PLAYIT_SECRET` | — | *Opcional.* La *secret key* del agente de playit. Sin ella no se intenta la puerta rápida |

Y dos variables más, también opcionales, para la puerta rápida: `PLAYIT_HOST` y
`PLAYIT_PUERTO`, la dirección pública del túnel de playit y su puerto.

### El túnel

La dirección pública es fija y vive en las variables `TUNEL_HOST` / `TUNEL_PUERTO`
del workflow:

```
lionel123lave-36820.portmap.host   puerto 36820
```

Corresponde a la regla `udp://lionel123lave-36820.portmap.host:36820 => 19132`
de portmap.io. Si algún día se rehace la regla, se cambia en el workflow y en
ningún sitio más.

#### El relé es el 70% del ping

Medido en agosto de 2026, desde Santo Domingo:

| Tramo | RTT |
|---|---|
| Jugador → relé de portmap **en Londres** | 138 ms |
| Londres → runner (Virginia) | ~80 ms |
| **Total dentro del juego** | **218 ms**, 3% de pérdida |

El tráfico cruza el Atlántico **dos veces para nada**: de camino a Londres ya
pasa por Nueva York a 62 ms, y desde Londres vuelve a Virginia. La ruta directa
serían ~50 ms.

portmap tiene un relé en Nueva York — `usa.portmap.io` → `nyc1.portmap.io`,
**54 ms desde Santo Domingo con 0% de pérdida** — pero elegir región es función
de pago (3,99 $/mes ó 29,99 $/año).

**Para mover el relé** basta con rehacer la regla en portmap sobre el servidor de
EE. UU. y cambiar tres cosas:

1. `PORTMAP_OVPN` → el `.ovpn` nuevo de esa configuración
2. `TUNEL_HOST` y `TUNEL_PUERTO` en el workflow → los de la regla nueva

El workflow no necesita ningún otro cambio: mide y publica el tramo
runner → boca del túnel en el resumen de cada ejecución.

#### La puerta rápida (opcional, gratis)

playit **sí** deja elegir región gratis. Su agente 1.0.x no sirve aquí por el
fallo de IPv6 de arriba, pero la rama **0.17.1** es otra generación del programa,
sigue soportada y no comparte ese código. El workflow la intenta si están puestos
`PLAYIT_SECRET`, `PLAYIT_HOST` y `PLAYIT_PUERTO`, con un tunel apuntando a
`127.0.0.1:19132` y **región de EE. UU.** elegida en su panel.

Es **aditiva y sin riesgo**: portmap se levanta igual, pase lo que pase. Si playit
funciona, el servidor queda con dos puertas y el resumen anuncia la rápida; si no,
se cierra sola y no se nota.

Y no se fía de lo que diga el agente. La vez anterior decía *tunnels loaded*
mientras no reenviaba nada, así que la única prueba que se acepta es un paquete
que salga del runner, dé la vuelta por la dirección pública y vuelva a entrar.

> **No se usa playit.gg.** Su agente 1.0.10 pide los servidores de control a la
> API, recibe solo objetivos IPv6 y no reintenta por IPv4. Los runners de GitHub
> son solo IPv4, así que la sesión de control nunca se establecía: el agente
> autenticaba y decía «tunnels loaded», pero no reenviaba ni un paquete. Es un
> bug abierto de upstream ([playit-agent#194](https://github.com/playit-cloud/playit-agent/issues/194)).

Dos tokens en vez de uno porque los *fine-grained tokens* pertenecen a una sola
cuenta. Además, así cada uno tiene el permiso mínimo: si el que vive en este
repo público se filtrase, solo daría lectura del repo de packs, nunca escritura.

> `PACKS_TOKEN` es el sensible: da acceso de lectura a un repo privado de tu
> otra cuenta. Ponle **caducidad de 90 días** y usa siempre *fine-grained*
> limitado a ese único repositorio.

### Arranque

`Actions → Servidor Bedrock → Run workflow`

Desde ahí se encadena solo. Para pararlo: `Actions → ··· → Disable workflow`.

---

## Lo que obtienes

| | |
|---|---|
| Sesión | ~5 h 35 min |
| Corte entre sesiones | 3-5 min |
| Reinicios al día | ~4 |
| Dirección | **Fija**, la del túnel de portmap.io (atada a la cuenta, no a la máquina) |
| Mundo | Guardado en la release `mundo` de este repo, restaurado al arrancar |
| Aviso a jugadores | Por chat, 5 min y 1 min antes de cada reinicio |

## Lo que no obtienes

- **No es 24/7 real.** El límite de 6 h por job es duro.
- El mundo se guarda **al final de cada sesión**: si un runner cae de golpe, se
  pierde lo jugado en ella. Es la limitación más seria del montaje.
- Va contra las políticas de GitHub. Riesgo real de suspensión de esta cuenta.

## Alternativa

Un VPS x86 de 2 núcleos y 4 GB cuesta ~4,50 €/mes: sin cortes, sin perder
partidas, sin riesgo de cuenta y con IP pública propia. Sale más barato que la
electricidad de dejar un PC encendido todo el mes.
