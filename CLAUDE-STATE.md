# Plato Sangala — Project State

Last updated: 2026-05-06

## Working Conventions (read first)

Long sessions on this repo have failed in two opposing ways:

1. **Over-trusting accumulated context** — earlier versions of this file carried claims like "v2.20 worked" that turned out to be wrong, and acting on them cost real cycles. This file is **not** authoritative for anything git can answer.
2. **Discarding accumulated context** — treating each turn as fresh causes forgotten work, repeated questions, and missed steps in multi-step flows.

Avoid both. Specifically:

- **Maintain a tracked task list for the session via the TodoWrite tool.** The list is the source of truth for what's pending vs. done. Don't rely on memory of conversation flow.
- **Verify load-bearing facts before claiming or acting.** Run `git tag -l`, `git log --oneline`, `git ls-tree`, or use GitHub MCP read tools to check actual state — especially for tag positions, release flags (latest/pre-release), branch tips, and shipped artifact contents. Trust git/GitHub over prose in this file.
- **Inspect what was actually built before declaring a fix shipped.** Download the release tarball and read the scripts inside. The build succeeding does not mean the right code shipped.
- **Be explicit when extrapolating.** If a recommendation is based on community lore (e.g., `/tmp/end_of_animation` as Nickel's "ready" marker, KFMon's FTE-detection mechanism), flag it as unverified rather than asserting it.

## Reference Versions

- **v2.32-sangala** — Backgrounds dictionary conversion in `plato.sh`; `plato-autostart.sh` now waits for `pidof nickel` + `KoboReader.sqlite` existence (60s cap) + 5s grace. Should both fix factory-reset hang and shrink subsequent-boot wait from 13s → ~6s. Pre-release until device-tested.
- **v2.30-sangala** — **Latest stable build.** Verified on factory-reset Clara BW: install package extracts cleanly, auto-reboot fires, Plato launches with no dot-loop overlay (`pkill -f on-animator` in `plato-autostart.sh` does it). Future tags ship as pre-release by default and must be manually promoted on the GitHub Releases page after a device test.
- **v2.31-sangala** — Pre-release. EPUBs moved out of install package (now ~68MB) into update only (~109MB). Hangs on factory-reset because `sleep 12` is too short while Nickel builds `KoboReader.sqlite`; Plato launch additionally delayed by synchronous dictionary conversion in `plato.sh`.
- **v2.28-sangala** — Failed KFMon experiment. Two launchers raced; every boot hung on dots. Do not use.
- **v2.27-sangala** — Pre-fix layout (`sleep 9`, no on-animator kill). First boot hangs on factory-reset.
- **v2.19-sangala** — Last build using KFMon + NickelMenu. Never verified on Clara BW.
- **v2.3-sangala-full-build** — Original baseline. Predates Clara BW support; do not extract its KoboRoot.tgz on Clara BW.

## Fresh install hang

**Cause.** `plato-autostart.sh` in v2.20–v2.27 used `pidof nickel` + a fixed `sleep 9` before calling `plato.sh`. On factory-reset Clara BW, Nickel takes longer than 9s to finish its boot animation phase, so plato.sh kills Nickel mid-init and the loading dots loop runs forever.

**v2.28 attempt (failed).** Reintroduced KFMon's `on_boot = true` from v2.3's KoboRoot.tgz and kept plato-autostart.sh as a "fallback". v2.3's `on-animator.sh` both starts KFMon and forks plato-autostart.sh; both then call plato.sh, which calls `killall -TERM nickel ... fmon`, and they race each other. Every boot hung on dots. Reverted in v2.29.

**v2.29 fix.** Stay on v2.27's minimal KoboRoot.tgz layout; bump `sleep 9` to `sleep 12` in plato-autostart.sh.

**Recovery from v2.28.** Factory reset (hold LIGHT during power-on for ~10s) is the cleanest path. Without a reset, installing v2.29 will overwrite `on-animator.sh` with the slim no-KFMon version, leaving the v2.3-derived KFMon binaries inert in `/usr/local/kfmon/`.

## Next Tag Number

**v2.32-sangala** (will ship as pre-release; promote manually on GitHub Releases after device test passes)

