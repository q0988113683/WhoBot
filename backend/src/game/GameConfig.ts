import { ModeConfig } from './GameTypes'

export const GAME_MODES: Record<number, ModeConfig> = {
  4: { playerCount: 4, humanCount: 3, aiCount: 1, totalRounds: 2 },
  6: { playerCount: 6, humanCount: 4, aiCount: 2, totalRounds: 4 },
  8: { playerCount: 8, humanCount: 6, aiCount: 2, totalRounds: 6 },
}

export const CHAT_DURATION = 120  // 秒
export const VOTE_DURATION = 30
export const RESULT_DURATION = 5
