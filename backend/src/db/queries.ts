import pool from './connection'
import { GameResult, EndReason } from '../game/GameTypes'

export async function saveGameSession(params: {
  roomCode: string
  mode: number
  result: GameResult
  endReason: EndReason
  roundsPlayed: number
  playerCount: number
}): Promise<string> {
  const res = await pool.query(
    `INSERT INTO game_sessions (room_code, mode, result, end_reason, rounds_played, player_count, ended_at)
     VALUES ($1, $2, $3, $4, $5, $6, NOW())
     RETURNING id`,
    [params.roomCode, params.mode, params.result, params.endReason, params.roundsPlayed, params.playerCount]
  )
  return res.rows[0].id as string
}

export async function saveMessage(params: {
  sessionId: string
  senderId: string
  content: string
  round: number
}): Promise<void> {
  await pool.query(
    `INSERT INTO messages (session_id, sender_id, content, round) VALUES ($1, $2, $3, $4)`,
    [params.sessionId, params.senderId, params.content, params.round]
  )
}
