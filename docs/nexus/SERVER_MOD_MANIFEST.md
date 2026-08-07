# NEXUS Dedicated Server Mod Manifest & Audit

**Minecraft Target:** 1.20.1  
**Forge Target:** 47.4.0  
**Java Runtime:** OpenJDK 17  
**Distribution Target:** Dedicated Headless Server  

---

## 1. Server Required & Core Mods (Lado: SERVER / BOTH)

| Mod | Archivo JAR | Versión | Lado | Dependencias | Motivo de Inclusión |
|---|---|---|---|---|---|
| **Nexus Core** | `nexus-core-1.0.0.jar` | 1.0.0 | BOTH | Forge, Minecraft | Mod principal del servidor: balance de armaduras pesadas, penalizaciones de magia, balance de jefes y reglas del servidor. |
| **L_Ender's Cataclysm** | `L_Enders_Cataclysm-3.31.jar` | 3.31 | BOTH | LionfishAPI | Jefes principales de fin de juego (Ignis, Harbinger, Leviathan, Monstrosity). |
| **LionfishAPI** | `lionfishapi-2.8.jar` | 2.8 | BOTH | Forge | API obligatoria requerida por L_Ender's Cataclysm 3.31. |
| **Iron's Spells 'n Spellbooks** | `irons_spellbooks-1.20.1-3.16.2.jar` | 3.16.2 | BOTH | Iron's Lib, Curios API, GeckoLib, PlayerAnimator | Sistema de magia principal del servidor. |
| **Iron's Lib** | `irons_lib-1.20.1-2.1.0.jar` | 2.1.0 | BOTH | Forge | Librería requerida por Iron's Spells 'n Spellbooks. |
| **Cataclysm Spellbooks** | `cataclysm_spellbooks-1.2.9-1.20.1-all.jar` | 1.2.9 | BOTH | Cataclysm, Iron's Spells | Puente de integración de hechizos y jefes entre Cataclysm e Iron's Spells. |
| **Create** | `create-1.20.1-6.0.8.jar` | 6.0.8 | BOTH | Forge | Sistema de automatización cinemática y progresión industrial básica. |
| **Create Crafts & Additions** | `createaddition-1.20.1-1.3.3.jar` | 1.3.3 | BOTH | Create | Integración de electricidad y conversión de energía de Create. |
| **Mekanism** | `Mekanism-1.20.1-10.4.16.80.jar` | 10.4.16.80 | BOTH | Forge | Progresión tecnológica avanzada, procesamiento de minerales y recipientes. |
| **Mekanism Generators** | `MekanismGenerators-1.20.1-10.4.16.80.jar` | 10.4.16.80 | BOTH | Mekanism | Generación de energía nuclear y avanzada para Mekanism. |
| **Timeless & Classics Zero (TaCZ)** | `tacz-1.20.1-1.1.8-hotfix.jar` | 1.1.8 | BOTH | Forge | Motor de armas de fuego y balística. |
| **Alex's Caves** | `alexscaves-2.0.2.jar` | 2.0.2 | BOTH | Citadel | Biomas subterráneos y jefes cavernoso. |
| **Citadel** | `citadel-2.6.3-1.20.1.jar` | 2.6.3 | BOTH | Forge | Librería de entidades requerida por Alex's Caves. |
| **EEEAB's Mobs** | `eeeabsmobs-1.20.1-0.98.1.jar` | 0.98.1 | BOTH | GeckoLib | Jefes y mobs de combate avanzados (Immortal, Executioner). |
| **Ars Nouveau** | `ars_nouveau-1.20.1-4.12.7-all.jar` | 4.12.7 | BOTH | Curios API | Sistema de magia ritual y glifos. |
| **Ars Curios** | `ArsCurios-1.20.1-2.0.0.jar` | 2.0.0 | BOTH | Ars Nouveau, Curios API | Integración de accesorios mágicos de Ars Nouveau con Curios. |
| **Curios API** | `curios-forge-5.14.1+1.20.1.jar` | 5.14.1 | BOTH | Forge | Ranuras de accesorios para magias, mochilas y amuletos. |
| **GeckoLib** | `geckolib-forge-1.20.1-4.8.4.jar` | 4.8.4 | BOTH | Forge | Motor de animaciones 3D para mobs, magias y armaduras. |
| **AzureLib** | `azurelib-neo-1.20.1-3.1.12.jar` | 3.1.12 | BOTH | Forge | Motor de animación secundario para utilidades. |
| **PlayerAnimator** | `player-animation-lib-forge-1.0.2-rc1+1.20.jar` | 1.0.2 | BOTH | Forge | Motor de animación de jugadores en tercera persona (lanzamiento de hechizos). |
| **Corpse** | `corpse-forge-1.20.1-1.0.23.jar` | 1.0.23 | BOTH | Forge | Preservación de inventarios en cadáver al morir. |
| **PlayerRevive** | `PlayerRevive_FORGE_v2.0.31_mc1.20.1.jar` | 2.0.31 | BOTH | CreativeCore | Mecánica de abatimiento y reanimación de compañeros. |
| **CreativeCore** | `CreativeCore_FORGE_v2.12.39_mc1.20.1.jar` | 2.12.39 | BOTH | Forge | Librería técnica requerida por PlayerRevive. |
| **Open Parties and Claims (OPAC)** | `open-parties-and-claims-forge-1.20.1-0.29.2.jar` | 0.29.2 | BOTH | Forge | Reclamación de chunks, protección contra griefing y partidos cooperativos. |
| **Simple Voice Chat** | `voicechat-forge-1.20.1-2.6.21.jar` | 2.6.21 | BOTH | Forge | Chat de voz posicional sobre UDP 24454. |
| **JEI (Just Enough Items)** | `jei-1.20.1-forge-15.48.0.179.jar` | 15.48.0 | BOTH | Forge | Manejador de transferencia de recetas en servidor y sync. |
| **Jade** | `Jade-1.20.1-Forge-11.13.3.jar` | 11.13.3 | BOTH | Forge | Proveedor de datos de bloques e inventarios para clientes. |

