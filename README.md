# BattlegroundTargets (World of Warcraft 1.12.1 Enhanced)

[![Client](https://img.shields.io/badge/Client-1.12.1%20Vanilla-blue.svg)](#)
[![ClassicAPI](https://img.shields.io/badge/ClassicAPI-v1.13.4+-orange.svg)](#)
[![SuperWoW](https://img.shields.io/badge/SuperWoW-v2.2+-brightgreen.svg)](#)
[![UnitXP](https://img.shields.io/badge/UnitXP_SP3-v90+-purple.svg)](#)
[![DXVK](https://img.shields.io/badge/DXVK-Vulkan-red.svg)](#)
[![License](https://img.shields.io/badge/License-GPLv2-yellow.svg)](#)

**BattlegroundTargets** is a high-performance Enemy Unit Frame addon for World of Warcraft 1.12.1 battlegrounds (Warsong Gulch, Arathi Basin / Eye of the Storm, Alterac Valley).

Engineered specifically for the Enhanced 1.12.1 Client, this version strips away all legacy 2006 bloat, combat-log guessing heuristics, range calculations, and role overlays, focusing exclusively on delivering rock-solid, ultra-fast **Enemy Unit Frames** in three dedicated battleground bracket formats.

---

## 🏛️ Architectural Pillars & Prerequisites

To run this modernized build, the following client extensions are strictly required:

| Component | Minimum Version | Architectural Role |
| :--- | :---: | :--- |
| **ClassicAPI.dll** | `v1.13.4+` | Modern Lua environment, native `table.wipe`, C_Timer, nameplate token telemetry (`NAME_PLATE_UNIT_ADDED`), and native focus support. |
| **SuperWoW.dll** | `v2.2+` | Direct GUID targeting via `TargetUnit(guid)` and exact-name targeting via `TargetByName(name, true)`. |
| **NamPower.dll** | `v4.6.3+` | Fast hardware spell querying & event routing. |
| **UnitXP SP3** | `v90+` | Accurate numerical health & unit telemetry (`UnitXP("health", unit)`). |
| **DXVK** | `v2.0+` (e.g. `v3.1`) | Direct3D 9 to Vulkan translation layer ensuring jitter-free frame pacing. |

---

## ⚔️ Key Features

- **Pure Enemy Frames**: Displays the active enemy roster cleanly with class-colored health status bars, player names, and real-time health percentage numbers. All unneeded role/healer icons, range dropdowns, target count badges, and focus markers have been completely removed.
- **Automated Scoreboard Polling & Zero-Allocation Delta Guard**: Periodically queries the server scoreboard on a 3.0s native hardware ticker (`C_Timer.NewTicker`), completely eliminating the need to manually click the minimap icon. Gated by a zero-allocation delta guard (`HasRosterChanged()`), 99.9% of polling cycles perform zero DOM manipulations, zero table allocations, and zero redraws if the roster has not changed.
- **Real-Time Stealth & Invisibility Detection**: Instantly detects and displays enemies entering or active in stealth/invisibility (*Stealth*, *Vanish*, *Prowl*, *Shadowmeld*, *Invisibility Potion*, *Lesser Invisibility Potion*, *Gnomish Cloaking Device*, *Smoke Cloud*). Features a crisp dedicated spell icon on the left edge of the row, subtle translucent row dimming (alpha 0.65), and optional stealth status tags, backed by SuperWoW's native C++ `UNIT_CASTEVENT`, ClassicAPI slot-batched aura inspection, and combat log telemetry. Automatically breaks when an enemy attacks, casts non-stealth abilities, takes damage, or dies.
- **Open-World Spy Detection**: Dedicated companion module (`BattlegroundTargetsSpy.lua`) providing high-cohesion, low-coupling enemy detection in the open world outside battlegrounds. Captures enemy player activity up to ~100 yards via SuperWoW `UNIT_CASTEVENT`, ClassicAPI nameplates (`NAME_PLATE_UNIT_ADDED`), and combat log telemetry. Features a draggable floating list displaying enemy names, class colors, levels, health %, stealth badges, and time-decay timestamps. Supports configurable audio chimes on enemy detection and stealth activation, auto-hiding when empty, left-click targeting, and right-click focus.
- **GUID-Aware Instant Targeting**: Left-click prioritizes SuperWoW's native C++ `TargetUnit(guid)` when observed, with instantaneous fallback to `TargetByName(name, true)` without combat lockdown restrictions or taint. Right-click sets focus via native `FocusUnit`.
- **Nameplate Token Telemetry**: Automatically listens to ClassicAPI's `NAME_PLATE_UNIT_ADDED` events (`nameplate1..N`), capturing enemy GUIDs and real-time health as soon as opponents come within 3D view.
- **Three Dedicated Battleground Brackets**:
  - **10 vs 10**: Warsong Gulch.
  - **15 vs 15**: Arathi Basin and Eye of the Storm.
  - **40 vs 40**: Alterac Valley.
- **Independent Layout Customization**: Separate text size, scale, width, height, and display toggles (Show Health Bar, Show Percent, Stealth Icon, Dim Stealthed, Stealth Tag, Hide Realm, Class/Name sorting) for each bracket, plus a dedicated "Spy" tab for open-world settings.
- **Zero-GC Active Sorting**: Fixed-size 40-slot array buffers sorted using an allocation-free insertion sort strictly over the active segment (`1..enemyCount`), eliminating Lua GC spikes during battlegrounds.
- **Unified Parent Frame Hierarchy**: Rows are direct children of `BattlegroundTargets_MainFrame`, providing clean scale inheritance and zero-overhead mouse passthrough during combat (Rule C8).
- **Modular Architecture (Rule H7)**: Core engine logic (`BattlegroundTargets.lua`), open-world detection (`BattlegroundTargetsSpy.lua`), and the configuration interface (`BattlegroundTargetsOpt.lua`) are completely decoupled.

---

## 💻 Slash Commands

| Command | Action |
| :--- | :--- |
| `/bgt` or `/battlegroundtargets` | Toggle the BattlegroundTargets configuration window. |
| `/bgt test` | Toggle test mode to preview and position battleground frames. |
| `/bgt spy` | Toggle open-world Spy test mode to preview and position the Spy frame. |
| `/bgt reset` | Reset all frame positions (BattlegroundTargets, Spy, Options) to default. |

---

## 📁 Clean Directory Structure

```text
BattlegroundTargets/
├── BattlegroundTargets.toc
├── BattlegroundTargets.lua
├── BattlegroundTargetsSpy.lua
├── BattlegroundTargetsOpt.lua
├── Textures/
│   ├── barTexture.tga
│   └── border.tga
├── LICENSE.txt
└── README.md
```

---

## ⚙️ Installation Guide

1. Download or clone this repository:
   ```bash
   git clone https://github.com/Fostercare5988/BattlegroundTargets.git
   ```
2. Place the folder inside your client's addon directory:
   `World of Warcraft/Interface/AddOns/BattlegroundTargets`
3. Ensure **ClassicAPI.dll** and **SuperWoW.dll** are loaded by your 1.12.1 game client.
4. Launch the game and join any battleground!

---

## ⚡ Performance Profile

- **Zero Combat Taint**: Completely bypasses retail protected frame restrictions.
- **Zero Click Interception**: All decorative textures and overlay fontstrings have mouse events disabled.
- **Zero Foreign Locale Bloat**: 100% pure English standard.
- **Zero GC Churn**: Pre-allocated combat state buffers and native memory wipes.

---

## 📜 Credits & License

- **Original Author**: kunda
- **1.12.1 Enhanced Modernization & Engine Architecture**: Fostercare5988
- **License**: GNU General Public License v2 (GPL-2.0)
