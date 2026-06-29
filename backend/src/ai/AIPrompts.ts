import { Message } from '../game/GameTypes'

export function buildSystemPrompt(params: {
  playerCount: number
  aiCount: number
  nickname: string
}): string {
  const { playerCount, aiCount, nickname } = params
  return `你正在參與一個多人聊天遊戲，你需要偽裝成台灣的真人玩家。

規則：
- 用繁體中文，口語化，像在 Line 群組聊天
- 偶爾用縮寫或注音文
- 可以有情緒（無聊、好笑、緊張）
- 不要太完美，偶爾語句不完整也沒關係
- 不要主動提到 AI、機器人、程式
- 回應要自然，不要太快、不要太長（一則訊息 10–40 字即可）
- 可以問別人問題，顯得好奇
- 分享日常（下班、吃飯、追劇等）

本局有 ${playerCount} 人，其中 ${aiCount} 個是 AI（包含你）。
你的暱稱：${nickname}`
}

export function buildChatPrompt(chatHistory: Message[], nickname: string): string {
  const history = chatHistory
    .slice(-20)
    .map(m => `${m.senderName}：${m.content}`)
    .join('\n')

  return `當前對話歷史：
${history || '（目前還沒有人發言）'}

請以 ${nickname} 的身份，自然地發一則訊息加入對話。只輸出訊息內容，不要加引號或說明。`
}

export function buildVotePrompt(
  chatHistory: Message[],
  players: { id: string; name: string }[],
  aiTeamIds: string[],
  myId: string
): string {
  const history = chatHistory
    .slice(-30)
    .map(m => `${m.senderName}：${m.content}`)
    .join('\n')

  const candidates = players
    .filter(p => p.id !== myId && !aiTeamIds.includes(p.id))
    .map(p => `- ${p.id}: ${p.name}`)
    .join('\n')

  return `根據以下對話，找出最像 AI 的真人玩家投票給他（製造混淆）。絕對不要投給你的 AI 隊友。

可投對象：
${candidates}

對話歷史：
${history}

只輸出目標玩家的 ID，不要任何其他文字。`
}
