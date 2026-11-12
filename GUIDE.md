# 從零重建工作室手把手指南

> 給第一次弄的新手朋友。請照順序做，每一步後面都有「✅ 怎麼確認成功」。
> 文件裡所有 `<在這裡填>` 或 `<你的名字>` 都是要你自己換成自己的內容；這份文件**絕不含任何人的密碼、金鑰、帳號或 bot ID**。

---

## 0. 這是什麼？（先看 1 分鐘）

你會在自己的 **Grok Bot App** 裡建立 4 隻 bot（名字由你在一鍵指令步驟 0 自己取，沒取就用預設值），讓牠們用「工作卡」互相分工合作：

| bot 名字 | 背後核心 | 做什麼 |
|---|---|---|
| **總管** | Grok 本人 | 聽你的需求 → 開卡放 `inbox/` → 點名派工 → 最後驗收 |
| **Claude 傳話** | Claude Code CLI（`claude`） | 被點名就跑 `cloud-relay claude <卡片路徑>` |
| **Haiku 傳話** | Hermes + Claude Haiku（`haiku`，經 OpenRouter） | 被點名就跑 `cloud-relay haiku <卡片路徑>` |
| **Antigravity 傳話** | Google Antigravity CLI（`agy`） | 被點名就跑 `cloud-relay agy <卡片路徑>` |

### 核心運作規則
- **卡片生命週期**：卡片是 Markdown（`.md`）檔案，狀態依序流轉：`inbox/`（剛開卡）→ `doing/`（進行中）→ `done/`（驗收完成）。
- **只附加紀錄**：所有 bot 在執行中與完成後，只能在卡片最底部的「## 紀錄」**往下加一行**，絕不修改或覆蓋前面已有的文字。
  格式範例：`- 2026-11-12 14:30 Claude 傳話：結果`
- **點名交接**：做完如果要別人接手，就在該行紀錄最後寫 `@名字`（例如 `@Haiku 傳話` 或 `@總管`）。
- **做的人不能自己驗收**：執行該張卡片的 bot 不能自己寫完成驗收；必須由另一位（例如總管或其他審核 bot）寫上【驗收通過】後，卡片才能移入 `done/`。
- **傳話 bot 不動腦**：Claude 傳話、Haiku 傳話、Antigravity 傳話是「傳話型 bot」，牠們收到指令只負責在背景跑 `cloud-relay` 腳本，呼叫對應的 CLI 真正動手做，做完回報一行結果。

> 💡 **彈性啟動**：你不需要一開始就湊齊 3 個 CLI。**哪怕只有一個（例如只有 Claude Code），工作室就能開始運作！** 沒裝的 CLI 對應的傳話 bot 先不建即可，之後想擴充隨時能補。

---

## A. 一定要你自己做的事（先做完這段）

以下步驟涉及個人帳號註冊、付款綁卡與獲取 API Key，**bot 無法代勞，必須由你本人手動完成**。
> ⚠️ **付費提醒**：任何涉及費用的服務均由你自行評估與決定，本指南不強制你付費。

### A1. Claude 帳號（給「Claude 傳話」用）
1. 打開瀏覽器前往 https://claude.ai ，使用你的 Email 或 Google 帳號註冊/登入。
2. 評估方案（二選一，均可能產生費用）：
   - **方式一（一般推薦）**：訂閱 Claude 付費方案（Pro 或 Max）。之後在終端機直接用瀏覽器 OAuth 登入即可。
   - **方式二（API 計費）**：前往 https://console.anthropic.com 註冊 Anthropic Console API 帳號、綁卡儲值，並建立一組 `sk-ant-...` 的 API 金鑰。
3. 若不想付費使用 Claude，可先跳過本步驟，只用後面的 OpenRouter Haiku（Haiku 傳話）。
4. ✅ **確認成功**：能夠登入 claude.ai 看到聊天介面（或在 console.anthropic.com 能看到你的 API Key）。

