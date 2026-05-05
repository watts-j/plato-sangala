# Plato Sangala — Project State

Last updated: 2026-05-05

## Reference Versions

- **v2.20-sangala** — Last confirmed stable build (dictionary, Menu top bar, empty dirs in nav, no KFMon)
- **v2.22-sangala** — Current build under test (menu restructure, boot delay 9s, Reboot removed)
- **v2.3-sangala-full-build** — Original baseline (archived, no longer used as reference)

## Next Tag Number

**v2.24-sangala**

## Package Structure

Two packages produced per release:
- **`-install.tar.gz`** — For new/factory-reset devices. Includes `.kobo/KoboRoot.tgz` for system-level auto-launch setup.
- **`-update.tar.gz`** — For devices that already have Plato installed. No KoboRoot.tgz, no system changes, no reboot required.

## Branch

`claude/customize-plato-ui-1Edbm`

## User Working Directory

`C:\Users\jbw3r\plato-sangala`

## Device

Kobo Clara BW (model spaBW/spaBWTPV), 1072x1448 @ 300 DPI

## Architecture

- Auto-launch: `plato-autostart.sh` in system partition (installed via KoboRoot.tgz)
- No KFMon, no NickelMenu
- KoboRoot.tgz is minimal (781 bytes): only `on-animator.sh` + `plato-autostart.sh`
- Boot delay: `sleep 9` in plato-autostart.sh
- Dictionary: StarDict format shipped, converted on-device on first use (~1-2 min)

## Library Indices (Settings.toml)

| Index | Name       | Path                    |
|-------|------------|-------------------------|
| 0     | STEM       | /mnt/onboard/STEM       |
| 1     | Humanities | /mnt/onboard/Humanities |
| 2     | Enrichment | /mnt/onboard/Enrichment |
| 3     | Resources  | /mnt/onboard/Resources  |
| 4     | Vocational | /mnt/onboard/Vocational |
| 5     | Menu       | /mnt/onboard/Menu       |

`selected-library = 5` (Menu — empty library, top bar always shows "Menu")

## Menu Tree

```
Menu (top bar — always shows "Menu" regardless of active library)
├── About                          → Resources/About/
├── Enrichment
│   ├── Sangala Story Exchange
│   ├── Drama
│   ├── Fiction
│   ├── Nonfiction
│   ├── Philosophy
│   └── Poetry
├── Humanities
│   ├── Fine Arts
│   ├── Geography
│   ├── History
│   ├── Languages
│   └── Literature in English
│       ├── Drama
│       ├── Fiction
│       ├── Nonfiction
│       └── Poetry
├── STEM
│   ├── Engineering
│   ├── Mathematics
│   │   ├── Algebra
│   │   ├── Calculus
│   │   ├── Geometry
│   │   └── Trigonometry
│   └── Science
│       ├── Biology
│       ├── Chemistry
│       └── Physics
├── Vocational
│   ├── Agriculture
│   ├── Clothing & Textiles
│   ├── Economics
│   ├── Entrepreneurship
│   └── Food & Nutrition
└── Resources
    └── REACH for Uganda Newsletters
```

## Burger Menu (hamburger icon)

- System Info
- Enable WiFi
- Applications (Calculator, Dictionary)
- Power Off

## EPUBs Included

| File | Location |
|------|----------|
| Concepts of Biology.epub | STEM/Science/Biology/ |
| Penrod.epub | Enrichment/Fiction/ |
| The Verger.epub | Enrichment/Fiction/ |
| A Leopard in the Forest.epub | Enrichment/Sangala Story Exchange/ |
| Sangala Reader Initiative.epub | Resources/About/ |
| Newsletter (Fall 2025) - REACH for Uganda.epub | Resources/REACH for Uganda Newsletters/ |

## Known Issues / Pending

- **Home landing page**: Not yet implemented. Previous HomeImage overlay approach crashed. Next approach: modify Shelf renderer to show image when books list is empty. Requires `selected-library = 5` (Menu, empty library) which works as of v2.16/v2.20.
- **`home-image` setting**: Still in Settings.toml and settings struct but not used in Home view code (disabled after crashes). Path: `/mnt/onboard/.adds/plato/resources/home.png`
- **Boot delay**: Currently 9s. Can be reduced further if testing shows stability.
- **`selected-library` crashes**: Setting `selected-library` to non-zero values crashed Plato WHEN combined with the HomeImage overlay code. Works fine without it (confirmed v2.16, v2.20).

## Key Lessons Learned

1. Never create custom system scripts (on-animator.sh) from scratch — use the proven ones
2. KoboRoot.tgz is reprocessed every time files are loaded; keep it minimal
3. `selected-library = X` works on its own but crashed when combined with HomeImage overlay
4. Dictionary pre-conversion in CI produced a 76MB index that was too large for device RAM
5. StarDict on-device conversion (v2.17 approach) works and is fast (~1-2 min first use)
6. Always check the reference version before making assumptions about package structure
7. The v2.3-sangala-full-build release on GitHub is the original source of KFMon/NickelMenu binaries
