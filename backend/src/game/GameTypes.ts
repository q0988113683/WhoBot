export interface ModeConfig {
  playerCount: 4 | 6 | 8
  humanCount: number
  aiCount: number
  totalRounds: number
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
export type EndReason = 'all_ai_found' | 'rounds_exhausted' | 'humans_eliminated'

export interface GameEndResult {
  result: GameResult
  reason: EndReason
}
