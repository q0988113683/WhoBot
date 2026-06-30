export type GameVariant = 'find_ai' | 'find_human'

export interface ModeConfig {
  playerCount: number
  humanCount: number
  aiCount: number
  totalRounds: number
  variant: GameVariant
}

export interface Player {
  id: string
  name: string
  lobbyName: string
  gameName?: string
  isAI?: boolean        // 只在 game_over 時揭露
  isEliminated: boolean
  avatarIndex: number   // 進房順序決定，0–7
  isHost: boolean
  userId?: string       // 排行榜用的持久使用者 id（真人才有；對應 device_id）
}

export interface Message {
  id: string
  senderId: string
  senderName: string
  senderAvatarIndex: number
  content: string
  timestamp: number
  round: number
}

export type GamePhase = 'waiting' | 'chat' | 'vote' | 'result' | 'ended'

export type GameResult = 'humans_win' | 'ai_wins'
export type EndReason =
  | 'all_ai_found'        // 找出AI：AI 全被揪出（真人勝）
  | 'humans_eliminated'   // 找出AI：真人被淘汰光（AI 勝）
  | 'all_humans_found'    // 找出人類：人類全被投出（AI 勝）
  | 'all_ai_eliminated'   // 找出人類：AI 全被投出（真人勝）
  | 'rounds_exhausted'    // 回合用完（依玩法決定誰勝）

export interface GameEndResult {
  result: GameResult
  reason: EndReason
}
