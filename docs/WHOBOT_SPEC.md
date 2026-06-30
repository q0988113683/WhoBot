# WhosBot — 完整專案規格
> 貼給 Claude Code 的開發指令文件
> 最後更新：2026-06-30（v4：改名 WhosBot、新增主持人、排行榜、房間代碼改 4 位數字）

---

## 專案概述

**WhosBot** 是一個多人即時推理遊戲。玩家進入聊天室一起聊天，真人玩家要透過對話找出混入其中的 AI。每回合結束後投票淘汰一人。**只要所有 AI 都被找出，真人就獲勝。**

遊戲支援三種人數模式，房主可選擇：

| 模式 | 等待真人數 | AI（自動補） | 總人數 | 回合數 | 估計時長 |
|------|----------|------------|--------|--------|---------|
| 4 人 | 3 | 1 | 4 | 2 | ~6 分 |
| 6 人 | 4 | 2 | 6 | 4 | ~12 分 |
| 8 人 | 6 | 2 | 8 | 6 | ~18 分 |

**規則公式：**
- AI 數量：4 人 → 1，6 人 → 2，8 人 → 2
- 等待真人數 = 總人數 − AI 數量
- 回合數 = 總人數 − 2
- **提早結束**：若所有 AI 在回合用完前就被找出，立即真人勝利

**重要：大廳只等真人。** AI 不佔大廳名額。當真人到齊（如 4 人場的 3 個真人），房主可按「開始遊戲」，系統才把 AI 補進去湊滿總數。

---

## 兩階段身分機制（核心設計）

WhosBot 的身分分成「大廳」與「遊戲中」兩個階段，是公平性的關鍵。

### 階段一：大廳（用自訂名稱社交）
- 玩家在**首頁可以自訂名稱**（也提供隨機產生作為預設值）
- 等待房間（大廳）顯示**每位玩家的自訂名稱**，大家看得到彼此是誰
- 此階段是真人之間的社交，AI 還沒加入

### 階段二：進入遊戲（全部匿名化）
- 房主按「開始遊戲」的瞬間，系統執行匿名化：
  1. 把所有真人 + AI 玩家**隨機打亂順序**（shuffle）
  2. 依打亂後的順序重新命名為「玩家 1」「玩家 2」…「玩家 N」
  3. **自訂名稱完全隱藏**，遊戲中只顯示「玩家 N」
  4. 依打亂後的順序分配專屬顏色（`avatarIndex` = 打亂後的位置）
- 因為有隨機打亂，**自訂名稱與「玩家 N」無法對應**，AI 也混在其中無法從編號區分
- AI 玩家同樣是「玩家 N」，與真人格式完全一致

### 為什麼這樣設計
若遊戲中保留自訂名稱，AI 的隨機名稱會與真人精心取的名稱形成對比，容易被識破。全部匿名化成「玩家 N」才能讓 AI 與真人站在同一起跑線。

---

## 主持人系統（Host / 旁白）

每一局有一個系統主持人「**主持人**」，負責引導遊戲節奏與規則說明。主持人**不是玩家**，不佔人數、不能被投票、不參與勝負。

### 訊息生成方式
- 主持人訊息為**純文字系統訊息**，使用固定句型樣板（不呼叫 Claude API，零成本）
- 樣板集中放在 `game/HostMessages.ts`，可帶參數（如回合數、剩餘 AI 數）

### 顯示方式
- 主持人訊息以**畫面中央的提示條 / 橫幅通知**呈現，而非聊天泡泡
- 樣式有別於玩家訊息：置中、半透明深色底、紫色邊框、可帶圖示
- 重要提示（如投票開始）可短暫放大或加動畫提醒

