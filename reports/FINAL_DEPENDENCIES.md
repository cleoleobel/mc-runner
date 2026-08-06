# NEXUS FINAL DEPENDENCIES & ARTIFACT REPORT

**Date:** 2026-08-06  
**Auditor:** Release Engineer (Antigravity AI)  

---

## 1. System Environment

- **Java JDK:** Eclipse Temurin JDK 17.0.10+7 (`C:\Users\PC\AppData\Local\Temp\jdk17\jdk-17.0.10+7`)
- **Gradle Executable:** Gradle 8.5 (`_work/gradle/bin/gradle.bat`)
- **Minecraft Engine:** 1.20.1
- **Forge Version:** 1.20.1-47.4.0

---

## 2. Compiled Binaries & Custom Packs

### Nexus Core Mod
- **File:** `dist/NEXUS_SERVER_READY/mods/nexus-core-1.0.0.jar`
- **Mod ID:** `nexus`
- **Build Status:** SUCCESS (Gradle 8.5)
- **File Size:** 21,875 bytes
- **SHA-256:** `9EFB41CD7081D1BFB6DD1BB085E01B6CDD32B0B29299DCABB546D9A571A8169C`

### Nexus Weapons (TaCZ Gunpack)
- **File:** `dist/nexus_weapons.zip`
- **Format:** TaCZ 1.1.8-hotfix native format with `assets/nexus_weapons/gunpack_info.json`
- **Path Separators:** Standardized Unix forward slashes `/` for Java `ZipFileSystem` compatibility
- **Target Deployments:**
  - `dist/NEXUS_WEAPONS/nexus_weapons.zip`
  - `dist/NEXUS_LOCAL_READY/tacz/nexus_weapons.zip`
  - `dist/NEXUS_SERVER_READY/tacz/nexus_weapons.zip` (simlinked/copied)
  - `dist/NEXUS_CLIENT_READY/tacz/nexus_weapons.zip`

---

## 3. Side Distribution Audit

- **Local Total Mods:** 37 JARs
- **Server Total Mods:** 30 JARs
- **Stripped Client-Only Mods (7 JARs):**
  1. `embeddium-0.3.31+mc1.20.1.jar`
  2. `entityculling-forge-1.7.5-mc1.20.1.jar`
  3. `DistantHorizons-2.3.0-a-1.20.1.jar`
  4. `immediatelyfast-forge-1.2.21+1.20.4.jar`
  5. `Xaeros_Minimap_24.7.1_Forge_1.20.jar`
  6. `XaerosWorldMap_1.39.3_Forge_1.20.jar`
  7. `Controlling-forge-1.20.1-12.0.2.jar`
- **Added Server Utilities (1 JAR):**
  1. `Chunky-1.3.146.jar`
