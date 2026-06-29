# WhoBot — 完整專案規格
> 貼給 Claude Code 的開發指令文件
> 最後更新：2026-06-30（v2：隨機暱稱、配色規則、訊息頭像）

---

## 專案概述

**WhoBot** 是一個多人即時推理遊戲。玩家進入聊天室一起聊天，真人玩家要透過對話找出混入其中的 AI。每回合結束後投票淘汰一人。**只要所有 AI 都被找出，真人就獲勝。**

遊戲支援三種人數模式，房主可選擇：

| 模式 | 真人 | AI | 回合數 | 估計時長 |
|------|------|-----|--------|---------|
| 4 人 | 3 | 1 | 2 | ~6 分 |
| 6 人 | 4 | 2 | 4 | ~12 分 |
| 8 人 | 6 | 2 | 6 | ~18 分 |

**規則公式：**
- AI 數量：4 人 → 1，6 人 → 2，8 人 → 2
- 回合數 = 玩家總數 − 2
- **提早結束**：若所有 AI 在回合用完前就被找出，立即真人勝利

---

## 玩家身分與配色（重要）

### 隨機暱稱
- 玩家**不需要輸入暱稱**。進入 App 時自動產生格式為「玩家 NNNN」的暱稱（NNNN 是 1000–9999 的隨機四位數）
- 首頁顯示暱稱與「換一個」按鈕，可重新隨機產生
- 首頁**不顯示**任何頭像或顏色（顏色在進房後才分配）
- 暱稱在 client 端產生即可，加入房間時一併送給後端

### 進房順序配色
- 玩家的專屬顏色**依進房順序分配**：第 1 個進房拿第 0 號色，第 2 個拿第 1 號色，依此類推
- 後端在玩家加入房間時，將 `avatarIndex`（0–7）依當前房間人數賦值
- 同一局內顏色**絕對不重複**（最多 8 人，剛好對應 8 色）
- 前端用 `avatarIndex` 對應到調色盤取色

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
- 頭像是一個**實心圓**，背景為玩家專屬色，圓內顯示暱稱數字的**第一位**（如「玩家 4271」顯示「4」，自己顯示「你」）
- 同一個玩家在所有畫面（頭像列、聊天訊息、投票卡、結算）使用**同一個顏色**，方便辨識
- 聊天室**每則訊息**前面都要顯示發話者的頭像（自己的訊息頭像在右側，他人在左側）

### 型別補充
```typescript
// Player 加上 avatarIndex（已在型別定義中）
interface Player {
  id: string
  name: string          // 「玩家 4271」
  avatarIndex: number   // 0-7，進房順序決定，對應調色盤
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
whobot/
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
│   │   │   ├── VoteManager.ts      # 投票收集、計票、淘汰
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
│   │   │   ├── home_screen.dart          # 首頁（輸入暱稱）
│   │   │   ├── mode_select_screen.dart   # 選擇人數模式（4/6/8）
│   │   │   ├── lobby_screen.dart         # 等待房間
│   │   │   ├── chat_screen.dart          # 聊天室（主畫面）
│   │   │   ├── vote_screen.dart          # 投票畫面
│   │   │   └── result_screen.dart        # 結算畫面
│   │   ├── widgets/
│   │   │   ├── message_bubble.dart       # 訊息泡泡
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
  playerCount: 4 | 6 | 8
  humanCount: number
  aiCount: number
  totalRounds: number
}

const GAME_MODES: Record<number, ModeConfig> = {
  4: { playerCount: 4, humanCount: 3, aiCount: 1, totalRounds: 2 },
  6: { playerCount: 6, humanCount: 4, aiCount: 2, totalRounds: 4 },
  8: { playerCount: 8, humanCount: 6, aiCount: 2, totalRounds: 6 },
}

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
// 建立房間（房主選擇人數模式）
socket.emit('create_room', { nickname: string, mode: 4 | 6 | 8 })

// 用房間代碼加入
socket.emit('join_room', { nickname: string, roomCode: string })

// 快速配對（系統自動找同模式房間）
socket.emit('quick_match', { nickname: string, mode: 4 | 6 | 8 })

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

// 房間人數更新（等待中）
socket.emit('lobby_update', {
  players: { id: string, name: string, avatarIndex: number }[],  // avatarIndex 依進房順序
  needed: number,      // 還差幾人
  mode: ModeConfig
})

// 配對成功，遊戲開始
socket.emit('game_start', {
  roomId: string,
  players: Player[],   // 含 avatarIndex，不含 isAI 欄位
  mode: ModeConfig,
  round: 1
})

// 新訊息廣播
socket.emit('new_message', {
  senderId: string,
  senderName: string,
  senderAvatarIndex: number,  // 前端用來顯示訊息頭像顏色
  content: string,
  timestamp: number
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

// 遊戲結束
socket.emit('game_over', {
  result: 'humans_win' | 'ai_wins',
  reason: 'all_ai_found' | 'rounds_exhausted' | 'humans_eliminated',
  reveal: Player[]     // 含 isAI 的完整資料
})

// 計時器同步
socket.emit('timer_update', {
  phase: 'chat' | 'vote',
  secondsLeft: number
})
```