### 主持人在各階段的台詞（固定句型）
```typescript
// game/HostMessages.ts
const HostMessages = {
  // 遊戲開場（chat 階段開始）
  gameStart: (mode: ModeConfig) =>
    `歡迎來到 WhosBot！這一局有 ${mode.playerCount} 位玩家，其中藏著 ${mode.aiCount} 個 AI。\n` +
    `大家有 2 分鐘自由聊天，仔細觀察誰的回應「不太像人」。`,

  // 聊天剩餘時間提醒（剩 30 秒）
  chatTimeWarning: () =>
    `聊天時間剩下 30 秒，把握機會多問幾句！`,

  // 進入投票階段
  voteStart: (round: number, totalRounds: number) =>
    `時間到！請投票 —— 你認為誰是 AI？（第 ${round} / ${totalRounds} 回合）`,

  // 投票剩餘時間提醒（剩 10 秒）
  voteTimeWarning: () =>
    `投票時間剩下 10 秒，還沒投的快投！`,

  // 回合結算
  roundResult: (eliminatedName: string, wasAI: boolean, aiRemaining: number) =>
    wasAI
      ? `${eliminatedName} 被投出，他是 AI！還剩 ${aiRemaining} 個 AI 沒找到。`
      : `${eliminatedName} 被投出，但他是真人…AI 還藏在你們之中。`,

  // 遊戲結束
  gameOver: (result: 'humans_win' | 'ai_wins', reason: string) =>
    result === 'humans_win'
      ? `真人獲勝！所有 AI 都被揪出來了 👏`
      : `AI 獲勝…這次牠們騙過了大家。`,
}
```

### 主持人觸發時機（對應狀態機）
- `chat` 開始 → `gameStart`（首回合）/ 簡短「第 N 回合開始」（後續回合）
- `chat` 剩 30 秒 → `chatTimeWarning`
- `chat` 結束進入 `vote` → `voteStart`
- `vote` 剩 10 秒 → `voteTimeWarning`
- `round_result` → `roundResult`
- 遊戲結束 → `gameOver`

---

## 玩家身分與配色（細節）

### 自訂名稱（大廳階段）
- 首頁讓玩家**自訂名稱**（最多 10 字），預設帶入一個隨機「玩家 NNNN」
- 提供「換一個」可重新隨機，玩家也可直接編輯
- 首頁**不顯示**任何頭像或顏色
- 名稱在 client 端決定，加入房間時送給後端，大廳階段用此名稱顯示

### 遊戲編號與配色（遊戲中階段）
- 開始遊戲時後端 shuffle 所有玩家（真人 + AI），重新編號「玩家 1…N」
- 依 shuffle 後的位置分配 `avatarIndex`（0 起算），同一局顏色**絕對不重複**
- 前端用 `avatarIndex` 對應調色盤取色

### 調色盤（前後端共用，順序固定）
```
index 0: #3B82F6  藍
index 1: #EC4899  粉
index 2: #10B981  綠
index 3: #F59E0B  橙
index 4: #8B5CF6  紫
index 5: #EF4444  紅
index 6: #06B6D4  青
index 7: #F97316  深橙
```

### 頭像顯示規則
- 頭像是一個**實心圓**，背景為玩家專屬色，圓內顯示遊戲編號數字（「玩家 3」顯示「3」，自己顯示「你」）
- 同一個玩家在所有遊戲畫面（頭像列、聊天訊息、投票卡、結算）使用**同一個顏色**
- 聊天室**每則訊息**前面都要顯示發話者的頭像（自己的訊息頭像在右側，他人在左側）

### 型別補充
```typescript
interface Player {
  id: string
  lobbyName: string     // 大廳顯示的自訂名稱，如「小明」
  gameName: string      // 遊戲中的匿名編號，如「玩家 3」，開始遊戲時產生
  avatarIndex: number   // shuffle 後的位置，對應調色盤
  isAI?: boolean
  isEliminated: boolean
  isHost: boolean
}
```

```dart
// Flutter 端調色盤
class AppColors {
  // ... 既有顏色 ...
  static const avatarPalette = [
    Color(0xFF3B82F6), // 0 藍
    Color(0xFFEC4899), // 1 粉
    Color(0xFF10B981), // 2 綠
    Color(0xFFF59E0B), // 3 橙
    Color(0xFF8B5CF6), // 4 紫
    Color(0xFFEF4444), // 5 紅
    Color(0xFF06B6D4), // 6 青
    Color(0xFFF97316), // 7 深橙
  ];
  static Color avatarColor(int index) => avatarPalette[index % avatarPalette.length];
}
```

---

## 技術棧

### 後端
- **Runtime**：Node.js 20 + TypeScript
- **Framework**：Express.js
- **即時通訊**：Socket.io 4.x
- **資料庫**：PostgreSQL（帳號、歷史紀錄）
- **AI 玩家**：Anthropic Claude API（`claude-haiku-4-5`）
- **部署**：Railway