### A2. OpenRouter 帳號與 API Key（給「Haiku 傳話」用）
1. 打開瀏覽器前往 https://openrouter.ai ，點擊右上角 **Sign in** 註冊（可直接用 Google 帳號快捷登入）。
2. Claude Haiku 5.5 需要 OpenRouter 帳戶有餘額（Credits）。實際單價請以 OpenRouter 頁面當下顯示為準，不要以本指南為準。請至 **Credits** 頁面視個人需要儲值（這是你自己的決定，會產生費用）。
3. 點擊右上角頭像 → **Keys** → **Create Key**。
4. 輸入金鑰名稱（例如 `hermes-haiku`），點擊建立。系統會彈出一串 `sk-or-...` 開頭的長字串。
5. **重要：立刻將這串金鑰複製並保存在你個人的密碼管理器或安全記事本中。千萬不要貼在任何公開聊天室或卡片中！** 後續步驟 C2 會需要你在終端機使用。
6. ✅ **確認成功**：在 OpenRouter 的 Keys 列表頁面可以看到剛剛建立的 key。

### A3. Google 帳號（給「Antigravity 傳話」用，選做）
1. 準備一個現有的 Google 帳號（一般 Gmail 即可）。
2. Google Antigravity CLI（指令叫 `agy`）的存取權限與方案費用以 Google 官方當下規定為準（費用與可用範圍請自己看官網）。
3. 照 Google Antigravity 官網的說明下載 CLI。它是一個單一執行檔，放好後在終端機跑一次 `agy install`，它會幫你把路徑加進 PATH。
4. 若目前不需要或暫無 Antigravity CLI，直接跳過本步驟。
5. ✅ **確認成功**：已備妥 Google 帳號；有裝的話，終端機打 `agy --version` 會印出版本號。

### A4. ChatGPT 帳號呢？
本工作室架構**完全沒有使用 ChatGPT**，你的現有 ChatGPT 帳號保留原樣，不需要做任何調整。

### A5. 確認 Grok Bot App 權限
1. 打開你的 Grok Bot App。
2. 確認你的 bot 具備以下兩項能力：
   - **Shell（執行命令列指令）**
   - **SendToAgent（互叫點名功能）**
3. ✅ **確認成功**：隨便開一隻 bot，對牠說「用 Shell 執行 `whoami` 並回報結果」，牠能正確回報機器上的使用者名稱。

---

## B. 讓 Grok 幫你蓋好工作室（貼一段指令就好）

1. 在 Grok Bot App 中開啟一隻新 bot（暫時命名為「總管」）。
2. 打開和這份指南一起拿到的 `一鍵重建指令.md`（同一個資料夾裡）。
3. 將裡面「=====從這裡開始複製=====」以下的所有文字整段複製，直接貼送給這隻 bot。
4. Grok 會先問你五個名字（總管、Claude 傳話、Haiku 傳話、Antigravity 傳話、工作室名稱；直接按 Enter 就用預設值），然後自動執行下列動作：
   - 建立工作室目錄（`/workspace/cloud` 或 `~/cloud`）及子資料夾（`inbox/`, `doing/`, `done/`, `logs/`, `files/`, `bots/`）。
   - 寫入工作室規範 `README.md`。
   - 寫入傳話核心腳本 `~/.local/bin/cloud-relay`。
   - 下載安裝 Claude Code CLI 與 Hermes Agent。
   - 建立 Hermes 的 `haiku` 設定檔與啟動包裝腳本 `~/.local/bin/haiku`。
   - 產生 4 隻 bot 的專屬角色描述檔（放於 `bots/` 資料夾）。
   - 寫入一張初始化測試卡片 `inbox/00000000-0000-試跑.md`。
5. 執行到需要人工登入或輸入金鑰時，Grok 會依指令停下來提醒你。此時請參閱下方 C 段操作。
6. ✅ **確認成功**：Grok 輸出「===== 檢查結果 =====」，顯示 CLI 的安裝版本狀態。

---

## C. 登入和貼金鑰（在終端機打字）

> 💡 **什麼是終端機？** 指的是連線到運行 Grok Bot App 的這台 Linux 電腦的命令列視窗（SSH 或 Web Terminal）。
> **資安鐵律：密碼與 API Key 只能在終端機輸入，絕對不要貼進 Grok 聊天視窗！**

### C1. 登入 Claude Code（Claude 傳話）
1. 在終端機輸入：
   ```bash
   claude
   ```
