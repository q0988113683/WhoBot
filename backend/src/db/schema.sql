CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nickname VARCHAR(20) NOT NULL,
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

CREATE TABLE IF NOT EXISTS game_players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id),
  user_id UUID REFERENCES users(id),
  is_ai BOOLEAN DEFAULT FALSE,
  is_winner BOOLEAN,
  eliminated_round INT
);

CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES game_sessions(id),
  sender_id UUID,
  content TEXT NOT NULL,
  round INT,
  sent_at TIMESTAMPTZ DEFAULT NOW()
);
