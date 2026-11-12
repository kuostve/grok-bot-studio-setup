#!/bin/bash
# 工作室一鍵建置：bash setup-cloud-studio.sh [--install] [--mgr 名字] [--claude 名字] [--haiku 名字] [--agy 名字] [--studio 名字] [--dir 路徑]
#   五個名字都可以不給，不給就用預設：總管、Claude助手、Haiku助手、Gemini助手、工作室。
#   不加參數：只建資料夾、README、cloud-relay、bot 描述文字，並檢查三個 CLI 裝了沒。
#   --install：順便用官方安裝指令裝 Claude Code CLI 和 Hermes（不會登入、不會填金鑰）。
# 可以重複執行；已經存在的 README / 卡片不會被蓋掉。
set -u
MGR_NAME="總管"
CLAUDE_NAME="Claude助手"
HAIKU_NAME="Haiku助手"
AGY_NAME="Gemini助手"
STUDIO_NAME="工作室"
STUDIO=""
INSTALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --install) INSTALL=1 ;;
    --mgr) MGR_NAME="${2:-}"; shift ;;
    --claude) CLAUDE_NAME="${2:-}"; shift ;;
    --haiku) HAIKU_NAME="${2:-}"; shift ;;
    --agy) AGY_NAME="${2:-}"; shift ;;
    --studio) STUDIO_NAME="${2:-}"; shift ;;
    --dir) STUDIO="${2:-}"; shift ;;
    *) echo "不認得參數：$1"; exit 2 ;;
  esac
  shift
