#!/usr/bin/env bash
# Restore the "Ask Gemini" / Gemini-in-Chrome sidebar button that disappears
# after a Chrome update flips the local Variations region seed to a non-US code.
#
# Root cause: Chrome's "Local State" file records a region seed (e.g.
# "variations_country": "cn"). Gemini in Chrome is gated by region/language, so
# a non-US seed hides the button, the AI innovations setting, and chrome://settings/ai.
# Fixing the seed to "us" restores the entry points.
#
# Modes:
#   (default)        backup + rewrite region fields to target country, then verify
#   --check          diagnose only, change nothing
#   --restore        restore Local State from the most recent backup this script made
#
# Options:
#   --country <cc>   target country code (default: us)
#   --chrome-dir <p> Chrome profile data dir (default: stable channel)
#   --kill           if Chrome is running, quit it automatically before editing
#
# Safety: refuses to edit while Chrome is running (Chrome overwrites Local State
# on exit). Always backs up to "Local State.backup" before editing.
set -euo pipefail

COUNTRY="us"
MODE="fix"
KILL=0
CHROME_DIR="$HOME/Library/Application Support/Google/Chrome"

while [ $# -gt 0 ]; do
  case "$1" in
    --check) MODE="check"; shift ;;
    --restore) MODE="restore"; shift ;;
    --country) COUNTRY="$2"; shift 2 ;;
    --chrome-dir) CHROME_DIR="$2"; shift 2 ;;
    --kill) KILL=1; shift ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done

LS="$CHROME_DIR/Local State"
BACKUP="$LS.backup"

if [ ! -f "$LS" ]; then
  echo "✗ 未找到 Local State: $LS" >&2
  echo "  若用的是 Chrome Beta/Canary，请用 --chrome-dir 指定对应数据目录。" >&2
  exit 1
fi

chrome_running() { pgrep -x "Google Chrome" >/dev/null 2>&1; }

print_fields() {
  python3 - "$LS" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
keys=["variations_country",
      "variations_permanent_consistency_country",
      "variations_safe_seed_permanent_consistency_country",
      "variations_safe_seed_session_consistency_country"]
for k in keys:
    print(f"  {k} = {d.get(k, '(无此字段)')}")
PY
}

# ---- restore mode ----
if [ "$MODE" = "restore" ]; then
  if [ ! -f "$BACKUP" ]; then
    echo "✗ 没有备份可还原: $BACKUP" >&2; exit 1
  fi
  if chrome_running; then
    echo "⚠️ Chrome 正在运行，请先 Cmd+Q 完全退出再还原。" >&2; exit 1
  fi
  cp "$BACKUP" "$LS"
  echo "✓ 已用备份还原 Local State"
  exit 0
fi

echo "=== 当前地区字段 ==="
print_fields

# ---- check mode ----
if [ "$MODE" = "check" ]; then
  echo
  if python3 - "$LS" "$COUNTRY" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8')); want=sys.argv[2]
vals=[d.get("variations_country"),
      d.get("variations_safe_seed_permanent_consistency_country"),
      d.get("variations_safe_seed_session_consistency_country")]
pc=d.get("variations_permanent_consistency_country")
if isinstance(pc,list) and pc: vals.append(pc[-1])
sys.exit(0 if all(v==want for v in vals if v is not None) else 1)
PY
  then echo "✓ 地区已是 '$COUNTRY'，无需修复。"
  else echo "→ 地区不是 '$COUNTRY'，存在被隐藏入口的风险。去掉 --check 即可修复。"
  fi
  exit 0
fi

# ---- fix mode ----
if chrome_running; then
  if [ "$KILL" = "1" ]; then
    echo "… 按要求退出 Chrome"
    osascript -e 'quit app "Google Chrome"' 2>/dev/null || true
    for _ in $(seq 1 20); do chrome_running || break; sleep 0.5; done
    if chrome_running; then echo "✗ Chrome 仍未退出，请手动 Cmd+Q 后重试。" >&2; exit 1; fi
  else
    echo >&2
    echo "⚠️ Chrome 正在运行。改之前必须完全退出，否则退出时会覆盖修改。" >&2
    echo "   请按 Cmd+Q（菜单 Chrome → 退出 Google Chrome）后重试，或加 --kill 让脚本代退。" >&2
    exit 1
  fi
fi

cp "$LS" "$BACKUP"
echo "✓ 已备份 -> $BACKUP"

python3 - "$LS" "$COUNTRY" <<'PY'
import json,sys
p,want=sys.argv[1],sys.argv[2]
d=json.load(open(p,encoding='utf-8'))
changed=[]
for k in ("variations_country",
          "variations_safe_seed_permanent_consistency_country",
          "variations_safe_seed_session_consistency_country"):
    if d.get(k) is not None and d[k]!=want:
        changed.append((k,d[k],want)); d[k]=want
k="variations_permanent_consistency_country"   # [version, country]
v=d.get(k)
if isinstance(v,list) and len(v)>=2 and v[-1]!=want:
    changed.append((k,list(v),None)); v[-1]=want
json.dump(d, open(p,"w",encoding='utf-8'), separators=(',',':'), ensure_ascii=False)
if changed:
    print("=== 已修改 ===")
    for k,old,_ in changed: print(f"  {k}: {old} -> {want}")
else:
    print("(无字段需要修改，已是目标地区)")
PY

echo
echo "=== 复核（重新读文件） ==="
print_fields
python3 -c "import json;json.load(open('$LS',encoding='utf-8'));print('JSON 合法 ✓')"

cat <<EOF

下一步：
  1. 重新打开 Chrome
  2. 看右上角 Ask Gemini 按钮 / 设置里的 AI innovations / chrome://settings/ai
若仍未出现，再确认：显示语言 = English (United States)、网络在美国节点，重启后再看。
还原：  bash "$0" --restore
EOF