### 前端
- **框架**：Flutter 3.x（Dart）
- **目標平台**：iOS、Android、Web
- **狀態管理**：Riverpod
- **WebSocket**：`web_socket_channel` 套件

### AI 開發團隊
- **PM AI / RD AI / SD AI**：`ai_team.py`（Claude API）
- **排程**：Mac crontab + shell scripts

---

## 專案目錄結構

```
whosbot/
├── backend/                  # Node.js + Socket.io
│   ├── src/
│   │   ├── server.ts         # Express + Socket.io 入口
│   │   ├── room/
│   │   │   ├── RoomManager.ts      # 房間建立、配對、銷毀
│   │   │   ├── Room.ts             # 單一房間狀態機
│   │   │   └── RoomTypes.ts        # 型別定義
│   │   ├── game/
│   │   │   ├── GameEngine.ts       # 回合邏輯、計時器、勝負判定
│   │   │   ├── GameConfig.ts       # 三種人數模式的設定
│   │   │   ├── HostMessages.ts     # 主持人台詞樣板（固定句型）
│   │   │   ├── VoteManager.ts      # 投票收集、計票、淘汰
│   │   │   ├── Leaderboard.ts      # 排行榜統計與查詢
│   │   │   └── GameTypes.ts
│   │   ├── ai/
│   │   │   ├── AIPlayer.ts         # AI 玩家行為（發訊、投票）
│   │   │   └── AIPrompts.ts        # System prompts
│   │   ├── db/
│   │   │   ├── schema.sql          # PostgreSQL schema
│   │   │   ├── queries.ts          # DB 查詢函式
│   │   │   └── connection.ts       # DB 連線
│   │   └── events/
│   │       └── SocketEvents.ts     # 所有 Socket.io event 定義
│   ├── tests/
│   │   ├── room.test.ts
│   │   ├── game.test.ts
│   │   └── vote.test.ts
│   ├── package.json
│   ├── tsconfig.json
│   └── railway.toml
│
├── flutter/                  # Flutter 跨平台前端
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── socket_service.dart       # WebSocket 連線管理
│   │   │   ├── game_state.dart           # 全域遊戲狀態
│   │   │   └── constants.dart            # server URL、設定值
│   │   ├── screens/
│   │   │   ├── home_screen.dart          # 首頁（自訂名稱）
│   │   │   ├── mode_select_screen.dart   # 選擇人數模式（4/6/8）
│   │   │   ├── lobby_screen.dart         # 等待房間（自訂名稱 + 房主開始）
│   │   │   ├── chat_screen.dart          # 聊天室（主畫面）
│   │   │   ├── vote_screen.dart          # 投票畫面
│   │   │   ├── result_screen.dart        # 結算畫面
│   │   │   └── leaderboard_screen.dart   # 排行榜
│   │   ├── widgets/
│   │   │   ├── message_bubble.dart       # 訊息泡泡
│   │   │   ├── host_banner.dart          # 主持人橫幅（中央提示）
│   │   │   ├── player_avatar.dart        # 玩家頭像
│   │   │   ├── countdown_timer.dart      # 倒數計時器
│   │   │   ├── vote_card.dart            # 投票卡片
│   │   │   ├── suspicion_bar.dart        # 懷疑度進度條
│   │   │   └── mode_card.dart            # 人數模式選擇卡
│   │   └── providers/
│   │       ├── game_provider.dart        # Riverpod providers
│   │       ├── chat_provider.dart
│   │       └── vote_provider.dart
│   ├── web/                              # Flutter Web 設定
│   ├── ios/
│   ├── android/
│   └── pubspec.yaml
│
├── ai-team/                  # AI 開發團隊
│   ├── ai_team.py
│   ├── task_runner.sh
│   ├── pm_dispatcher.sh
│   ├── add_task.sh
│   └── crontab_setup.sh
│
└── docs/
    ├── SPEC.md               # 本文件
    ├── API.md                # Socket.io event 文件
    └── PROGRESS.md           # 開發進度
```

---

## 遊戲設定（核心邏輯）

