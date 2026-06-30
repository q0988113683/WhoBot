import { ModeConfig, GameResult, EndReason, GameVariant } from './GameTypes'

export const HostMessages = {
  gameStart: (mode: ModeConfig) =>
    mode.variant === 'find_human'
      ? `歡迎來到「找出人類」！這一局 ${mode.playerCount} 位玩家大多是 AI，` +
        `但藏了 ${mode.humanCount} 個假裝成 AI 的真人。\n大家有 2 分鐘聊天，揪出那個「太有人味」的玩家！`
      : `歡迎來到 WhosBot！這一局有 ${mode.playerCount} 位玩家，其中藏著 ${mode.aiCount} 個 AI。\n` +
        '大家有 2 分鐘自由聊天，仔細觀察誰的回應「不太像人」。',

  roundStart: (round: number) => `第 ${round} 回合開始。保持懷疑，但也別太快露出破綻。`,

  chatTimeWarning: () => '聊天時間剩下 30 秒，把握機會多問幾句！',

  voteStart: (round: number, totalRounds: number, variant: GameVariant = 'find_ai') =>
    `時間到！請投票，你認為誰是${variant === 'find_human' ? '人類' : 'AI'}？（第 ${round} / ${totalRounds} 回合）`,

  voteTimeWarning: () => '投票時間剩下 10 秒，還沒投的快投！',

  // eliminatedWasHunted：被淘汰者是否屬於「被獵殺隊伍」（find_ai=AI、find_human=人類）
  // huntedRemaining：被獵殺隊伍剩餘人數
  roundResult: (
    eliminatedName: string,
    eliminatedWasHunted: boolean,
    huntedRemaining: number,
    variant: GameVariant = 'find_ai'
  ) => {
    if (variant === 'find_human') {
      return eliminatedWasHunted
        ? `${eliminatedName} 被投出，他真的是人類！還剩 ${huntedRemaining} 個人類沒找到。`
        : `${eliminatedName} 被投出，但他是 AI...人類還躲在你們之中。`
    }
    return eliminatedWasHunted
      ? `${eliminatedName} 被投出，他是 AI！還剩 ${huntedRemaining} 個 AI 沒找到。`
      : `${eliminatedName} 被投出，但他是真人...AI 還藏在你們之中。`
  },

  gameOver: (result: GameResult, _reason: EndReason, variant: GameVariant = 'find_ai') => {
    if (variant === 'find_human') {
      return result === 'humans_win'
        ? '人類獲勝！成功騙過所有 AI、活到了最後。'
        : 'AI 獲勝！偽裝的人類全被揪出來了。'
    }
    return result === 'humans_win'
      ? '真人獲勝！所有 AI 都被揪出來了。'
      : 'AI 獲勝...這次它們騙過了大家。'
  },
}
