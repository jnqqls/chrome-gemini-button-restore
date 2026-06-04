# chrome-gemini-button-restore

[![ShellCheck](https://github.com/jnqqls/chrome-gemini-button-restore/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/jnqqls/chrome-gemini-button-restore/actions/workflows/shellcheck.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Platform: macOS](https://img.shields.io/badge/platform-macOS-lightgrey.svg)

Restore the **Ask Gemini** / *Gemini in Chrome* sidebar button that disappears
after a Chrome update on macOS.

It ships as a [Claude Code](https://claude.com/claude-code) **skill** (`SKILL.md` +
script), but the script is a standalone Bash tool you can run on its own.

[中文说明见下方](#中文说明)

---

## The problem

After a Chrome update on macOS, the **Ask Gemini** button vanishes from the
top-right toolbar. You may also notice:

- No **AI innovations** entry in Settings
- `chrome://settings/ai` bounces back to the normal settings page
- ...even though the **Gemini web app works**, Chrome is up to date, you're
  signed in, and you're not in incognito

## The root cause

Gemini in Chrome is **region/language-gated**. A Chrome update can re-seed the
browser's local **Variations region** to a non-US code (e.g. `cn`). Chrome then
hides the button, the AI innovations setting, and `chrome://settings/ai`.

The region seed lives in Chrome's `Local State` file:

```
~/Library/Application Support/Google/Chrome/Local State
```

The fix rewrites four region fields back to `us` (keeping the Chrome version
number intact):

- `variations_country`
- `variations_permanent_consistency_country` (last element)
- `variations_safe_seed_permanent_consistency_country`
- `variations_safe_seed_session_consistency_country`

> **The Gemini web app working tells you nothing** — the toolbar button is a
> separate feature gated on this local region seed.

## Requirements

Region is only the *last mile*. These must also hold (macOS, desktop Chrome):

- Chrome is up to date — `chrome://settings/help`
- Display language = **English (United States)** — `chrome://settings/languages`
- Network / proxy on a **US** node

If all of those are fine but the button is still missing, fix the region seed.

## Usage

```bash
S=scripts/fix-chrome-gemini-region.sh

bash "$S" --check      # diagnose only (read-only, safe while Chrome runs)
# ...fully quit Chrome with Cmd+Q (closing the window is not enough)...
bash "$S"              # backup + rewrite region to us + verify
# ...reopen Chrome and confirm the button is back...
```

| Goal | Command |
|---|---|
| Diagnose only (read-only) | `bash scripts/fix-chrome-gemini-region.sh --check` |
| Fix (Chrome must be quit first) | `bash scripts/fix-chrome-gemini-region.sh` |
| Fix and auto-quit Chrome | `bash scripts/fix-chrome-gemini-region.sh --kill` |
| Roll back to backup | `bash scripts/fix-chrome-gemini-region.sh --restore` |
| Target a different country | `bash scripts/fix-chrome-gemini-region.sh --country us` |
| Chrome Beta/Canary profile | `bash scripts/fix-chrome-gemini-region.sh --chrome-dir <data-dir>` |

### The one hard rule

**Chrome must be fully quit before editing `Local State`.** Chrome rewrites that
file on exit, so editing while it runs gets silently overwritten. Quit with
`Cmd+Q` — closing the window is not enough. The script refuses to edit while
Chrome is running (use `--kill` to let it quit Chrome for you).

## Safety

- The script **always backs up** `Local State` to `Local State.backup` before editing.
- It only changes the country code — the Chrome version number is preserved.
- It re-reads the file afterward to verify the change and that the JSON is valid.
- A bad edit is one `--restore` away.
- It does **not** touch bookmarks, passwords, or browsing history.

## Use as a Claude Code skill

Drop the folder into your skills directory:

```bash
cp -r chrome-gemini-button-restore ~/.claude/skills/
```

Then just ask Claude Code something like *"fix the Chrome Gemini button"* and the
skill triggers automatically.

## Verified

Chrome `148.0.7778.216` (macOS): all four region fields were `cn` after an
update; rewriting them to `us` (Chrome fully quit, then reopened) brought the
Ask Gemini button back immediately.

## Official reference

[Use Gemini in Chrome — Google Chrome Help](https://support.google.com/chrome/answer/16283624)

---

## 中文说明

Chrome 更新后,macOS 上右上角的 **Ask Gemini**(Gemini in Chrome)侧边栏按钮消失,
设置里也没了 **AI innovations**、`chrome://settings/ai` 打不开——但 Gemini 网页版正常、
Chrome 已是最新、已登录、非无痕。

**根因**:Gemini in Chrome 受地区/语言限制。Chrome 更新会把本地 **Variations 地区种子**
刷成非美国码(如 `cn`),于是入口被隐藏。修复就是把 `Local State` 里的四个地区字段改回
`us`(版本号不动)。

> Gemini 网页能用 ≠ 工具栏按钮会出现,二者是两个独立功能。

**前提**(地区只是最后一环,这些也要满足):Chrome 最新版、显示语言 = English (United States)、
网络在美国节点。

**用法**:

```bash
S=scripts/fix-chrome-gemini-region.sh
bash "$S" --check     # 只诊断(只读,Chrome 开着也能跑)
# 用 Cmd+Q 完全退出 Chrome(只关窗口不算)
bash "$S"             # 备份 + 改地区为 us + 复核
# 重开 Chrome 确认按钮回来
```

**唯一硬性要求**:改 `Local State` 前必须**完全退出 Chrome**(否则退出时会覆盖)。脚本会拒绝
在 Chrome 运行时修改,加 `--kill` 可让它代为退出。

**安全**:每次必先备份到 `Local State.backup`,只改地区码,改完复核 JSON,出问题用 `--restore`
一键还原;不碰书签/密码/历史。

## License

[MIT](LICENSE)