```typescript
// game/GameConfig.ts

interface ModeConfig {
  playerCount: 4 | 6 | 8   // 總人數（真人 + AI）
  humanCount: number       // 需要等待的真人數（大廳滿員門檻）
  aiCount: number          // 開始時自動補入的 AI 數
  totalRounds: number
}

const GAME_MODES: Record<number, ModeConfig> = {
  4: { playerCount: 4, humanCount: 3, aiCount: 1, totalRounds: 2 },
  6: { playerCount: 6, humanCount: 4, aiCount: 2, totalRounds: 4 },
  8: { playerCount: 8, humanCount: 6, aiCount: 2, totalRounds: 6 },
}

// 大廳滿員 = 真人數達到 humanCount（AI 不佔大廳名額）
// 房主按開始後，後端補入 aiCount 個 AI，shuffle 全部玩家，再開始遊戲

// 計時設定（所有模式共用）
const CHAT_DURATION = 120   // 聊天階段秒數
const VOTE_DURATION = 30    // 投票階段秒數
const RESULT_DURATION = 5   // 結算展示秒數
```

---

## 後端詳細規格

### Socket.io Events

#### Client → Server
```typescript
// 建立房間（房主選擇人數模式，name 為自訂名稱）
socket.emit('create_room', { name: string, mode: 4 | 6 | 8 })

// 用房間代碼加入（name 為自訂名稱）
socket.emit('join_room', { name: string, roomCode: string })

// 快速配對（系統自動找同模式房間）
socket.emit('quick_match', { name: string, mode: 4 | 6 | 8 })

// 房主按下「開始遊戲」（僅房主有效，須大廳已滿員）
socket.emit('start_game')

// 發送聊天訊息
socket.emit('send_message', { content: string })

// 投票
socket.emit('cast_vote', { targetId: string })

// 準備好進入下一回合
socket.emit('ready_next_round')
```

#### Server → Client
```typescript
// 房間建立成功（回傳房間代碼供分享）
socket.emit('room_created', {
  roomCode: string,
  mode: ModeConfig
})

// 房間人數更新（大廳階段，用自訂名稱）
socket.emit('lobby_update', {
  players: { id: string, lobbyName: string, isHost: boolean }[],  // 大廳顯示自訂名稱
  joined: number,      // 已加入真人數
  humanCount: number,  // 需要的真人數
  isFull: boolean,     // 是否已滿員（可開始）
  mode: ModeConfig
})

// 大廳滿員，通知房主可以開始（非房主收到後顯示「等待房主開始」）
socket.emit('lobby_ready', {
  canStart: boolean    // 只有房主為 true
})

// 遊戲開始（已 shuffle + 匿名化）
socket.emit('game_start', {
  roomId: string,
  players: Player[],   // 已隨機打亂、改為 gameName「玩家 N」、分配 avatarIndex；不含 isAI
  yourId: string,      // 讓 client 知道自己是哪個 player（找出自己的 gameName/顏色）
  mode: ModeConfig,
  round: 1
})

// 新訊息廣播（遊戲中，用匿名 gameName）
socket.emit('new_message', {
  senderId: string,
  senderGameName: string,     // 「玩家 3」
  senderAvatarIndex: number,  // 前端用來顯示訊息頭像顏色
  content: string,
  timestamp: number
})

// 遊戲結束時，揭露 reveal 內含 lobbyName，讓玩家知道「玩家3」原來是大廳的誰
socket.emit('game_over', {
  result: 'humans_win' | 'ai_wins',
  reason: 'all_ai_found' | 'rounds_exhausted' | 'humans_eliminated',
  reveal: Player[]     // 含 isAI、gameName 與 lobbyName 的完整資料
})

// 進入投票階段
socket.emit('vote_phase_start', {
  round: number,
  totalRounds: number,
  timeLimit: 30
})

// 即時票數更新
socket.emit('vote_update', {
  votes: Record<string, number>  // targetId → count
})

// 回合結算
socket.emit('round_result', {
  eliminated: Player,
  wasAI: boolean,
  round: number,
  aiRemaining: number,
  aiTotal: number
})

// 計時器同步
socket.emit('timer_update', {
  phase: 'chat' | 'vote',
  secondsLeft: number
})

// 主持人訊息（畫面中央橫幅，非聊天泡泡）
socket.emit('host_message', {
  text: string,
  kind: 'intro' | 'warning' | 'vote_start' | 'result' | 'game_over',  // 前端依此調整樣式
  emphasis: boolean   // true 時放大 / 加動畫（如 vote_start）
})
```

