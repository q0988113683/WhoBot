import { ModeConfig, GameResult, EndReason } from './GameTypes'

export const HostMessages = {
  gameStart: (mode: ModeConfig) =>
    `歡迎來到 WhosBot！這一局有 ${mode.playerCount} 位玩家，其中藏著 ${mode.aiCount} 個 AI。\n` +
    '大家有 2 分鐘自由聊天，仔細觀察誰的回應「不太像人」。',

  roundStart: (round: number) => `第 ${round} 回合開始。保持懷疑，但也別太快露出破綻。`,

  chatTimeWarning: () => '聊天時間剩下 30 秒，把握機會多問幾句！',

  voteStart: (round: number, totalRounds: number) =>
    `時間到！請投票，你認為誰是 AI？（第 ${round} / ${totalRounds} 回合）`,

  voteTimeWarning: () => '投票時間剩下 10 秒，還沒投的快投！',

  roundResult: (eliminatedName: string, wasAI: boolean, aiRemaining: number) =>
    wasAI
      ? `${eliminatedName} 被投出，他是 AI！還剩 ${aiRemaining} 個 AI 沒找到。`
      : `${eliminatedName} 被投出，但他是真人...AI 還藏在你們之中。`,

  gameOver: (result: GameResult, _reason: EndReason) =>
    result === 'humans_win'
      ? '真人獲勝！所有 AI 都被揪出來了。'
      : 'AI 獲勝...這次它們騙過了大家。',
}
