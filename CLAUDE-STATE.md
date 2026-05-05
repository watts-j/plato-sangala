# Plato Sangala — Project State

Last updated: 2026-05-05

## Reference Versions

- **v2.27-sangala** — Latest build (dot-prefixed libraries, dual packages, installer script, menu restructure)
- **v2.20-sangala** — Last confirmed fresh install that worked WITHOUT a hang. Compare KoboRoot.tgz and package structure to find the difference.
- **v2.3-sangala-full-build** — Original baseline (archived)

## Critical Open Issue

**Fresh install hang**: Fresh installs from v2.25+ hang on loading dots and require a forced reboot. v2.20's fresh install did NOT have this problem. The root cause is unknown but is somewhere in the KoboRoot.tgz or package structure differences between v2.20 and v2.25+. This MUST be investigated by comparing the two versions.

Key differences between v2.20 and v2.25+:
- v2.20 used KoboRoot.tgz from v2.3 release (782KB, included KFMon/NickelMenu binaries + on-animator.sh + plato-autostart.sh)
- v2.25+ uses a custom minimal KoboRoot.tgz (781 bytes, only on-animator.sh + plato-autostart.sh)
- v2.20 had non-dot library folders (STEM/, Humanities/, etc.) — Nickel scanned them
- v2.25+ has dot-prefixed library folders (.STEM/, .Humanities/, etc.) — Nickel ignores them
- The custom on-animator.sh in v2.25+ is stripped down (no KFMon, no FBInk shim)
- The v2.20 on-animator.sh was the full KFMon version (with KFMon launch, FBInk progress bar option, etc.)

**Hypothesis**: The minimal on-animator.sh may be missing something that the full KFMon version handled during boot. Or the removal of KFMon binaries leaves dangling references. Investigate by comparing the exact on-animator.sh scripts.

## Next Tag Number

**v2.28-sangala**

## Package Structure

Two packages produced per release:
- **`-install.tar.gz`** — For new/factory-reset devices. Includes `.kobo/KoboRoot.tgz`.
- **`-update.tar.gz`** — For devices that already have Plato installed. No KoboRoot.tgz.
- **`install-sangala.ps1`** — Separate download. PowerShell installer script.

**Installer script**: `sangala/installer/install-sangala.ps1` — auto-detects Kobo by volume name "KOBOeReader", determines install vs update, cleans up old non-dot library folders, copies files.

## Branch

`claude/customize-plato-ui-1Edbm`

## User Working Directory

`C:\Users\jbw3r\plato-sangala`

## Device

Kobo Clara BW (model spaBW/spaBWTPV), 1072x1448 @ 300 DPI

## Architecture

- Auto-launch: `plato-autostart.sh` in system partition (installed via KoboRoot.tgz)
- No KFMon, no NickelMenu (removed in v2.20)
- KoboRoot.tgz is minimal (781 bytes): only `on-animator.sh` + `plato-autostart.sh`
- Boot delay: `sleep 9` in plato-autostart.sh
- Dictionary: Wiktionary English (StarDict format), converted on-device on first use (~1-2 min)
- Metadata extraction: title and author only (series, year, publisher, categories ignored)
- Dictionary rendering: HTML-aware (definitions containing `<` rendered as HTML)
- Library folders: dot-prefixed (.STEM, .Humanities, etc.) to hide from Nickel's scanner
- EPUB font-size: pinch/spread gestures adjust by 0.5pt steps on reflowable docs

## Library Indices (Settings.toml)

| Index | Name       | Path                      |
|-------|------------|---------------------------|
| 0     | STEM       | /mnt/onboard/.STEM        |
| 1     | Humanities | /mnt/onboard/.Humanities  |
| 2     | Enrichment | /mnt/onboard/.Enrichment  |
| 3     | Resources  | /mnt/onboard/.Resources   |
| 4     | Vocational | /mnt/onboard/.Vocational  |
| 5     | Menu       | /mnt/onboard/.Menu        |

`selected-library = 5` (Menu — empty library, top bar always shows "Menu")

## Menu Tree

```
Menu (top bar — always shows "Menu" regardless of active library)
├── About                          → .Resources/About/
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

(Removed: Invert Colors, Reboot)

## EPUBs Included

### .Enrichment/Drama
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

### .Enrichment/Fiction
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

### .Enrichment/Sangala Story Exchange
- A Leopard in the Forest

### .Enrichment/Nonfiction
- Essays - Henry David Thoreau
- South! The Story of Shackleton - Ernest Shackleton
- The Autobiography of Benjamin Franklin
- Walden - Henry David Thoreau
- Wild Animals I Have Known - Ernest Thompson Seton

### .Enrichment/Poetry
- Lyrical Ballads - William Wordsworth
- Poetry - William Carlos Williams
- Poetry - William Shakespeare

### .STEM/Science/Biology
- Photosynthesis (AP level)
- Photosynthesis (Grade 11)
- Photosynthesis (deeper)
- Photosynthesis (overview)
- Pigment Chromatography Lab
- Plant Transport

### .Resources
- Sangala Reader Initiative (About/)
- Newsletter (Fall 2025) - REACH for Uganda (REACH for Uganda Newsletters/)

## Known Issues / Pending

- **CRITICAL: Fresh install hang** — see "Critical Open Issue" section above
- **Home landing page**: Not yet implemented. Previous HomeImage overlay approach crashed. Next approach: modify Shelf renderer to show image when books list is empty. `selected-library = 5` (Menu, empty library) works as of v2.16/v2.20.
- **`home-image` setting**: Still in Settings.toml and settings struct but not used in Home view code (disabled after crashes). Path: `/mnt/onboard/.adds/plato/resources/home.png`
- **Boot delay**: Currently 9s. Can be reduced further if testing shows stability.
- **Installer script paths**: Currently hardcoded to v2.24 paths. Needs parameterization for new versions.
- **Installer script download**: .ps1 file uploads to GitHub release successfully but may not be visible in the UI. Consider zipping it.
- **Stale library folders**: When updating from pre-v2.25 builds, old non-dot library folders (STEM/, Humanities/, etc.) must be deleted. Installer script handles this, but manual installs do not.

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
11. Nickel ignores directories starting with `.` — use dot-prefixed library folders to prevent Nickel from scanning EPUBs
12. Shell glob `*` does not match dot-files/directories — use `shopt -s dotglob` in bash
13. v2.20 used the KoboRoot.tgz from the v2.3 release (with KFMon) and fresh installs worked fine. The minimal custom KoboRoot.tgz introduced in v2.20+ causes hangs on fresh install. Root cause unknown.