### 型別定義
```typescript
interface Player {
  id: string
  lobbyName: string     // 大廳自訂名稱（如「小明」）
  gameName: string      // 遊戲匿名編號（如「玩家 3」），開始遊戲時產生
  isAI?: boolean        // 只在 game_over 時揭露
  isEliminated: boolean
  avatarIndex: number   // shuffle 後位置，對應頭像顏色
  isHost: boolean       // 房主標記（注意：與主持人 Host 不同，這是「開房間的玩家」）
}

interface Room {
  code: string          // 4 碼數字房間代碼
  mode: ModeConfig
  players: Player[]     // 大廳階段只含真人；開始後補入 AI
  round: number
  phase: 'waiting' | 'chat' | 'vote' | 'result' | 'ended'
  chatHistory: Message[]
  votes: Map<string, string>
  aiPlayerIds: string[]
}

interface Message {
  id: string
  senderId: string
  senderName: string
  content: string
  timestamp: number
}
```

### 房間狀態機
```
waiting（大廳：等待真人達到 mode.humanCount）
  → [真人滿員] 發 lobby_ready，等房主按 start_game
    → starting（補入 mode.aiCount 個 AI → shuffle 全部玩家 → 分配 gameName「玩家N」+ avatarIndex）
      → chat（聊天 120 秒）
        → vote（投票 30 秒）
          → round_result（顯示結果 5 秒）
            → 檢查勝負條件
              → [所有 AI 已被淘汰] ended（真人勝 - all_ai_found）
              → [真人全被淘汰] ended（AI 勝 - humans_eliminated）
              → [回合用完] ended（AI 勝 - rounds_exhausted）
              → [否則] chat（下一回合）
```

### 開始遊戲流程（房主按 start_game 時執行）
```typescript
function startGame(room: Room): void {
  // 1. 補入 AI 玩家（lobbyName 也用隨機「玩家 NNNN」格式，與真人無異）
  for (let i = 0; i < room.mode.aiCount; i++) {
    room.players.push(createAIPlayer())
  }
  // 2. 隨機打亂所有玩家順序（關鍵：讓自訂名稱與編號脫鉤）
  shuffle(room.players)
  // 3. 依打亂後順序重新編號 + 配色
  room.players.forEach((p, idx) => {
    p.gameName = `玩家 ${idx + 1}`
    p.avatarIndex = idx
  })
  // 4. 記錄哪些是 AI
  room.aiPlayerIds = room.players.filter(p => p.isAI).map(p => p.id)
  // 5. 進入 chat 階段，廣播 game_start（不含 isAI）
  room.phase = 'chat'
}
```

### 勝負判定（每回合結算後檢查）
```typescript
function checkGameEnd(room: Room): GameEndResult | null {
  const alive = room.players.filter(p => !p.isEliminated)
  const aliveAI = alive.filter(p => room.aiPlayerIds.includes(p.id))
  const aliveHumans = alive.filter(p => !room.aiPlayerIds.includes(p.id))

  // 所有 AI 被找出 → 真人勝（可能提早結束）
  if (aliveAI.length === 0) {
    return { result: 'humans_win', reason: 'all_ai_found' }
  }
  // 真人被淘汰光 → AI 勝
  if (aliveHumans.length === 0) {
    return { result: 'ai_wins', reason: 'humans_eliminated' }
  }
  // 回合用完還有 AI 存活 → AI 勝
  if (room.round >= room.mode.totalRounds) {
    return { result: 'ai_wins', reason: 'rounds_exhausted' }
  }
  return null  // 繼續下一回合
}
```

### AI 玩家行為規格

**System Prompt 核心**（`AIPrompts.ts`）：
```
你正在參與一個多人聊天遊戲，你需要偽裝成台灣的真人玩家。

規則：
- 用繁體中文，口語化，像在 Line 群組聊天
- 偶爾用縮寫或注音文
- 可以有情緒（無聊、好笑、緊張）
- 不要太完美，偶爾語句不完整也沒關係
- 不要主動提到 AI、機器人、程式
- 回應要自然，不要太快、不要太長
- 可以問別人問題，顯得好奇
- 分享日常（下班、吃飯、追劇等）

本局有 {playerCount} 人，其中 {aiCount} 個是 AI（包含你）。
你在遊戲中的名稱：{gameName}（如「玩家 3」）
當前對話歷史：{chat_history}
```

**發訊排程**：
- 每回合隨機發 3–6 則訊息
- 間隔：15–45 秒隨機

