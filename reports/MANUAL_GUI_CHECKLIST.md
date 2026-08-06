# NEXUS MANUAL CLIENT GUI VALIDATION CHECKLIST

**Date:** 2026-08-06  
**Target:** Client UI / Singleplayer / Multi-player HUD  

---

## Instructions for Human Tester

Because automated scripting operates headlessly, please execute the following 5-minute manual check in the Minecraft client using `dist/NEXUS_CLIENT_READY`:

- [ ] **1. Singleplayer World Launch:**
  Launch client via your launcher (Prism/CurseForge/MultiMC) pointing to `dist/NEXUS_CLIENT_READY`. Create a new Survival world. Confirm world loads without screen freeze or rendering glitches.
- [ ] **2. TaCZ Weapon HUD & Keybinds:**
  Craft or `/give` a TaCZ gun (`nexus_weapons:anti_colossus_sniper`). Hold gun, press `R` (reload), press `Z` (fire mode switch), right-click (ADS / scope zoom). Confirm weapon HUD overlay displays ammo count properly.
- [ ] **3. Xaero's Minimap & WorldMap:**
  Confirm minimap renders in the top-right corner. Press `M` to open full-screen WorldMap. Confirm no keybind conflicts.
- [ ] **4. JEI / REI Interface:**
  Open Inventory (`E`), search `nexus` in JEI search bar. Confirm all 4 custom items (`Ballistic Steel`, `Arcane Catalyst`, `Technomantic Crystal`, `Containment Rune`) display recipes correctly.
- [ ] **5. Dedicated Server Connection:**
  Connect client to local server at `127.0.0.1:25565`. Confirm successful login, voice chat icon in corner, and smooth chunk loading.
