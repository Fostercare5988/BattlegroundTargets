# BattlegroundTargets (World of Warcraft 1.12.1 Enhanced)

[![Client](https://img.shields.io/badge/Client-1.12.1%20Vanilla-blue.svg)](#)
[![ClassicAPI](https://img.shields.io/badge/ClassicAPI-v1.13.3+-orange.svg)](#)
[![SuperWoW](https://img.shields.io/badge/SuperWoW-v2.2+-brightgreen.svg)](#)
[![UnitXP](https://img.shields.io/badge/UnitXP_SP3-v89+-purple.svg)](#)
[![DXVK](https://img.shields.io/badge/DXVK-Vulkan-red.svg)](#)
[![License](https://img.shields.io/badge/License-GPLv2-yellow.svg)](#)

**BattlegroundTargets** is a high-performance Enemy Unit Frame addon for World of Warcraft 1.12.1 battlegrounds (Warsong Gulch, Arathi Basin, Alterac Valley). 

Originally authored by **kunda** and modernized by **Fostercare5988**, this version has been completely re-engineered from modern Classic Era (1.14.2) back to the 1.12.1 Enhanced Client, leveraging native C++ engine extensions for instantaneous exact-name targeting, zero combat lockdown restrictions, and rock-solid high-refresh framerate pacing.

---

## 🏛️ Architectural Pillars & Prerequisites

To run this modernized build, the following client extensions are strictly required:

| Component | Minimum Version | Architectural Role |
| :--- | :---: | :--- |
| **ClassicAPI.dll** | `v1.13.3+` | Modern Lua environment & compatibility layers. |
| **SuperWoW.dll** | `v2.2+` | Instantaneous `TargetByName(name, true)` exact-name targeting in and out of combat without lockdown taint. |
| **NamPower.dll** | `v4.6.2+` | Fast hardware spell querying & event routing. |
| **UnitXP SP3** | `v89+` | Accurate 3D Euclidean distances (`UnitXP("distance", unit)`). |
| **DXVK** | `v2.0+` (e.g. `v3.1`) | Vulkan translation layer ensuring jitter-free frame pacing. |

---

## ⚔️ Key Features

- **Unrestricted Combat Targeting**: Unlike retail/Classic Era where targeting buttons are locked behind `SecureActionButtonTemplate` restrictions during combat, our SuperWoW integration provides instant exact-name targeting via `TargetByName(name, true)` at all times.
- **Child Element Click Passthrough**: Explicit `:EnableMouse(false)` configured across all text labels, target indicators, assist markers, and class overlays (Rule C8) to eliminate click interception.
- **Dynamic 10v10, 15v15 & 40v40 Layouts**: Automatically switches layout and scales depending on whether you are in Warsong Gulch, Arathi Basin, or Alterac Valley.
- **Healer & Role Detection**: Identifies enemy healers through combat log aura analysis and cross-faction database caching.
- **Flag Carrier Tracking**: Real-time tracking of Warsong Gulch flag carriers.
- **100% Clean English Standard**: Purged of redundant foreign localization files in compliance with Rule H2.

---

## 💻 Slash Commands

| Command | Action |
| :--- | :--- |
| `/bgt` or `/bgtargets` | Toggle the BattlegroundTargets configuration interface. |
| `/bgt hdlog` | Toggle logging of healer detections in chat. |
| `/bgt hdreport` | Print summary report of detected enemy healers and damage dealers. |
| `/bgt hdlogAlways` | Toggle persistent healer logging mode while inside battlegrounds. |
| `/bgt dbStoragePeriod <months>` | Get or set retention period for healer detection database. |

---

## 📁 Clean Directory Structure

```text
BattlegroundTargets/
├── BattlegroundTargets.toc
├── BattlegroundTargets.lua
├── DBUtils.lua
├── Locales/
│   ├── BattlegroundTargets-localization-enUS.lua
│   ├── BattlegroundTargets-localized-bgnames.lua
│   ├── BattlegroundTargets-localized-flag.lua
│   └── BattlegroundTargets-localized-racenames.lua
├── Textures/
│   ├── BattlegroundTargets-texture-button.tga
│   └── Focus.tga
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
- **Zero Foreign Locale Bloat**: 9 redundant foreign locale scripts purged, reducing startup memory footprints.

---

## 📜 Credits & License

- **Original Author**: kunda
- **Combat Log & Healer Detection**: Nobraix, Jud, Khal
- **1.12.1 Modernization & Engine Architecture**: Fostercare5988
- **License**: GNU General Public License v2 (GPL-2.0)