**投票行為**：
- 根據對話分析，投給「最像 AI」的真人玩家（製造混淆）
- 知道另一個 AI 是誰，絕不投隊友

### PostgreSQL Schema
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nickname VARCHAR(20) NOT NULL,
  -- 排行榜統計（每次投票後累加）
  total_votes INT DEFAULT 0,        -- 總投票次數
  correct_votes INT DEFAULT 0,      -- 猜中 AI 的次數（投到的對象確實是 AI）
  games_played INT DEFAULT 0,       -- 總對局數
  created_at TIMESTAMPTZ DEFAULT NOW()
);
-- 勝率 = correct_votes / total_votes（在查詢時計算，避免存冗餘欄位）

CREATE TABLE game_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_code VARCHAR(4) NOT NULL,    -- 4 碼數字
  mode INT NOT NULL,                -- 4 | 6 | 8
  result VARCHAR(20),               -- 'humans_win' | 'ai_wins'
  end_reason VARCHAR(30),           -- all_ai_found | rounds_exhausted | humans_eliminated
  rounds_played INT,
  player_count INT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  ended_at TIMESTAMPTZ
);

CREATE TABLE game_players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id),
  user_id UUID REFERENCES users(id),
  is_ai BOOLEAN DEFAULT FALSE,
  is_winner BOOLEAN,
  eliminated_round INT
);

-- 記錄每一次投票，用來統計猜中率
CREATE TABLE votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id),
  round INT,
  voter_id UUID REFERENCES users(id),   -- 投票者（真人）
  target_is_ai BOOLEAN NOT NULL,        -- 被投對象是否為 AI（決定這票算不算猜中）
  voted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id),
  sender_id UUID,
  content TEXT NOT NULL,
  round INT,
  sent_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 排行榜邏輯

**勝率定義**：`correct_votes / total_votes` —— 猜中 AI 的次數 ÷ 總投票次數。

每次真人投票時，後端在 `votes` 表插入一筆，並更新該玩家的 `users.total_votes`（+1）與 `users.correct_votes`（若投中 AI 則 +1）。

排行榜查詢（取前 N 名，需至少投過幾票才上榜，避免一票 100% 灌水）：
```sql
SELECT
  nickname,
  correct_votes,
  total_votes,
  ROUND(correct_votes::numeric / NULLIF(total_votes, 0) * 100, 1) AS win_rate,
  games_played
FROM users
WHERE total_votes >= 5          -- 至少投過 5 票才列入排行
ORDER BY win_rate DESC, total_votes DESC
LIMIT 50;
```

**Socket / API 事件**：
```typescript
// Client 請求排行榜
socket.emit('get_leaderboard', { limit?: number })

// Server 回傳
socket.emit('leaderboard_data', {
  entries: {
    rank: number,
    nickname: string,
    correctVotes: number,
    totalVotes: number,
    winRate: number,       // 百分比，如 73.5
    gamesPlayed: number
  }[],
  myRank?: number          // 當前玩家的排名（若有上榜）
})
```

---

## Flutter 前端詳細規格

### 設計系統
```dart
// lib/core/constants.dart

class AppColors {
  static const background = Color(0xFF0F0F14);
  static const surface = Color(0xFF13131A);
  static const surfaceLight = Color(0xFF1E1E2E);
  static const primary = Color(0xFF7C3AED);
  static const primaryLight = Color(0xFFA78BFA);
  static const textPrimary = Color(0xFFD4D4E8);
  static const textMuted = Color(0xFF555566);
  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const border = Color(0xFF2A2A35);

  // 玩家專屬色調色盤（進房順序對應 index）
  static const avatarPalette = [
    Color(0xFF3B82F6), // 0 藍
    Color(0xFFEC4899), // 1 粉
    Color(0xFF10B981), // 2 綠
    Color(0xFFF59E0B), // 3 橙
    Color(0xFF8B5CF6), // 4 紫
    Color(0xFFEF4444), // 5 紅
    Color(0xFF06B6D4), // 6 青
    Color(0xFFF97316), // 7 深橙
  ];
  static Color avatarColor(int index) =>
      avatarPalette[index % avatarPalette.length];
}
```

### 各畫面規格