## Package Structure

Two packages produced per release; a fresh install runs both in sequence:

- **`-install.tar.gz`** — Bootstrap. System partition (`KoboRoot.tgz` with `on-animator.sh` + `plato-autostart.sh`) plus user-partition non-content (Plato app, `Settings.toml`, dictionaries, screensaver, `Kobo eReader.conf`). No EPUBs. ~30MB. Triggers Nickel's "updating" screen and an auto-reboot.
- **`-update.tar.gz`** — Content. Same user-partition files as install **plus** the dot-prefixed library skeleton (EPUBs). No `KoboRoot.tgz`. ~80MB.
- **`install-sangala.ps1`** — Separate download. PowerShell installer script.

Fresh install flow: copy install → eject → device updates and reboots → reconnect → copy update → eject. Subsequent updates just reapply the update package.

**Installer script**: `sangala/installer/install-sangala.ps1` — auto-detects Kobo by volume name "KOBOeReader", determines install vs update, cleans up old non-dot library folders, copies files.

## Branch

`claude/customize-plato-ui-1Edbm`

## User Working Directory

`C:\Users\jbw3r\plato-sangala`

## Device

Kobo Clara BW (model spaBW/spaBWTPV), 1072x1448 @ 300 DPI

## Architecture

- Auto-launch: `plato-autostart.sh` in system partition (installed via KoboRoot.tgz). Waits for `pidof nickel`, then for `/mnt/onboard/.kobo/KoboReader.sqlite` to exist (60s cap, near-zero on subsequent boots), plus a 5s grace period; then `pkill -f on-animator` and `exec /mnt/onboard/.adds/plato/plato.sh`.
- Dictionary conversion (`convert-dictionary.sh`) is forked into the background by `plato.sh` so it doesn't block Plato startup. First-launch dictionary lookups may fail until conversion completes; second launch is fine.
- No KFMon, no NickelMenu.
- KoboRoot.tgz is the committed minimal `sangala/kobo-assets/KoboRoot.tgz` (~1KB): only `etc/init.d/on-animator.sh` (slim, no KFMon hook) and `usr/local/bin/plato-autostart.sh`.
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

- **Fresh install hang**: addressed in v2.32 by waiting for `KoboReader.sqlite` to exist before killing Nickel (covers factory-reset DB build) and reducing the post-DB grace to 5s (faster on subsequent boots). Validate with a factory-reset Clara BW.

## Long-term TODO

- **Pre-convert dictionary in CI (Option B).** `plato.sh` currently forks `convert-dictionary.sh` into the background to avoid blocking Plato startup; first-launch dictionary lookups fail until conversion completes (multiple minutes on Clara BW). Better path: run `convert-dictionary.sh` once in CI, ship only the dictd-format `.dict.dz` + `.index`, no on-device conversion ever. A previous CLAUDE-STATE note claimed pre-conversion produced "a 76MB index too large for device RAM" — but `dictfmt`'s `.index` is a flat per-word offset table, not loaded entirely into RAM at runtime, so it may actually be fine. Investigate before assuming the old note still applies.
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
10. Don't reach for a non-trivial fix until you've ruled out a one-line one. The fresh-install hang may simply need a slightly longer post-Nickel sleep, not a marker-based gate or KFMon revival.
11. Nickel ignores directories starting with `.` — use dot-prefixed library folders to prevent Nickel from scanning EPUBs
12. Shell glob `*` does not match dot-files/directories — use `shopt -s dotglob` in bash
13. v2.20 (commit `0189d82`) introduced the minimal KoboRoot.tgz and removed KFMon. v2.28 tried to undo that and made things worse — putting KFMon back alongside our plato-autostart.sh creates two competing launchers, since v2.3's on-animator.sh starts both. If KFMon is ever reintroduced, plato-autostart.sh must be removed (or made a no-op) at the same time.
14. Trust git history over CLAUDE-STATE.md. Verify claims against `git ls-tree`/`git diff` before acting on them.
15. Inspect the actual built artifact (download the install tarball, extract KoboRoot.tgz, read the scripts) before declaring a fix complete. Building correctly does not imply running correctly.
