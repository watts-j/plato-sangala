# Plato Sangala — Project State

Last updated: 2026-05-05

## Reference Versions

- **v2.28-sangala** — Restores KFMon-based auto-launch on top of v2.27's content (next tag).
- **v2.27-sangala** — Last build with the minimal-KoboRoot.tgz / shell-autostart approach. Hangs on fresh install.
- **v2.19-sangala** — Last build using KFMon + NickelMenu via v2.3-derived KoboRoot.tgz. Reference for "what works".
- **v2.3-sangala-full-build** — Original baseline; source of KFMon and NickelMenu binaries (downloaded by CI).

## Resolved: Fresh install hang

**History.** Fresh installs from v2.20 onward hang on loading dots until a manual power cycle. CLAUDE-STATE previously claimed v2.20 worked; that was incorrect — see commit `0189d82` ("Remove KFMon/NickelMenu, use minimal KoboRoot.tgz"), which IS v2.20-sangala and is the breaking change. v2.20 ships the same minimal 781-byte KoboRoot.tgz as v2.27. Diff between v2.20 and v2.27 inside the tgz is just `sleep 10` → `sleep 9` in plato-autostart.sh.

**Cause.** Removing KFMon left fresh-install auto-launch to a naive `pidof nickel` + `sleep 9` script. On a freshly-reset device, Nickel needs much longer than 9s to finish first-boot init (build KoboReader.sqlite, scan partition, etc.); the script kills Nickel mid-init before Kobo's boot manager kills `on-animator.sh`, leaving the device painting loading dots indefinitely. KFMon's `on_boot = true` waits for FTE completion, which is why v2.3–v2.19 never had this issue.

**Fix (v2.28+).** CI rebuilds KoboRoot.tgz from the v2.3 release archive (system partition: KFMon + NickelMenu udev rules and binaries) and ships KFMon's `plato.ini` with `on_boot = true` plus the trigger `launch.png`. `plato-autostart.sh` is kept as a redundant launch path. NickelMenu provides a manual-launch fallback.

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

- Auto-launch: KFMon `on_boot = true` watching `/mnt/onboard/.adds/plato/launch.png`. Fires after Nickel's FTE flow completes, avoiding the fresh-install race.
- Manual launch: NickelMenu entry under Plato in Nickel's main menu.
- Redundant fallback: `plato-autostart.sh` in system partition (installed via KoboRoot.tgz).
- KoboRoot.tgz is rebuilt in CI from the v2.3 release archive (KFMon + NickelMenu udev rules + binaries) with our updated `plato-autostart.sh` injected.
- Boot delay (fallback path): `sleep 9` in plato-autostart.sh.
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

- **Fresh install hang**: addressed in v2.28 by restoring KFMon-based launch. Validate with a factory-reset Clara BW + v2.28 install package.
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
10. Auto-launch on fresh installs requires an FTE-aware trigger. `pidof nickel` + a fixed sleep is not enough — KFMon's `on_boot = true` is the proven path.
11. Nickel ignores directories starting with `.` — use dot-prefixed library folders to prevent Nickel from scanning EPUBs
12. Shell glob `*` does not match dot-files/directories — use `shopt -s dotglob` in bash
13. v2.20 (commit `0189d82`) introduced the minimal KoboRoot.tgz and removed KFMon. That is the regression — every later version inherited it.
14. Trust git history over CLAUDE-STATE.md. Verify claims against `git ls-tree`/`git diff` before acting on them.