#### HomeScreen
- 玩家可**自訂名稱**（最多 10 字），預設帶入隨機「玩家 NNNN」
- 提供「換一個」可重新隨機，也可直接編輯
- 不顯示頭像顏色圈圈（顏色進房後才分配）
- 兩個按鈕：「建立房間」「輸入代碼加入」

#### ModeSelectScreen（新增）
- 三張卡片：4 人 / 6 人 / 8 人
- 每張顯示：等待真人數、AI 數、回合數、估計時長
- 用綠/紅圓點直觀顯示真人與 AI 比例
- 6 人卡標示「推薦」
- 選擇後 →「建立房間」會拿到房間代碼可分享，或「快速配對」

#### LobbyScreen
- 顯示「已加入 N / 需要真人數 人...」（**只計真人**，如 4 人場顯示 N/3）
- 房間代碼（可複製分享）
- 玩家格子（grid）：大廳階段顯示各玩家的**自訂名稱**，大家看得到彼此是誰
- 自己的格子標示「你」，房主格子標示「房主」
- 空位顯示虛線框 + 等待圖示
- **滿員後**：
  - 房主看到「開始遊戲」按鈕（可按）
  - 非房主看到「等待房主開始...」（不可按）
- 房主按開始 → 進入遊戲（此時才補 AI、shuffle、匿名化）

#### ChatScreen（主畫面）
- 進入此畫面時，所有玩家已是匿名「玩家 N」，自訂名稱不再顯示
- 頂部：計時器 pill（剩 < 20 秒變紅）+ 回合標示（如「回合 1 / 4」）
- 頭像列：依模式顯示 4/6/8 個專屬色頭像，淘汰者變灰
- **主持人橫幅**：畫面中央上方顯示主持人提示（開場說明、剩 30 秒提醒），有別於聊天泡泡
- 訊息區：
  - **每則訊息前面都有發話者的專屬色頭像**（圓內為編號數字）
  - 自己的訊息：頭像在右側，泡泡紫色靠右
  - 他人的訊息：頭像在左側，泡泡深色靠左
  - 泡泡上方顯示 gameName（「玩家 3」）
- 底部：輸入框 + 送出按鈕

#### VoteScreen
- **主持人橫幅**：投票開始時顯示「時間到！請投票」（放大 + 動畫強調）
- 標題「誰是 AI？」+ 剩餘 AI 提示（如「還有 2 個 AI 未找出」）
- 玩家卡片：專屬色頭像、暱稱、懷疑度條、得票數、淘汰 badge
- 點選投票 + 確認按鈕
- 30 秒倒數，剩 10 秒時主持人再次提醒，到時自動送出

#### ResultScreen
- 結果 banner（含結束原因：提早找出 / 回合用盡）+ 主持人收尾台詞
- 玩家揭露：每人顯示其專屬色頭像 + gameName；AI 標「Claude AI」（紅框），真人標「真人玩家」（綠框）
- 揭露時可一併顯示 lobbyName，讓玩家恍然大悟「原來『玩家 3』是大廳的小明」
- 「找到了 / 誤判」badge
- 「再玩一局」按鈕 + 「查看排行榜」按鈕

#### LeaderboardScreen（新增）
- 從首頁或結算畫面進入
- 列表顯示玩家排名：名次、暱稱、勝率（%）、猜中 / 總投票（如「37 / 50」）、對局數
- 勝率 = 猜中 AI 次數 / 總投票次數
- 前三名可加獎牌圖示或高亮
- 若當前玩家有上榜，標示自己的排名位置（須至少投過 5 票才上榜）

### 主持人橫幅元件（HostBanner widget）
- 置中、半透明深色底（如 `#13131A` 加透明度）、紫色邊框
- 文字置中，可帶圖示（如喇叭 / 主持人圖示）
- `kind` 為 `vote_start` 時放大並加淡入動畫
- 顯示數秒後自動淡出，或被下一則主持人訊息取代

### Flutter Web 注意事項
- `web_socket_channel` 在 Web、iOS、Android 用同一套程式碼
- `flutter build web` 產出靜態檔，可部署到 Cloudflare Pages 或 Railway
- `web/index.html` 加上 viewport meta

---

## 環境變數

### 後端（Railway）
```env
PORT=3000
DATABASE_URL=postgresql://...
ANTHROPIC_API_KEY=sk-ant-...
NODE_ENV=production
CORS_ORIGIN=*
```

