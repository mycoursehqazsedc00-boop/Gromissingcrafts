# Gromissingcrafts

> Missing-recipe tracker for Vanilla WoW 1.12 / Turtle WoW (Ace3-free, pfUI-friendly fork of [MissingCrafts](https://github.com/refaim/MissingCrafts)) with specialization branching, Turtle WoW recipe parity, and **AdvancedTradeSkillWindow** integration.

## Client Mods Used
This addon runs in **pure Vanilla 1.12 (Lua 5.0)** and requires **no client DLL mods**. The following optional mods are used when present:

| Mod | Purpose in this addon | Required? |
|---|---|---|
| ClassicAPI | `GetSpellInfo(spellID)` localized specialization-name lookup | Optional |
| SuperWoW | `SpellInfo(spellID)` localized spell/specialization lookup & `spell:` link prefix compatibility | Optional |

## Features
- **Integrated Profession Window:** Attaches directly to the open profession frame (Default, Turtle WoW, `AdvancedTradeSkillWindow`, `AdvancedTradeSkillWindow2`, `Artisan`) and moves with it.
- **Specialization Branching & Filtering:** Tracks specializations for Blacksmithing (`Armorsmith`, `Weaponsmith`, `Master Axesmith` / `Hammersmith` / `Swordsmith`), Engineering (`Gnomish` / `Goblin`), Leatherworking (`Dragonscale` / `Elemental` / `Tribal`), and Jewelcrafting (`Gemology` / `Goldsmith`). Shows all branches with `[Spec]` tags before you specialize, and hides mutually-exclusive branches you cannot learn once specialized.
- **Complete Turtle WoW Recipe Database (`LibCrafts-1.0` v21):** Cross-checked against `database.capycraft.io` across all 12 professions, including Jewelcrafting, Disguise, and **Survival** (92 recipes).
- **Enhanced Item Tooltips:** Shows which characters on your realm can learn a recipe item and filters out incompatible specialization branches.
- **Search & Source Info:** Real-time recipe name search with source breakdown (`Vendor`, `Quest`, `Drop`, `Trainer`, etc.) and `Specialization:` line in tooltips.
- **pfUI-friendly & No Ace3:** Uses native Vanilla frames with zero Ace3 library conflicts.
- **Multi-Language Support:** English, German, French, Spanish, Portuguese, Russian, Korean, Chinese (Simplified), Chinese (Traditional).

## What Was Added / Improved
- **Specialization Detection & Filtering:**
  - Added `LibCrafts-1.0` specialization constants and `Craft:SetSpecialization()`, tagging **207** specialization-gated recipes across Blacksmithing, Engineering, Leatherworking, and Jewelcrafting.
  - Added automatic spellbook & skill-line specialization detection (`Gromissingcrafts.lua`) and `Character:CanUseSpecialization()` filtering in both the missing-crafts list and alt recipe tooltips (`TooltipEnhancer.lua`).
  - Added `[Spec]` tags in the recipe list and `Specialization: <name>` tooltip lines.
- **Database Parity (`database.capycraft.io`):**
  - Verified all 1,848 existing `LibCrafts-1.0` recipes and added **33** missing Turtle WoW recipes across 11 professions (including `Oil-Powered Cooker`, `Prospector's Magnifying Lens`, `Facetted Crystal Scope`, `Dreamsteel`, `Dreamhide`, `Dreamthread`, `Mixologist Stone`, `Crystalized Topaz`, etc.).
- **ATSW & Vanilla Lua 5.0 Bug Fixes:**
  - Fixed `hookGlobalFunction` missing `...` crash (`MovePanelToLeft`/`MovePanelToCenter`) in `src/ui/Tools.lua` and reused a single `delayFrame`.
  - Guarded `IsMouseButtonDown` in `src/ui/list/CraftsList.lua` for pure Vanilla 1.12 clients without ClassicAPI.
  - Fixed `LibItemTooltip-1.0` crash when clicking non-item chat links (`enchant:`, `quest:`, `player:`).
  - Fixed `UIManager` / `OpenButton` stale `professionFrame` closure when switching professions via `ATSW_QuickTools` and reused `OpenButton` frames instead of leaking `CheckButton` widgets.
  - Fixed `LibCraftingProfessions-1.0` `detect_profession_frame` respecting `/atsw disable`, prevented `scan_skills` from aborting an entire profession on a single uncached `item_link` (while guaranteeing filter/header restore), fixed missing `return true` in `scan_craft_frame`, and replaced the permanent `OnUpdate` frame counter with `GetTime()`.
  - Scoped `Database` character/skill lookups to `GetRealmName()` and wrapped `SetHyperlink` in `pcall`.

## Usage
1. Open any crafting profession window.
2. Click the scroll button in the upper-right corner of the profession frame.
3. Type in the search box to filter missing recipes by name, and hover over entries for source and specialization details.
4. `/gmc dump` — Dump known recipes/item IDs from an open trade skill, craft, or trainer window.

## Supported Profession Windows
- Default WoW profession windows
- Turtle WoW improved Trade Skill window
- [**AdvancedTradeSkillWindow**](https://github.com/laytya/AdvancedTradeSkillWindow-vanilla)
- [**AdvancedTradeSkillWindow2**](https://github.com/Shellyoung/AdvancedTradeSkillWindow2)
- [**Artisan**](https://github.com/Otari98/Artisan)
- [**pfUI**](https://github.com/shagu/pfUI)'s trade skill frame styling

## Acknowledgments
- Built on top of [MissingCrafts](https://github.com/refaim/MissingCrafts) by Roman Kharitonov (`Refaim`) and `Grom`
- Inspired by [MissingTradeSkillsList](https://github.com/refaim/MissingTradeSkillsList)
