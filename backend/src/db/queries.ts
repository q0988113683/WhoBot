import pool from './connection'
import { GameResult, EndReason } from '../game/GameTypes'

// 以 device_id 找到 / 建立使用者，回傳 userId。失敗回 null（不影響遊戲）。
export async function upsertUser(deviceId: string, nickname: string): Promise<string | null> {
  try {
    const res = await pool.query(
      `INSERT INTO users (device_id, nickname)
       VALUES ($1, $2)
       ON CONFLICT (device_id) DO UPDATE SET nickname = EXCLUDED.nickname
       RETURNING id`,
      [deviceId, nickname.slice(0, 20) || '玩家']
    )
    return (res.rows[0]?.id as string) ?? null
  } catch (err) {
    console.error('[DB] upsertUser:', (err as Error).message)
    return null
  }
}

// 記錄一回合內所有真人玩家的投票，並累加統計。best-effort。
export async function recordVotes(
  entries: { userId: string; targetIsAi: boolean; round: number }[]
): Promise<void> {
  if (entries.length === 0) return
  try {
    for (const e of entries) {
      await pool.query(
        `INSERT INTO votes (voter_id, target_is_ai, round) VALUES ($1, $2, $3)`,
        [e.userId, e.targetIsAi, e.round]
      )
      await pool.query(
        `UPDATE users
         SET total_votes = total_votes + 1,
             correct_votes = correct_votes + $2
         WHERE id = $1`,
        [e.userId, e.targetIsAi ? 1 : 0]
      )
    }
  } catch (err) {
    console.error('[DB] recordVotes:', (err as Error).message)
  }
}

export async function incrementGamesPlayed(userIds: string[]): Promise<void> {
  const ids = userIds.filter(Boolean)
  if (ids.length === 0) return
  try {
    await pool.query(
      `UPDATE users SET games_played = games_played + 1 WHERE id = ANY($1::uuid[])`,
      [ids]
    )
  } catch (err) {
    console.error('[DB] incrementGamesPlayed:', (err as Error).message)
  }
}

export interface LeaderboardEntry {
  rank: number
  nickname: string
  correctVotes: number
  totalVotes: number
  winRate: number
  gamesPlayed: number
}

const MIN_VOTES = 5

export async function getLeaderboard(limit = 50): Promise<LeaderboardEntry[]> {
  try {
    const res = await pool.query(
      `SELECT nickname, correct_votes, total_votes, games_played,
              ROUND(correct_votes::numeric / NULLIF(total_votes, 0) * 100, 1) AS win_rate
       FROM users
       WHERE total_votes >= $1
       ORDER BY win_rate DESC, total_votes DESC
       LIMIT $2`,
      [MIN_VOTES, limit]
    )
    return res.rows.map((r, i) => ({
      rank: i + 1,
      nickname: r.nickname as string,
      correctVotes: Number(r.correct_votes),
      totalVotes: Number(r.total_votes),
      winRate: Number(r.win_rate ?? 0),
      gamesPlayed: Number(r.games_played),
    }))
  } catch (err) {
    console.error('[DB] getLeaderboard:', (err as Error).message)
    return []
  }
}

// 取得某使用者在排行榜中的名次（未達門檻或失敗回 null）
export async function getUserRank(userId: string): Promise<number | null> {
  try {
    const res = await pool.query(
      `WITH ranked AS (
         SELECT id,
                ROW_NUMBER() OVER (
                  ORDER BY (correct_votes::numeric / NULLIF(total_votes, 0)) DESC, total_votes DESC
                ) AS rank
         FROM users
         WHERE total_votes >= $1
       )
       SELECT rank FROM ranked WHERE id = $2`,
      [MIN_VOTES, userId]
    )
    return res.rows[0] ? Number(res.rows[0].rank) : null
  } catch (err) {
    console.error('[DB] getUserRank:', (err as Error).message)
    return null
  }
}

export async function saveGameSession(params: {
  roomCode: string
  mode: number
  result: GameResult
  endReason: EndReason
  roundsPlayed: number
  playerCount: number
}): Promise<string | null> {
  try {
    const res = await pool.query(
      `INSERT INTO game_sessions (room_code, mode, result, end_reason, rounds_played, player_count, ended_at)
       VALUES ($1, $2, $3, $4, $5, $6, NOW())
       RETURNING id`,
      [params.roomCode, params.mode, params.result, params.endReason, params.roundsPlayed, params.playerCount]
    )
    return (res.rows[0]?.id as string) ?? null
  } catch (err) {
    console.error('[DB] saveGameSession:', (err as Error).message)
    return null
  }
}
