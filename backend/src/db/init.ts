import pool from './connection'

// 啟動時執行，建立 / 補齊資料表（冪等）。DB 不可用時不應讓伺服器崩潰。
const SCHEMA_SQL = `
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id VARCHAR(64) UNIQUE,
  nickname VARCHAR(20) NOT NULL,
  total_votes INT DEFAULT 0,
  correct_votes INT DEFAULT 0,
  games_played INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

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
`

// 針對既有資料庫補欄位（若先前已建過舊版 users 表）
const MIGRATIONS_SQL = `
ALTER TABLE users ADD COLUMN IF NOT EXISTS device_id VARCHAR(64);
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_votes INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS correct_votes INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS games_played INT DEFAULT 0;
CREATE UNIQUE INDEX IF NOT EXISTS users_device_id_idx ON users (device_id);
`

export async function initDb(): Promise<void> {
  try {
    await pool.query(SCHEMA_SQL)
    await pool.query(MIGRATIONS_SQL)
    console.log('[DB] schema ready')
  } catch (err) {
    console.error('[DB] init failed（排行榜功能將停用，遊戲仍可進行）:', (err as Error).message)
  }
}
