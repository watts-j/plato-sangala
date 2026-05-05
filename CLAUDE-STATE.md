# Plato Sangala — Project State

Last updated: 2026-05-05

## Reference Versions

- **v2.24-sangala** — Current build (menu restructure, new library, dictionary, metadata cleanup, dual packages, installer script)
- **v2.20-sangala** — Last confirmed stable before menu restructure
- **v2.3-sangala-full-build** — Original baseline (archived, no longer used as reference)

## Next Tag Number

**v2.25-sangala**

## Package Structure

Two packages produced per release:
- **`-install.tar.gz`** — For new/factory-reset devices. Includes `.kobo/KoboRoot.tgz` for system-level auto-launch setup.
- **`-update.tar.gz`** — For devices that already have Plato installed. No KoboRoot.tgz, no system changes, no reboot required.

**Installer script**: `sangala/installer/install-sangala.ps1` — PowerShell script that auto-detects the Kobo (by volume name "KOBOeReader" or `.kobo/` directory), determines install vs update, and copies the appropriate files. For fresh installs, handles the two-step process automatically.

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
- Dictionary: Wiktionary English (StarDict format), converted on-device on first use (~1-2 min)
- Metadata extraction: title and author only (series, year, publisher, categories ignored)
- Dictionary rendering: HTML-aware (definitions containing `<` rendered as HTML)

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
- Connect USB
- Power Off

## EPUBs Included

### Enrichment/Drama
- A Doll's House - Henrik Ibsen
- A Midsummer Night's Dream - William Shakespeare
- Hamlet - William Shakespeare
- King John - William Shakespeare
- King Lear - William Shakespeare
- Oedipus Rex - Sophocles
- Oedipus at Colonus - Sophocles
- Richard III - William Shakespeare
- The Cherry Orchard - Anton Chekhov
- The Tempest - William Shakespeare

### Enrichment/Fiction
- A Leopard in the Forest (in Sangala Story Exchange)
- Crime and Punishment - Fyodor Dostoevsky
- Dracula - Bram Stoker
- Fables - Aesop
- Fathers and Children - Ivan Turgenev
- Flatland - Edwin A. Abbott
- Frankenstein - Mary Shelley
- Penrod - Booth Tarkington
- Pride and Prejudice - Jane Austen
- Saint Joan - George Bernard Shaw
- Short Fiction - Anton Chekhov
- Short Fiction - H. G. Wells
- Short Fiction - Herman Melville
- Short Fiction - Leo Tolstoy
- Short Fiction - O. Henry
- Short Science Fiction - Isaac Asimov
- The Country Wife - William Wycherley
- The Iliad - Homer
- The Odyssey - Homer
- The Verger - Somerset Maugham
- The Way of the World - William Congreve

### Enrichment/Nonfiction
- Essays - Henry David Thoreau
- South! The Story of Shackleton - Ernest Shackleton
- The Autobiography of Benjamin Franklin
- Walden - Henry David Thoreau
- Wild Animals I Have Known - Ernest Thompson Seton

### Enrichment/Poetry
- Lyrical Ballads - William Wordsworth
- Poetry - William Carlos Williams
- Poetry - William Shakespeare

### STEM/Science/Biology
- Photosynthesis (AP level)
- Photosynthesis (Grade 11)
- Photosynthesis (deeper)
- Photosynthesis (overview)
- Pigment Chromatography Lab
- Plant Transport

### Resources
- Sangala Reader Initiative (About/)
- Newsletter (Fall 2025) - REACH for Uganda (REACH for Uganda Newsletters/)

## Known Issues / Pending

- **Home landing page**: Not yet implemented. Previous HomeImage overlay approach crashed. Next approach: modify Shelf renderer to show image when books list is empty. `selected-library = 5` (Menu, empty library) works as of v2.16/v2.20.
- **`home-image` setting**: Still in Settings.toml and settings struct but not used in Home view code (disabled after crashes). Path: `/mnt/onboard/.adds/plato/resources/home.png`
- **Boot delay**: Currently 9s. Can be reduced further if testing shows stability.
- **KoboRoot.tgz freeze**: Fresh installs trigger KoboRoot.tgz processing which can cause a temporary freeze. Solved by using separate install/update packages. Install package triggers the freeze once; update package avoids it.
- **Installer script**: PowerShell script at `sangala/installer/install-sangala.ps1`. Currently hardcoded to v2.24 paths. Needs updating for each new release or parameterization.

## Key Lessons Learned

1. Never create custom system scripts (on-animator.sh) from scratch — use proven ones
2. KoboRoot.tgz is reprocessed every time files are loaded; separate install and update packages
3. `selected-library = X` works on its own but crashed when combined with HomeImage overlay
4. Dictionary pre-conversion in CI produced a 76MB index too large for device RAM
5. StarDict on-device conversion (v2.17 approach) works and is fast (~1-2 min first use)
6. Always check the reference version before making assumptions about package structure
7. The v2.3-sangala-full-build release on GitHub is the original source of KFMon/NickelMenu binaries
8. Plato reads `belongs-to-collection` for series metadata even when Calibre doesn't show it — strip unwanted metadata fields in extraction code
9. For long sessions, start fresh and read CLAUDE-STATE.md for context
10. Auto-launch is handled by `plato-autostart.sh` (system partition), not KFMon
