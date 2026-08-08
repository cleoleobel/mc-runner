# IronsArms Compatibility Blocker

## Status: BLOCKED

## Error
```
armslib.mixins.json:tacz.AmmoBoxItemMixin fails APPLY against TaCZ 1.1.8-hotfix
```

## Versions Tested
| IronsArms | ArmsLib | CastLib | TaCZ | Result |
|-----------|---------|---------|------|--------|
| 2.0.1 | 2.0.0 | 2.0.0 | 1.1.8-hotfix | CRASH — ArmsLib mixin targets class that changed in TaCZ hotfix |

## Root Cause
ArmsLib 2.0.0 contains a Mixin (`tacz.AmmoBoxItemMixin`) that targets internal TaCZ classes.
TaCZ 1.1.8-hotfix changed the targeted class structure, making the mixin incompatible.
There is no official ArmsLib update for TaCZ 1.1.8-hotfix on Forge 1.20.1.

## Decision
- IronsArms, ArmsLib, and CastLib are **removed from the stable baseline**.
- They remain in `_work/mods/` as evidence.
- TaCZ 1.1.8-hotfix is kept because it is the latest stable release for Forge 1.20.1.
- Iron's Spells 'n Spellbooks continues to function independently without IronsArms.

## Impact
- No spell-gun integration (Iron's Spells weapons cannot use TaCZ mechanics).
- Nexus gun progression is fully handled by the TaCZ gun pack instead.
- Magic pillar remains via Iron's Spells standalone.

## Resolution Path
- Monitor IronsArms/ArmsLib for an update compatible with TaCZ 1.1.8-hotfix.
- If a future ArmsLib release fixes the mixin, re-test and add back.
- Do NOT use manually patched JARs in stable distribution.

## Evidence
- `_work/mods/IronsArms-1.20.1-2.0.1.jar` — original jar
- `_work/mods/ArmsLib-1.20.1-2.0.0.jar` — contains the broken mixin
- `_work/mods/CastLib-1.20.1-2.0.0.jar` — dependency