2. 若使用 Claude.ai 訂閱方案：輸入 `/login`，瀏覽器會開啟授權網頁，授權後將驗證碼貼回終端機完成登入。
3. 打 `/exit` 離開。
4. **若你用的是 Anthropic Console API Key（不是訂閱）**，改用這段（金鑰輸入時畫面不顯示、也不會留在指令紀錄裡；`cloud-relay` 每次執行會自動讀這個檔）：
   ```bash
   mkdir -p ~/.config/cloud-studio
   read -rsp '貼上 Anthropic 金鑰（畫面不會顯示），按 Enter：' K; echo
   printf 'export ANTHROPIC_API_KEY=%s\n' "$K" > ~/.config/cloud-studio/env
   chmod 600 ~/.config/cloud-studio/env; unset K
   ```
5. ✅ **確認成功**：在終端機執行 `claude -p "回我 OK"`（用 API Key 的人先打 `. ~/.config/cloud-studio/env`），能順利印出包含 `OK` 的回應。

### C2. 設定 Haiku 的 OpenRouter 金鑰（Haiku 傳話）
建置腳本已自動將 `haiku` 的模型預設為 `anthropic/claude-haiku-5.5`，provider 預設為 `openrouter`。你只需填入在步驟 A2 取得的 OpenRouter API Key，以下兩種方法二選一：

- **方法 A（推薦，不用方向鍵選單）**：
  在終端機一行一行貼上執行。跑到第二行會等你貼金鑰：貼上 `sk-or-...` 後按 Enter（畫面不會顯示，這是正常的；金鑰也不會留在指令紀錄裡）：
  ```bash
  f=$(haiku config env-path)
  read -rsp '貼上 OpenRouter 金鑰（畫面不會顯示），按 Enter：' K; echo
  sed -i '/^OPENROUTER_API_KEY=/d' "$f"
  printf 'OPENROUTER_API_KEY=%s\n' "$K" >> "$f"; chmod 600 "$f"; unset K
  ```
  （第三行是先刪掉舊的空白設定，避免同一個名字出現兩行。）
- **方法 B（互動式選單）**：
  在終端機輸入：
  ```bash
  haiku model
  ```
  在選單中選 **OpenRouter**，貼上金鑰，確認模型為 `anthropic/claude-haiku-5.5`。
- ✅ **確認成功**：在終端機執行 `haiku -z "回我 OK"`，能順利印出包含 `OK` 的回應。

### C3. 登入 Antigravity（Antigravity 傳話，選做）
1. 若你有安裝 `agy`，先進到工作室資料夾再開（路徑換成腳本印出的「工作室資料夾」）：
   ```bash
   cd /workspace/cloud   # 或 ~/cloud
   agy
   ```
2. 依照螢幕提示使用 Google 帳號完成登入認證；若問要不要信任這個資料夾，選信任。完成後離開。
3. ✅ **確認成功**：在終端機執行 `agy -p "回我 OK"`，能順利印出回應。

---

## D. 設定 4 隻 Bot 的角色描述

腳本已在工作室的 `bots/` 資料夾下產生好 4 個純文字描述檔，檔名就是你在步驟 0 取的名字：
- `bots/<總管名>.txt`
- `bots/<Claude傳話名>.txt`
- `bots/<Haiku傳話名>.txt`
- `bots/<Antigravity傳話名>.txt`

1. **更新總管**：請 Grok 將 `bots/<總管名>.txt` 的內容貼出來，你將它複製後，貼入目前這隻總管 bot 的系統描述（Description/Profile）中。
2. **新增另外 3 隻 bot**：在 Grok Bot App 中點擊建立新 bot，名字必須和步驟 0 的答案**一字不差**，並貼上對應的檔案內容：
   - 名字：`<Claude傳話名>` ｜ 描述：貼上 `bots/<Claude傳話名>.txt` 的全部內容
   - 名字：`<Haiku傳話名>` ｜ 描述：貼上 `bots/<Haiku傳話名>.txt` 的全部內容
   - 名字：`<Antigravity傳話名>` ｜ 描述：貼上 `bots/<Antigravity傳話名>.txt` 的全部內容（若沒裝 agy 可先不建）
3. 確認每隻 bot 都已啟用 Shell 執行功能與 SendToAgent 互叫功能。
4. ✅ **確認成功**：在 Grok Bot App 的 Bot 清單中，清楚看到這幾隻名稱和步驟 0 的答案完全相符。

---

## E. 驗收與試跑

