# COMPATIBILITY REPORT — NEXUS MODPACK INTEGRATION

**Minecraft Target:** 1.20.1  
**Forge Target:** 47.4.0  
**Java Runtime:** OpenJDK 17  

---

## 1. Validated Core Integration Matrix

The following combination has been tested and verified to prevent crashes, `NoClassDefFoundError`, `AbstractMethodError`, or Mixin transformation failures:

| Mod Component | Validated Version | Status | Notes |
|---|---|---|---|
| **L_Ender's Cataclysm** | `3.16` | **VERIFIED** | Pinned to v3.16. Prevents API breakage with LionfishAPI 2.8 and Cataclysm Spellbooks 1.2.9. |
| **LionfishAPI** | `2.8` | **VERIFIED** | Core dependency for Cataclysm 3.16. |
| **Cataclysm Spellbooks** | `1.2.9` | **VERIFIED** | Bridge between Cataclysm boss items and Iron's Spells spellcasting. |
| **Iron's Spells 'n Spellbooks** | `3.16.2` | **VERIFIED** | Magic engine. Integrates with Curios and GeckoLib. |
| **Create** | `6.0.8` | **VERIFIED** | Automation engine. |
| **Create Crafts & Additions** | `1.3.3` | **VERIFIED** | Electricity conversion integration for Create. |
| **Mekanism** | `10.4.16.80` | **VERIFIED** | Advanced tech and ore processing. |
| **Mekanism Generators** | `10.4.16.80` | **VERIFIED** | Nuclear power generation. |
| **Timeless & Classics Zero (TaCZ)** | `1.1.8-hotfix` | **VERIFIED** | Firearms engine and custom `nexus_weapons` gunpack. |
| **Alex's Caves** | `2.0.2` | **VERIFIED** | Underground biomes (Citadel dependency). |
| **EEEAB's Mobs** | `0.98.1` | **VERIFIED** | Additional boss encounters. |
| **Nexus Core** | `1.0.0` | **VERIFIED** | Compiled local binary `nexus-core-1.0.0.jar`. Heavy magic armor penalties and co-op boss scaling active. |

---

## 2. Banned Incompatible Mods

| Prohibited Mod | Reason for Ban | Enforcement Mechanism |
|---|---|---|
| **IronsArms** | Causes fatal mixin conflict and crash with TaCZ firearms engine. | Build-time throw assertion in `build-server-bundle.ps1`. |
| **ArmsLib** | Dependency for IronsArms. Incompatible with TaCZ. | Build-time throw assertion in `build-server-bundle.ps1`. |

---

## 3. Side Classification & Exclusion Rules

- **Dedicated Server Mods (37 JARs):** Pure gameplay, tech, magic, boss, and server performance mods.
- **Client-Only Mods Excluded (13 JARs):** Renderers (Embeddium, Chloride, ImmediatelyFast, Distant Horizons, Entity Culling, Cull Less Leaves, Vanillin, GPU Memory Leak Fix) and HUD interfaces (Xaero's Minimap, Xaero's World Map, Controlling, Searchables, Sodium Options API).