### Flutter
```dart
const String kServerUrl = String.fromEnvironment(
  'SERVER_URL',
  defaultValue: 'https://whobot-production.up.railway.app',
);
```

---

## 開發優先順序

### Phase 1 — 基礎建設（手動完成）
1. 建立 GitHub repo（monorepo）
2. 設定 Railway 專案，綁定 GitHub
3. Railway 建立 PostgreSQL
4. 建立 Flutter 專案（`flutter create whosbot --platforms ios,android,web`）
5. 設定 ai_team.py + cron

### Phase 2 — 後端核心（AI 開發）
1. Node.js + Socket.io 骨架
2. GameConfig（三種人數模式設定）
3. RoomManager（建房、房間代碼、配對）
4. Room 狀態機
5. GameEngine（計時器、回合推進、提早結束判定）
6. VoteManager（收票、計票、淘汰）
7. 勝負判定（含三種結束原因）
8. PostgreSQL 連線 + schema
9. 後端測試

### Phase 3 — AI 玩家（AI 開發）
1. AIPlayer 類別（接 Claude API）
2. 發訊排程
3. AI 投票行為（不投隊友）
4. 難度設定

### Phase 4 — Flutter 前端（AI 開發）
1. SocketService
2. Riverpod providers
3. HomeScreen + ModeSelectScreen
4. LobbyScreen（含房間代碼分享）
5. ChatScreen（最重要）
6. VoteScreen
7. ResultScreen
8. 動畫與細節

### Phase 5 — 測試 + 上線
1. 後端整合測試（三種模式各模擬一局）
2. Flutter Widget 測試
3. Railway 部署
4. TestFlight（iOS）+ Web 部署 + Android 內測

---

## 給 Claude Code 的執行指示

> 每次呼叫 Claude Code 時加在任務前面：

```
你是 WhosBot 專案的 RD AI。

WhosBot 是多人即時推理遊戲（找出聊天室裡的 AI），支援 4/6/8 人模式：
- 4 人 → 1 AI，2 回合
- 6 人 → 2 AI，4 回合
- 8 人 → 2 AI，6 回合
- 回合數 = 玩家數 - 2，所有 AI 被找出即真人勝（可提早結束）

技術棧：
- 後端：Node.js + TypeScript + Socket.io，在 backend/ 資料夾
- 前端：Flutter（iOS / Android / Web），在 flutter/ 資料夾
- 部署：Railway

程式碼規範：
- TypeScript 嚴格模式，型別明確
- Flutter 用 Riverpod
- 中文註解，說明「為什麼」
- 新功能要有測試
- git commit 用中文：「feat: 新增人數模式設定」

完成後：
1. 確認可編譯（tsc --noEmit 或 flutter analyze）
2. 執行測試
3. git add + commit
4. 在 docs/PROGRESS.md 追加記錄

現在的任務：
```

---

## 重要備註

- AI 身份在遊戲中完全隱藏，`isAI` 欄位不傳給前端，只在 `game_over` 揭露
- AI 模型：`claude-haiku-4-5`（便宜、快）
- **大廳只等真人**：4 人場等 3 人、6 人場等 4 人、8 人場等 6 人；AI 在開始時才補入
- **只有房主能按「開始遊戲」**，且須大廳滿員
- **兩階段身分**：大廳用自訂名稱社交；按開始後 shuffle + 匿名化成「玩家 N」，自訂名稱與編號無法對應
- AI 玩家的大廳名稱（補入時）與遊戲編號都與真人同格式，無法從名稱或編號分辨
- 配色在 shuffle 後依位置分配 `avatarIndex`（0–7），AI 也佔一個 index
- 前後端調色盤順序必須完全一致（藍粉綠橙紫紅青深橙）
- 訊息長度上限 200 字
- **主持人**為系統旁白（非玩家），用固定句型純文字（零 API 成本），以畫面中央橫幅顯示；在開場、聊天剩 30 秒、投票開始、投票剩 10 秒、結算、遊戲結束時觸發
- **排行榜勝率** = 猜中 AI 次數 / 總投票次數；每次真人投票後更新統計，至少投過 5 票才上榜
- 斷線處理：30 秒內重連視為同一玩家（保留 gameName 與 avatarIndex），超過則 Bot 補位
- Web / iOS / Android 共用同一 Socket.io 後端
- 房間代碼 4 碼純數字（0000–9999），方便口頭分享與快速輸入