1. 打開與「<總管名>」的對話，對牠說：
   > 「請把 inbox/ 裡的試跑卡移到 doing/，然後點名 <Claude傳話名> 去看卡。」
2. 總管會將卡片移到 `doing/`，並透過 SendToAgent 發送訊息：「去看卡 <完整路徑>」給 <Claude傳話名>。
3. <Claude傳話名> 收到後，會自動在 Shell 跑 `cloud-relay claude <完整路徑>`，完成後回報一行結果（包含 `rc=0`）。所需時間依任務大小而定，單次最長 12 分鐘（超過會被中斷）。
4. 檢查卡片內容：打開該卡片，最底部的「## 紀錄」應該已經自動多出一行：
   `- 2026-11-12 14:35 <Claude傳話名>：結果...`
5. 你也可以要求總管點名 <Haiku傳話名> 或 <Antigravity傳話名>，依樣畫葫蘆跑一次。
6. 最後由總管在卡片紀錄加上 `【驗收通過】`，並將卡片移入 `done/` 資料夾。
7. ✅ **確認成功**：三隻傳話 bot 均能正常執行並留下紀錄，回傳 `rc=0`。

### 常見問題與排錯對照表
| 錯誤或現象 | 代表意義 | 解決方式 |
|---|---|---|
| `rc=0` | 執行完全成功 | 正常運作，檢查卡片紀錄即可。 |
| `rc=124` | 逾時被系統中斷（超過 12 分鐘） | 任務量過大，請總管將需求拆細成小卡片。 |
| `rc=127` 或 `command not found` | 找不到 CLI 執行檔 | 檢查 `~/.local/bin` 是否已加入 `PATH`，或重新執行建置腳本。 |
| 找不到卡片 | 卡片路徑錯誤或不存在 | 傳話訊息中必須包含卡片的絕對完整路徑。 |
| log 顯示 `401` 或 `Unauthorized` | API 金鑰無效或尚未登入 | 參照步驟 C 重新進行終端機登入或檢查 `.env` 金鑰。 |
| log 顯示 `402` 或 `insufficient credits` / `quota` | 額度已用盡 | 評估是否前往服務商儲值餘額，或換另一位成員接手。 |
| 傳話 bot 沒有動靜或回話聊天 | 描述檔設定錯誤或名字不符 | 檢查 Bot 的系統描述是否完全符合 `bots/*.txt`，確認名稱一字不差。 |

> 🔍 **除錯小撇步**：所有執行的詳細過程與輸出均完整記錄在工作室的 `logs/` 資料夾中（每次執行獨立產生一個檔案）。若遇問題，直接請總管：「幫我查看 logs/ 裡最新一份 log 的最後 30 行」，就能立刻抓出癥結！

---

## F. 日常工作流程（平時怎麼用）

1. **提需求**：直接找總管聊天，說明你想做的事（例如「幫我寫個抓天氣預報的 Python 腳本」）。
2. **開卡派工**：總管會開一張 Markdown 卡片放進 `inbox/`，並主動移到 `doing/` 點名適合的傳話 bot（Claude 傳話、Haiku 傳話或Antigravity 傳話）開工。
3. **自動接力**：被點名的傳話 bot跑完後，會在紀錄記下一筆，若需要接手就 `@下一位`。
4. **驗收結案**：所有人完成後，總管最後審閱成果，在紀錄寫下【驗收通過】，並將卡片搬移到 `done/`。

---

## G. 資安與工作室鐵律（嚴格遵守）

1. **機密不上卡、不上對話**：密碼、私鑰、API Token、身分驗證碼、Webhook 完整網址，**嚴禁**寫入任何卡片、對話紀錄、Bot 記憶或 Git 版本庫。
2. **不做未授權金流與高風險操作**：未經你本人在卡片或對話中明確指名授權，所有 bot 嚴禁進行任何線上付款、下單扣款、更換系統 root 密碼等高風險動作。
3. **免確認權限安全須知**：`cloud-relay` 腳本為了讓 CLI 能自主編輯程式碼與檔案，啟用了無提示權限參數（如 `--dangerously-skip-permissions` 或 `--accept-hooks`）。**請確保本環境為專屬的工作沙盒或專用虛擬機，切勿在存放個人敏感機密檔案的私人家用電腦上直接無防護運行！**
