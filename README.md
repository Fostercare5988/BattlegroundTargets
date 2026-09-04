# BattlegroundTargets (World of Warcraft 1.12.1 Enhanced)

[![Client](https://img.shields.io/badge/Client-1.12.1%20Vanilla-blue.svg)](#)
[![ClassicAPI](https://img.shields.io/badge/ClassicAPI-v1.13.4+-orange.svg)](#)
[![SuperWoW](https://img.shields.io/badge/SuperWoW-v2.2+-brightgreen.svg)](#)
[![UnitXP](https://img.shields.io/badge/UnitXP_SP3-v89+-purple.svg)](#)
[![DXVK](https://img.shields.io/badge/DXVK-Vulkan-red.svg)](#)
[![License](https://img.shields.io/badge/License-GPLv2-yellow.svg)](#)

**BattlegroundTargets** is a high-performance Enemy Unit Frame addon for World of Warcraft 1.12.1 battlegrounds (Warsong Gulch, Arathi Basin / Eye of the Storm, Alterac Valley).

Engineered specifically for the Enhanced 1.12.1 Client, this version strips away all legacy 2006 bloat, combat-log guessing heuristics, range calculations, and role overlays, focusing exclusively on delivering rock-solid, ultra-fast **Enemy Unit Frames** in three dedicated battleground bracket formats.

---

## 🏛️ Architectural Pillars & Prerequisites

To run this modernized build, the following client extensions are strictly required:

| Component | Minimum Version | Architectural Role |
| :--- | :---: | :--- |
| **ClassicAPI.dll** | `v1.13.4+` | Modern Lua environment, native `table.wipe`, C_Timer, and compatibility layers. |
| **SuperWoW.dll** | `v2.2+` | Instantaneous `TargetByName(name, true)` exact-name targeting in and out of combat without lockdown taint. |
| **NamPower.dll** | `v4.6.3+` | Fast hardware spell querying & event routing. |
| **UnitXP SP3** | `v89+` | Accurate numerical health & unit telemetry (`UnitXP("health", unit)`). |
| **DXVK** | `v2.0+` (e.g. `v3.1`) | Vulkan translation layer ensuring jitter-free frame pacing. |

---

## ⚔️ Key Features

- **Pure Enemy Frames**: Displays the active enemy roster cleanly with class-colored health status bars, player names, and real-time health percentage numbers. All unneeded role/healer icons, range dropdowns, target count badges, and focus markers have been completely removed.
- **Unrestricted Instant Targeting**: Left-click instantly targets the exact enemy unit using SuperWoW's native C++ `TargetByName(name, true)` without combat lockdown restrictions or taint. Right-click sets focus via native `FocusUnit`.
- **Three Dedicated Battleground Brackets**:
  - **10 vs 10**: Warsong Gulch (supports optional FosterFrames sleek dark card styling).
  - **15 vs 15**: Arathi Basin and Eye of the Storm.
  - **40 vs 40**: Alterac Valley.
- **Independent Layout Customization**: Separate text size, scale, width, height, and display toggles (Show Health Bar, Show Percent, Hide Realm, Class/Name sorting) for each bracket.
- **Child Element Click Passthrough**: Explicit `:EnableMouse(false)` configured across all text labels, health bars, and background textures (Rule C8) to eliminate click dead zones.
- **Zero-GC Table Recycling**: Pre-allocated array buffers and native C++ `table.wipe` memory recycling (Rule D1 & B10) ensuring zero garbage collector spikes during intense PvP combat.
- **Modular Architecture (Rule H7)**: Core engine logic (`BattlegroundTargets.lua`) cleanly separated from the configuration interface (`BattlegroundTargetsOpt.lua`).

---

## 💻 Slash Commands

| Command | Action |
| :--- | :--- |
| `/bgt` or `/battlegroundtargets` | Toggle the BattlegroundTargets configuration window. |
| `/bgt test` | Toggle test mode to preview and position frames outside battlegrounds. |
| `/bgt reset` | Reset all frame positions to default. |

---

## 📁 Clean Directory Structure

```text
BattlegroundTargets/
├── BattlegroundTargets.toc
├── Localization.lua
├── BattlegroundTargets.lua
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
