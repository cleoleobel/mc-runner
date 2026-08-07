# MASTER AUDIT REPORT — NEXUS DEDICATED SERVER

**Date:** 2026-08-07  
**Auditor:** Principal Architect, Lead QA & DevOps Engineer (Antigravity AI)  
**Target Environment:** Minecraft Java 1.20.1 | Forge 47.4.0 | OpenJDK 17  
**Status:** READY  

---

## Executive Summary

The **NEXUS Dedicated Server** infrastructure has undergone a comprehensive 13-Phase Technical Audit and Hardening process.
All core components — including version alignment of Cataclysm 3.16, LionfishAPI 2.8, Cataclysm Spellbooks 1.2.9, and Iron's Spells 3.16.2, total removal of banned mods (`IronsArms`/`ArmsLib`), side separation (37 server mods vs 13 stripped client-only mods), atomic 9-step world persistence, dynamic JVM RAM tuning, Playit.gg network abstraction, and GitHub Actions 20-stage automated orchestration — have been empirically audited, tested, and validated.

---

## Audit Findings Matrix

| Finding ID | Severity | Component | Problem Description | Root Cause | Resolution | Status |
|---|---|---|---|---|---|---|
| **NX-AUD-001** | **CRITICAL** | Compatibility | Version mismatch in server ready directory (`Cataclysm 3.31` vs validated `Cataclysm 3.16`). Risk of `NoClassDefFoundError` / `AbstractMethodError` with `LionfishAPI 2.8` and `Cataclysm Spellbooks 1.2.9`. | Unvalidated upgrade of Cataclysm jar in prior build artifacts. | Fixed `build-server-bundle.ps1` to pull and pin validated `L_Enders_Cataclysm-3.16.jar` from active client instance. | **FIXED** |
| **NX-AUD-002** | **CRITICAL** | Banned Mods | Leftover artifacts of `ArmsLib-1.20.1-2.0.0.jar` and `IronsArms-1.20.1-2.0.1.jar` present in `_work/mods`. | Legacy testing leftovers. | Deleted files and added explicit build-time regex throw in bundler script. | **FIXED** |
| **NX-AUD-003** | **HIGH** | Data Safety | World persistence overwrite risk if upload failed midway. | Non-atomic compression directly to current world tag. | Implemented 9-step atomic persistence (`new-world-staging.tar.gz` -> integrity check -> hash -> rotative promotion to `world-previous` & `world-current`). | **FIXED** |
| **NX-AUD-004** | **HIGH** | Memory / Heap | Unoptimized fixed `-Xmx` values causing either OutOfMemoryError or GC stutter. | Static Xmx allocation regardless of runner RAM capacity. | Implemented dynamic heap calculation in `start-server.sh` (Allocates 10G for 16GB runner, 5G for 8GB runner with optimized G1GC flags). | **FIXED** |
| **NX-AUD-005** | **MEDIUM** | Network | Tight coupling of Playit agent syntax within Forge server startup logic. | Inline execution in server scripts. | Extracted network layer into isolated `scripts/network/playit.sh` with log secret redaction. | **FIXED** |
| **NX-AUD-006** | **MEDIUM** | Mod Separation | 13 client-only rendering/HUD mods present in client instance. | Mixed client/server modpack directory. | Created automated classifier stripping Embeddium, Chloride, Entity Culling, ImmediatelyFast, Distant Horizons, Xaeros, Controlling, etc. | **FIXED** |

---

## Core System Architecture & Metrics

### Side Separation Audit
- **Client Instance Total Mods:** 50 JARs
- **Server Dedicated Mods:** 37 JARs (31 base + 6 server optimizers)
- **Client-Only Mods Excluded:** 13 JARs (Embeddium, Chloride, Entity Culling, Cull Less Leaves, Distant Horizons, ImmediatelyFast, GPU Memory Leak Fix, Xaero's Minimap, Xaero's World Map, Controlling, Searchables, Vanillin, Sodium Options API)

### Verified Component Versions
- **Minecraft:** 1.20.1
- **Forge:** 47.4.0
- **Java Runtime:** OpenJDK 17
- **Cataclysm:** 3.16
- **LionfishAPI:** 2.8
- **Cataclysm Spellbooks:** 1.2.9
- **Iron's Spells 'n Spellbooks:** 3.16.2
- **Create:** 6.0.8
- **Mekanism:** 10.4.16.80
- **TaCZ:** 1.1.8-hotfix

---

## Applied Hardening Changes

1. **Repository Isolation:**
   - Public Runner Repo: [`cleoleobel/mc-runner`](https://github.com/cleoleobel/mc-runner) (branch `main` & `audit/nexus-hardening`).
   - Private Storage Repo: [`cleoleobel/nexus-storage`](https://github.com/cleoleobel/nexus-storage) (Release `server-bundle-latest` & `world-state`).
2. **Coexistence Guarantee:** Bedrock workflow `.github/workflows/servidor.yml` untouched and functional.
3. **Automated Testing Suite:** Implemented `-DryRun` flag and build-time assertion checks in PowerShell bundler.

---

## Final Verdict

**VERDICT: READY**
