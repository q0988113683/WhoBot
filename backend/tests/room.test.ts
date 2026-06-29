import { GAME_MODES } from '../src/game/GameConfig'

describe('GAME_MODES 完整性', () => {
  const modes = [4, 6, 8] as const
  modes.forEach(mode => {
    it(`模式 ${mode}：humanCount + aiCount = playerCount`, () => {
      const m = GAME_MODES[mode]
      expect(m.humanCount + m.aiCount).toBe(m.playerCount)
    })
    it(`模式 ${mode}：totalRounds = playerCount - 2`, () => {
      const m = GAME_MODES[mode]
      expect(m.totalRounds).toBe(m.playerCount - 2)
    })
  })
})
