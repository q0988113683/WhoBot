import { ModeConfig, GameVariant } from './GameTypes'

// 找出 AI（原版）：真人多數、AI 少數，真人揪出 AI
export const GAME_MODES: Record<number, ModeConfig> = {
  4: { playerCount: 4, humanCount: 3, aiCount: 1, totalRounds: 2, variant: 'find_ai' },
  6: { playerCount: 6, humanCount: 4, aiCount: 2, totalRounds: 4, variant: 'find_ai' },
  8: { playerCount: 8, humanCount: 6, aiCount: 2, totalRounds: 6, variant: 'find_ai' },
}

// 找出人類（新版）：AI 多數、真人少數，大家一起揪出偽裝的真人
export const GAME_MODES_FIND_HUMAN: Record<number, ModeConfig> = {
  3: { playerCount: 3, humanCount: 1, aiCount: 2, totalRounds: 2, variant: 'find_human' },
  5: { playerCount: 5, humanCount: 2, aiCount: 3, totalRounds: 3, variant: 'find_human' },
}

// 依玩法與人數取得設定（找不到時回 null）
export function getMode(variant: GameVariant, count: number): ModeConfig | null {
  const table = variant === 'find_human' ? GAME_MODES_FIND_HUMAN : GAME_MODES
  return table[count] ?? null
}

export const CHAT_DURATION = 120  // 秒
export const VOTE_DURATION = 30
export const RESULT_DURATION = 5
