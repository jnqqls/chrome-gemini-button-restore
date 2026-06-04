---
name: chrome-gemini-button-restore
description: Use when the "Ask Gemini" / Gemini in Chrome sidebar button disappears after a Chrome update on macOS — symptoms include the button gone from the top-right toolbar, no "AI innovations" in Settings, and chrome://settings/ai bouncing back to normal settings, even though the Gemini web app works and Chrome is up to date and signed in. Fixes the local Variations region seed (variations_country) being stuck on a non-US code like "cn".
---

# Restore the Gemini-in-Chrome Button

## Overview
After a Chrome update, the **Ask Gemini** sidebar button can vanish because Chrome
re-seeds its local **Variations region** to a non-US code (e.g. `cn`). Gemini in
Chrome is region/language-gated, so a non-US seed hides the button, the
**AI innovations** setting, and `chrome://settings/ai`. The fix is to rewrite the
region fields in Chrome's `Local State` file back to `us`.

**Key insight:** the Gemini *web app* working tells you nothing — the toolbar
button is a separate feature ("Gemini in Chrome") gated on the local region seed.

## When to Use
Symptoms (macOS, desktop Chrome):
- Ask Gemini button gone from top-right after an update
- No "AI innovations" entry in Settings
- `chrome://settings/ai` redirects to normal settings
- Gemini web app works, Chrome is latest + signed in, not incognito

Pre-check the other official requirements first — they must ALSO hold, region is
only the last mile:
- Chrome is up to date (`chrome://settings/help`)
- Display language = **English (United States)** (`chrome://settings/languages`)
- Network/proxy on a **US** node

If those are fine but the button is still missing, the region seed is the culprit.

## The One Hard Rule
**Chrome MUST be fully quit before editing `Local State`.** Chrome rewrites that
file on exit, so editing while it runs gets silently overwritten. Quit with
`Cmd+Q` (menu → Quit Google Chrome) — closing the window is not enough.

## Quick Reference
Script: `scripts/fix-chrome-gemini-region.sh`

| Goal | Command |
|---|---|
| Diagnose only (read-only, safe while Chrome runs) | `... --check` |
| Fix (Chrome must be quit first) | `...` |
| Fix and auto-quit Chrome | `... --kill` |
| Roll back to backup | `... --restore` |
| Target a different country | `... --country us` |
| Chrome Beta/Canary profile | `... --chrome-dir <data-dir>` |

The script edits four fields in `Local State`, preserving the version number:
`variations_country`, `variations_permanent_consistency_country` (last element),
`variations_safe_seed_permanent_consistency_country`,
`variations_safe_seed_session_consistency_country`.

## Procedure
1. **Diagnose:** run with `--check` (works even while Chrome is open). If it already
   reports `us`, the region is fine — chase language/network instead.
2. **Quit Chrome:** `Cmd+Q`. Confirm it is fully closed.
3. **Fix:** run the script with no flags. It backs up to `Local State.backup`,
   rewrites the region fields to `us`, then re-reads the file to verify the change
   and that the JSON is still valid.
4. **Reopen Chrome** and confirm the Ask Gemini button / AI innovations /
   `chrome://settings/ai` are back.
5. **If anything breaks:** `--restore` puts the backup back.

```bash
S="$HOME/.claude/skills/chrome-gemini-button-restore/scripts/fix-chrome-gemini-region.sh"
bash "$S" --check     # diagnose
# ... user quits Chrome (Cmd+Q) ...
bash "$S"             # backup + fix + verify
# ... user reopens Chrome to confirm ...
```

## Common Mistakes
| Mistake | Result | Fix |
|---|---|---|
| Editing while Chrome runs | Change overwritten on quit | Quit Chrome first, or use `--kill` |
| Only closed the window | Chrome still running in background | Use `Cmd+Q` / Quit, verify with `pgrep -x "Google Chrome"` |
| Changed the version number too | Inconsistent seed | Only the country code changes; the script keeps the version |
| Assuming region is the only gate | Button still hidden | Language must be English (US) and network on a US node as well |
| No backup before manual edit | Hard to recover | The script always backs up first; never hand-edit without one |

## Real-World Impact
Verified on Chrome 148.0.7778.216 (macOS): all four region fields were `cn` after
an update; rewriting them to `us` (Chrome fully quit, then reopened) brought the
Ask Gemini button back immediately. Backup + re-read verification means a bad edit
is one `--restore` away.