### 型別定義
```typescript
interface Player {
  id: string
  name: string
  isAI?: boolean        // 只在 game_over 時揭露
  isEliminated: boolean
  avatarIndex: number   // 對應頭像顏色
  isHost: boolean       // 房主標記
}

interface Room {
  code: string          // 6 碼房間代碼
  mode: ModeConfig
  players: Player[]
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
waiting（等待達到 mode.playerCount 人）
  → chat（聊天 120 秒）
    → vote（投票 30 秒）
      → round_result（顯示結果 5 秒）
        → 檢查勝負條件
          → [所有 AI 已被淘汰] ended（真人勝 - all_ai_found）
          → [真人全被淘汰] ended（AI 勝 - humans_eliminated）
          → [回合用完] ended（AI 勝 - rounds_exhausted）
          → [否則] chat（下一回合）
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
你的暱稱：{nickname}
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
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE game_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_code VARCHAR(10) NOT NULL,
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

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id),
  sender_id UUID,
  content TEXT NOT NULL,
  round INT,
  sent_at TIMESTAMPTZ DEFAULT NOW()
);
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
- **不需要輸入暱稱**，自動產生「玩家 NNNN」隨機暱稱
- 顯示暱稱 + 「換一個」按鈕（重新隨機）
- 不顯示頭像顏色圈圈（顏色進房後才分配）
- 兩個按鈕：「建立房間」「輸入代碼加入」

#### ModeSelectScreen（新增）
- 三張卡片：4 人 / 6 人 / 8 人
- 每張顯示：真人數、AI 數、回合數、估計時長
- 用綠/紅圓點直觀顯示真人與 AI 比例
- 6 人卡標示「推薦」
- 選擇後 →「建立房間」會拿到房間代碼可分享，或「快速配對」

#### LobbyScreen
- 顯示「已加入 N / 總數 人...」
- 房間代碼（可複製分享）
- 玩家格子（grid）：**進房後才顯示專屬顏色頭像**，頭像圓內為暱稱數字第一位
- 自己的格子標示「你」
- 空位顯示虛線框 + 等待圖示
- 底部說明配色規則（進房順序決定顏色）
- 人數到齊自動進入 ChatScreen

#### ChatScreen（主畫面）
- 頂部：計時器 pill（剩 < 20 秒變紅）+ 回合標示（如「回合 1 / 4」）
- 頭像列：依模式顯示 4/6/8 個專屬色頭像，淘汰者變灰
- 訊息區：
  - **每則訊息前面都有發話者的專屬色頭像**（圓內為暱稱數字第一位）
  - 自己的訊息：頭像在右側，泡泡紫色靠右
  - 他人的訊息：頭像在左側，泡泡深色靠左
  - 泡泡上方顯示暱稱
- 底部：輸入框 + 送出按鈕

#### VoteScreen
- 標題「誰是 AI？」+ 剩餘 AI 提示（如「還有 2 個 AI 未找出」）
- 玩家卡片：專屬色頭像、暱稱、懷疑度條、得票數、淘汰 badge
- 點選投票 + 確認按鈕
- 30 秒倒數，到時自動送出

#### ResultScreen
- 結果 banner（含結束原因：提早找出 / 回合用盡）
- 玩家揭露：每人顯示其專屬色頭像；AI 標「Claude AI」（紅框），真人標「真人玩家」（綠框）
- 「找到了 / 誤判」badge
- 「再玩一局」按鈕

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
  defaultValue: 'wss://whobot.railway.app',
);
```

---

## 開發優先順序

### Phase 1 — 基礎建設（手動完成）
1. 建立 GitHub repo（monorepo）
2. 設定 Railway 專案，綁定 GitHub
3. Railway 建立 PostgreSQL
4. 建立 Flutter 專案（`flutter create whobot --platforms ios,android,web`）
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
你是 WhoBot 專案的 RD AI。

WhoBot 是多人即時推理遊戲（找出聊天室裡的 AI），支援 4/6/8 人模式：
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
- **暱稱由 client 端隨機產生**（「玩家 NNNN」），不需要登入或輸入
- **AI 玩家的暱稱也用同一套格式**隨機產生，與真人無法從暱稱區分
- **配色依進房順序**，後端在 `join_room` / `quick_match` 時賦值 `avatarIndex`（0–7），AI 玩家也佔一個 index
- 前後端調色盤順序必須完全一致（藍粉綠橙紫紅青深橙）
- 訊息長度上限 200 字
- 斷線處理：30 秒內重連視為同一玩家（保留 avatarIndex），超過則 Bot 補位
- Web / iOS / Android 共用同一 Socket.io 後端
- 房間代碼 6 碼英數字，方便口頭分享