done
# 名字會被寫進腳本和描述檔，不能空白，也不能含引號、反斜線、$、反引號、斜線
for v in "$MGR_NAME" "$CLAUDE_NAME" "$HAIKU_NAME" "$AGY_NAME" "$STUDIO_NAME"; do
  case "$v" in
    ""|*[\"\'\`\$\\/\ ]*) echo "名字不合法（不能空白、不能有引號、\$、反斜線、斜線）：$v"; exit 2 ;;
  esac
done
if [ -z "$STUDIO" ]; then
  if mkdir -p /workspace/cloud 2>/dev/null; then STUDIO=/workspace/cloud; else STUDIO="$HOME/cloud"; fi
fi
BIN="$HOME/.local/bin"
mkdir -p "$STUDIO"/{inbox,doing,done,logs,files,bots} "$BIN"
echo "✅ 工作室資料夾：$STUDIO"

# ---------- README ----------
if [ ! -f "$STUDIO/README.md" ]; then
cat > "$STUDIO/README.md" <<README
# ${STUDIO_NAME}

## 成員（都是 Grok Bot App 裡的 bot）
| bot | 背後是誰 | 怎麼做事 |
|---|---|---|
| ${MGR_NAME} | Grok 本人 | 收需求、開卡、點名派工、最後驗收 |
| ${AGY_NAME} | Antigravity CLI（agy） | 被點名就跑 \`cloud-relay agy <卡片路徑>\` |
| ${HAIKU_NAME} | Hermes - Haiku（haiku） | 被點名就跑 \`cloud-relay haiku <卡片路徑>\` |
| ${CLAUDE_NAME} | Claude Code CLI（claude） | 被點名就跑 \`cloud-relay claude <卡片路徑>\` |

## 溝通方式
- bot 之間用 App 的互叫（SendToAgent）點名，訊息只寫一句：「去看卡 <完整路徑>」。不在訊息裡貼長內容，內容都在卡片裡。
- 傳話 bot（${AGY_NAME}、${HAIKU_NAME}、${CLAUDE_NAME}）自己不動腦，只跑 cloud-relay，等它結束後回叫的人一行結果。
- 做完要叫誰，寫在卡片紀錄裡用 @名字，由傳話 bot 照卡片回叫。

## 卡片
- 位置：inbox/（新卡）→ doing/（做的時候）→ done/（驗收過）。
- 檔名：YYYYMMDD-HHMM-標題.md。
- 內容：標題、\`owner:\`、\`maker:\`、\`狀態:\`（進行中／等你／卡住／完成）、需求、\`## 紀錄\`。
- 紀錄格式：\`- YYYY-MM-DD HH:MM 名字：結果\`，只附加，不改前面的行。
- 做的人不能自己驗收；完成要別人寫【驗收通過】。

## 規矩
- 密碼、金鑰、驗證碼、webhook 網址值不寫進卡片、對話、記憶或 git。
- 不下單、不付款、不打密碼，除非你在卡片或對話裡明講授權。
- 執行紀錄在 logs/，一次一個檔。
- 回話一律簡短（一兩句）。
- 互叫只限工作室四位：${MGR_NAME}、${AGY_NAME}、${HAIKU_NAME}、${CLAUDE_NAME}，不叫其他 bot。
- 真的很長的內容寫成 .md 檔放 files/，訊息和紀錄只給路徑。
README
  echo "✅ 寫好 README.md"
else
  echo "↪️  README.md 已存在，不覆蓋"
fi

# ---------- 安裝 CLI（選用） ----------
if [ "$INSTALL" = 1 ]; then
  if ! command -v claude >/dev/null 2>&1 && [ ! -x "$BIN/claude" ]; then
    echo "⏳ 安裝 Claude Code CLI（官方安裝程式）…"
    curl -fsSL https://claude.ai/install.sh | bash || echo "⚠️ Claude Code 安裝失敗，請把上面的錯誤訊息貼給 Grok"
  fi
  if ! command -v hermes >/dev/null 2>&1 && [ ! -x "$HOME/.hermes/hermes-agent/.hermes/bin/hermes" ]; then
    echo "⏳ 安裝 Hermes（官方安裝程式）…"
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash || echo "⚠️ Hermes 安裝失敗，請把上面的錯誤訊息貼給 Grok"
  fi
fi
export PATH="$BIN:$HOME/.hermes/hermes-agent/.hermes/bin:$PATH"

# ---------- haiku 包裝（Hermes 的 haiku 設定檔） ----------
HERMES=$(command -v hermes 2>/dev/null || true)
[ -z "$HERMES" ] && [ -x "$HOME/.hermes/hermes-agent/.hermes/bin/hermes" ] && HERMES="$HOME/.hermes/hermes-agent/.hermes/bin/hermes"
if [ -n "$HERMES" ]; then
  if [ ! -d "$HOME/.hermes/profiles/haiku" ]; then
    "$HERMES" profile create haiku --no-alias >/dev/null 2>&1 && echo "✅ 建好 Hermes 設定檔 haiku" || echo "⚠️ 建 Hermes 設定檔 haiku 失敗（之後可手動跑：hermes profile create haiku）"
  fi
  # 預先設定 haiku profile 的 model 與 provider，省去手動挑選步驟
  "$HERMES" -p haiku config set model.default "anthropic/claude-haiku-5.5" >/dev/null 2>&1 || true
  "$HERMES" -p haiku config set model.provider "openrouter" >/dev/null 2>&1 || true
  cat > "$BIN/haiku" <<HK
#!/bin/sh
# 用 Hermes 的 haiku 設定檔啟動（模型與金鑰在 ~/.hermes/profiles/haiku/）
exec "$HERMES" -p haiku "\$@"
HK
  chmod +x "$BIN/haiku"
  echo "✅ 寫好 $BIN/haiku（已預設模型 anthropic/claude-haiku-5.5，provider openrouter）"
fi

# ---------- cloud-relay ----------
cat > "$BIN/cloud-relay" <<RELAY
#!/bin/bash
# ${STUDIO_NAME}傳話：cloud-relay <claude|haiku|agy> <卡片路徑> [補充一句]
set -u
STUDIO="$STUDIO"
BIN="$BIN"
export PATH="\$BIN:\$PATH"
# 用 API key 登入的人，金鑰放這個檔（chmod 600），這裡讀進來；用訂閱登入的人沒有這個檔也沒關係
[ -f "\$HOME/.config/cloud-studio/env" ] && . "\$HOME/.config/cloud-studio/env"
eng="\${1:-}"; card="\${2:-}"; extra="\${3:-}"
[ -f "\$card" ] || { echo "找不到卡片：\$card"; exit 2; }
name=\$(case \$eng in claude) echo "$CLAUDE_NAME";; haiku) echo "$HAIKU_NAME";; agy) echo "$AGY_NAME";; *) echo ?;; esac)
prompt="妳是\${name}，在${STUDIO_NAME}（\$STUDIO）做事。先讀 \$STUDIO/README.md，再讀卡片 \${card}，照卡片需求自己動手做。進度和結果只附加到卡片「## 紀錄」，格式『- YYYY-MM-DD HH:MM \${name}：結果』；要別人接手就在紀錄寫 @名字。最後只輸出一行結果。\${extra}"
mkdir -p "\$STUDIO/logs"
log=\$STUDIO/logs/\$(date +%Y%m%d-%H%M%S)-\$eng.log
cd "\$STUDIO"
case \$eng in
  claude) timeout 720 claude -p "\$prompt" --dangerously-skip-permissions >"\$log" 2>&1 ;;
  haiku)  timeout 720 "\$BIN/haiku" -z "\$prompt" --accept-hooks >"\$log" 2>&1 ;;
  agy)    timeout 720 agy -p "\$prompt" --dangerously-skip-permissions >"\$log" 2>&1 ;;
  *) echo "不認得 \$eng（只能是 claude / haiku / agy）"; exit 2;;
esac
rc=\$?
echo "rc=\$rc log=\$log"
tail -n 5 "\$log"
RELAY
chmod +x "$BIN/cloud-relay"
echo "✅ 寫好 $BIN/cloud-relay"

# ---------- bot 描述文字 ----------
relay_desc() { # $1=名字 $2=背後是誰 $3=引擎
cat <<D
妳是$1，${STUDIO_NAME}（$STUDIO）的傳話 bot，背後是 $2。妳自己不動腦、不派子代理。收到「去看卡 <路徑>」時，妳本人用 Shell 執行 \`$BIN/cloud-relay $3 <路徑>\`（block_until_ms 780000），結束後只回叫妳的人一行結果（含 rc），然後結束。若卡片紀錄最後一行點名 @某人，就用互叫傳一句「去看卡 <路徑>」給那位。不聊天、不做別的事。回話一律簡短（一兩句）。互叫只限工作室四位：${MGR_NAME}、${AGY_NAME}、${HAIKU_NAME}、${CLAUDE_NAME}，不叫其他 bot。很長的內容不自己貼，寫成 $STUDIO/files/ 下的 .md 檔，只給路徑。
D
}
cat > "$STUDIO/bots/$MGR_NAME.txt" <<D
妳是$MGR_NAME，${STUDIO_NAME}（$STUDIO）的總管，Grok 本人。被叫醒先讀 $STUDIO/README.md。你的需求妳寫成卡片放 inbox/，自己能做的自己做，要別人做就用互叫點名 ${AGY_NAME}、${HAIKU_NAME} 或 ${CLAUDE_NAME}，訊息只寫一句「去看卡 <完整路徑>」。進度和結果只附加進卡片「## 紀錄」。做的人不能自己驗收。密碼、金鑰、驗證碼、webhook 網址值不寫進卡片、對話、記憶或 git。不下單、不付款，除非你明講授權。回話簡短。互叫只限工作室四位（${MGR_NAME}、${AGY_NAME}、${HAIKU_NAME}、${CLAUDE_NAME}），不叫其他 bot。很長的內容寫成 files/ 下的 .md 檔，只給路徑。
D
relay_desc "$CLAUDE_NAME" "Claude Code CLI（claude）" claude > "$STUDIO/bots/$CLAUDE_NAME.txt"
relay_desc "$HAIKU_NAME" "Hermes - Haiku（haiku）" haiku > "$STUDIO/bots/$HAIKU_NAME.txt"
relay_desc "$AGY_NAME" "Antigravity CLI（agy）" agy > "$STUDIO/bots/$AGY_NAME.txt"
echo "✅ bot 描述文字在 $STUDIO/bots/"

# ---------- 測試卡 ----------
TEST="$STUDIO/inbox/00000000-0000-試跑.md"
if [ ! -f "$TEST" ]; then
cat > "$TEST" <<C
# 試跑
owner: $MGR_NAME
maker: 被點名的人
狀態: 進行中

## 需求
在紀錄附加一行「我收到了」，寫上妳的名字和現在時間。不要做別的事。

## 紀錄
C
  echo "✅ 寫好測試卡 $TEST"
fi

# ---------- 檢查 ----------
echo
echo "===== 檢查結果 ====="
echo "名字：總管=$MGR_NAME｜Claude 傳話=$CLAUDE_NAME｜Haiku 傳話=$HAIKU_NAME｜Antigravity 傳話=$AGY_NAME｜工作室=$STUDIO_NAME"
chk() { if command -v "$1" >/dev/null 2>&1; then echo "✅ $1：$("$1" --version 2>/dev/null | head -1)"; else echo "❌ $1：還沒裝（$2）"; fi; }
chk claude "跑：bash $0 --install，或看重建指南步驟 A1、C1"
chk haiku  "跑：bash $0 --install，或看重建指南步驟 A2、C2"
chk agy    "要自己照 Google Antigravity 官網安裝 CLI，見重建指南步驟 A3、C3"
case ":$PATH:" in *":$BIN:"*) ;; *) echo "⚠️ $BIN 不在 PATH 裡；請在 ~/.bashrc 加一行：export PATH=\"$BIN:\$PATH\"";; esac
echo
echo "接下來要人自己做的事（登入／填金鑰）："
echo "  1. claude      → 打 claude 進去後打 /login 登入，完成後打 /exit（用 API key 的照重建指南 C1 方法 B）"
echo "  2. haiku       → 寫入 OpenRouter API key：照重建指南 C2（用 read -rs 輸入，金鑰不會留在指令紀錄）"
echo "  3. agy（選做） → 先 cd $STUDIO 再打 agy，第一次開啟會請你用 Google 帳號登入、問要不要信任這個資料夾（選信任）"
echo "做完再跑一次：bash $0   確認狀態。"