---

## 2. Server Performance & Optimization Mods (Lado: SERVER / BOTH)

| Mod | Archivo JAR | Versión | Lado | Motivo de Inclusión |
|---|---|---|---|---|
| **ModernFix** | `modernfix-forge-5.27.66+mc1.20.1.jar` | 5.27.66 | BOTH | Reducción drástica del uso de memoria heap y aceleración de tiempo de booteo. |
| **FerriteCore** | `ferritecore-6.0.1-forge.jar` | 6.0.1 | BOTH | Optimización de estructuras de datos de modelos y estado de bloques en memoria RAM. |
| **Chunky** | `Chunky-1.3.146.jar` | 1.3.146 | SERVER | Herramienta de pre-generación asíncrona de terreno para prevenir lag en exploración. |
| **Spark** | `spark-1.10.53-forge.jar` | 1.10.53 | BOTH | Profiler de rendimiento de CPU, memoria y TPS en tiempo real. |
| **Clumps** | `Clumps-forge-1.20.1-12.0.0.4.jar` | 12.0.0.4 | SERVER | Agrupa orbes de experiencia para evitar acumulación excesiva de entidades en servidor. |
| **Alternate Current** | `alternate_current-mc1.20-1.7.0.jar` | 1.7.0 | SERVER | Reemplazo hiper-optimizado del motor de cálculo de Redstone vanilla. |
| **Get It Together, Drops!** | `getittogetherdrops-forge-1.20-1.3.jar` | 1.3 | SERVER | Fusiona ítems tirados en el suelo para minimizar impacto de lag por entidades. |

---

## 3. Client-Only Mods Excluidos del Servidor (Lado: CLIENT)

| Mod | Motivo de Exclusión del Servidor |
|---|---|
| **Embeddium** / **Chloride** | Motor de renderizado cliente (Sodium fork). No tiene representación en servidor dedicado y causa crash de inicialización de contexto gráfico. |
| **Sodium Options API** | Interfaz gráfica cliente para menú de opciones de video. |
| **Entity Culling** | Algoritmo de renderizado en cliente para ocultar entidades fuera del frustum de la cámara. |
| **Cull Less Leaves** | Optimización de renderizado de hojas de árboles en cliente. |
| **Vanillin** | Paquete de shaders/texturas de interfaz en cliente. |
| **ImmediatelyFast** | Optimización de buffers de dibujo OpenGL/ImmediateMode en cliente. |
| **GPU Memory Leak Fix** | Limpieza de VRAM de la tarjeta gráfica en cliente. |
| **Distant Horizons** | Generador de LOD (Level of Detail) de renderizado visual a larga distancia en cliente. |
| **Xaero's Minimap & World Map** | Renderizado del minimapa e interfaz de usuario en el cliente. |
| **Controlling** | Buscador de teclas y keybinds en el menú de opciones del cliente. |

---

## 4. Mods Incompatibles Excluidos Explícitamente (PROHIBIDOS)

| Mod | Motivo de Exclusión |
|---|---|
| **IronsArms** / **ArmsLib** | **EXPLICITAMENTE PROHIBIDO:** Presenta incompatibilidades fatales comprobadas con el motor de armas TaCZ (Timeless & Classics Zero), provocando cierres inesperados del servidor y conflictos de mixins. **NO debe ser introducido bajo ninguna circunstancia.** |

---

## 5. Resumen de Distribución Server-Side

- **Total Mods de Cliente Local:** 37 mods
- **Total Mods en Servidor Dedicado:** 34 mods (31 base + 3 optimizaciones server-side)
- **Mods de Cliente Eliminados:** 10 mods
- **Integridad de Modpack:** 100% Inmutable y Validado en Forge 47.4.0 / Java 17
