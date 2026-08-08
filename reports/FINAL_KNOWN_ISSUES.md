# NEXUS FINAL KNOWN ISSUES & MITIGATIONS

**Date:** 2026-08-06  
**Auditor:** Final Technical Auditor (Antigravity AI)  

---

## 1. Resolved Issues

1. **ZipFileSystem Windows Path Separator Crash (TaCZ 1.1.8):**
   - **Symptom:** ` cpw.mods.niofs.union.UnionFileSystem$NoSuchFileException: technomantic_launcher.json` during server startup.
   - **Root Cause:** PowerShell `Compress-Archive` stored entry paths with Windows backslashes `\`.
   - **Resolution:** Built ZIP files using Python `zipfile` module to strictly enforce Unix forward slashes `/`.
2. **Nexus Config Default Gun ID Mismatch:**
   - **Symptom:** Default gun ID pointed to non-existent `nexus_weapons:anti_colossus_rifle`.
   - **Resolution:** Fixed to `nexus_weapons:anti_colossus_sniper` in `NexusConfig.java` and recompiled.
3. **Mekanism Datapack Tag Mismatch:**
   - **Symptom:** `steel_casing.json` relied on `forge:glass/silica`.
   - **Resolution:** Replaced with universal `forge:glass` tag.

---

## 2. Outstanding & Minor Non-Blocking Issues

1. **Client GUI Verification (Requires Player Interaction):**
   - **Status:** Headless execution cannot drive singleplayer GUI menus or test client HUD keybinds directly.
   - **Mitigation:** Marked project status as `READY PENDING MANUAL GUI VALIDATION` and provided `reports/MANUAL_GUI_CHECKLIST.md`.
2. **IronsArms / Modified ArmsLib:**
   - **Status:** Removed from modpack per project guidelines. Modpack operates completely stably without them.
