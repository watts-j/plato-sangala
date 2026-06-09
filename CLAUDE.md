# Plato Sangala — start here

Customized Plato eReader build for **Kobo Clara BW** devices in educational deployments.

## Canonical branch

**`main`** is the trunk and the GitHub default — the only branch on GitHub. (It
is the former `sangala-v2.48-base`, renamed 2026-06-09.) Confirm at session
start:

```
git branch --show-current   # terminal: main | web: claude/<session>
git status                  # expect: clean
git log -1 --format='%h %s' # expect: the latest known push
```

**Which surface are you on?** It changes how you branch (Lesson #46):

- **Terminal / local:** work directly on `main`. If a fresh clone lands you on
  an ancient commit with no `CLAUDE-STATE.md`, run
  `git fetch origin && git checkout main` before doing anything (Lesson #44).
- **Claude Code on the web:** the platform *always* creates a per-session
  `claude/*` branch off `main`'s current tip and the git proxy only lets you
  push **that** branch. This is by design — **not** the stale-clone problem, and
  **do not** `git checkout main` (it strands you on a branch you can't push).
  Verify your `claude/*` branch sits at `main`'s tip (`git log -1` matches the
  last known push), work there, and hand off. The user fast-forwards/merges the
  branch into `main` on their machine afterward.

## Read next

**`CLAUDE-STATE.md`** is the full project state: shipped versions, the
factory-reset investigation, package structure, the device-install flow, and the
numbered Lessons. Read it before acting. Trust git/GitHub over its prose for
anything git can answer (tags, branch tips, release flags).

## Load-bearing facts (details in CLAUDE-STATE.md)

- **Factory-reset bug is FIXED as of v2.49** (KFMon retrofit). v2.49–v2.54 are
  released (pre-release) on GitHub. Do not call any pre-v2.49 version stable.
- **Deploy is manual drag-drop**, not the PowerShell installer (broken on the
  user's Windows setup — see Lesson #42). v2.54+: install package, eject, wait
  3 min for dictionary conversion, then library package.
- **Don't re-propose** removed features (Calculator, Power Off, Enable WiFi,
  Frontlight presets), Nickel as a Plato alternative (Lesson #36), or the PS
  installer for production — unless explicitly asked.
- **Search-verify** vendor UI paths (Calibre, Nickel, Windows) with a current
  WebSearch before stating menu locations (Lesson #43).

## Recovering discarded experiment work

The old `claude/customize-plato-ui-1Edbm` branch (v2.49–v2.53 experiments,
deliberately discarded) is archived at the `archive/customize-plato-ui` tag.
