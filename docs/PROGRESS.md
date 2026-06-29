# WhoBot 開發進度

## 2026-06-30

### Phase 2 — 後端核心 ✅
- Node.js + TypeScript + Socket.io 骨架
- GameConfig（三種人數模式設定：4/6/8 人）
- RoomManager（建房、房間代碼、快速配對）
- Room 狀態機（waiting → chat → vote → result → ended）
- GameEngine（計時器、回合推進、提早結束判定）
- VoteManager（收票、計票、平票隨機、淘汰）
- 勝負判定（all_ai_found / rounds_exhausted / humans_eliminated）
- PostgreSQL schema + queries
- 後端測試 12 項全通過（tsc --noEmit ✅）

### Phase 3 — AI 玩家 ✅
- AIPlayer 類別（接 claude-haiku-4-5 API）
- 發訊排程（每回合 3–6 則，間隔 15–45 秒）
- AI 投票行為（不投隊友）
- System prompt（台灣口語繁中偽裝）

### Phase 4 — Flutter 前端 ✅
- SocketService（所有 event 處理）
- GameState（Provider ChangeNotifier）
- HomeScreen（自動暱稱「玩家 NNNN」+ 換一個）
- ModeSelectScreen（4/6/8 人，推薦 6 人）
- LobbyScreen（房間代碼複製、玩家格子、進房配色）
- ChatScreen（計時器、頭像列、訊息泡泡、輸入框）
- VoteScreen（懷疑度條、即時票數、確認投票）
- ResultScreen（每回合結算 + 遊戲結束揭露）
- Flutter analyze 無錯誤，測試 2 項全通過

## 待辦
- [ ] Phase 5：Railway 部署、TestFlight、Web 部署
- [ ] 斷線重連（30 秒內視為同一玩家）
- [ ] 遊戲內 snackbar 錯誤提示
