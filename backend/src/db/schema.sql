-- 實際執行的 schema 由 src/db/init.ts 在啟動時冪等套用，此檔為對照文件。

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id VARCHAR(64) UNIQUE,     -- 持久身份（前端 localStorage 產生）
  nickname VARCHAR(20) NOT NULL,
  total_votes INT DEFAULT 0,        -- 總投票次數
  correct_votes INT DEFAULT 0,      -- 投中 AI 的次數
  games_played INT DEFAULT 0,       -- 總對局數
  created_at TIMESTAMPTZ DEFAULT NOW()
);
-- 勝率 = correct_votes / total_votes（查詢時計算）

CREATE TABLE IF NOT EXISTS game_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_code VARCHAR(10) NOT NULL,
  mode INT NOT NULL,
  result VARCHAR(20),
  end_reason VARCHAR(30),
  rounds_played INT,
  player_count INT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  ended_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID,
  round INT,
  voter_id UUID REFERENCES users(id),
  target_is_ai BOOLEAN NOT NULL,
  voted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID,
  sender_id UUID,
  content TEXT NOT NULL,
  round INT,
  sent_at TIMESTAMPTZ DEFAULT NOW()
);
