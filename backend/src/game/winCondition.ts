import { GameVariant, GameEndResult } from './GameTypes'

/**
 * 純函式勝負判定。被獵殺隊伍（hunted）全滅 → 獵人勝；hunted 撐到回合用完 → hunted 勝。
 * - find_ai：hunted = AI
 * - find_human：hunted = 人類
 */
export function evaluateWin(params: {
  variant: GameVariant
  aliveAI: number
  aliveHumans: number
  round: number
  totalRounds: number
}): GameEndResult | null {
  const { variant, aliveAI, aliveHumans, round, totalRounds } = params

  if (variant === 'find_human') {
    if (aliveHumans === 0) return { result: 'ai_wins', reason: 'all_humans_found' }
    if (aliveAI === 0) return { result: 'humans_win', reason: 'all_ai_eliminated' }
    if (round >= totalRounds) return { result: 'humans_win', reason: 'rounds_exhausted' }
    return null
  }

  // find_ai
  if (aliveAI === 0) return { result: 'humans_win', reason: 'all_ai_found' }
  if (aliveHumans === 0) return { result: 'ai_wins', reason: 'humans_eliminated' }
  if (round >= totalRounds) return { result: 'ai_wins', reason: 'rounds_exhausted' }
  return null
}
