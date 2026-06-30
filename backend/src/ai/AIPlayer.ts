import Anthropic from '@anthropic-ai/sdk'
import { Message, Player } from '../game/GameTypes'
import { buildSystemPrompt, buildChatPrompt, buildVotePrompt, AI_PERSONAS } from './AIPrompts'

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY })

export class AIPlayer {
  readonly id: string
  name: string
  avatarIndex: number
  private systemPrompt: string
  private chatSchedule?: ReturnType<typeof setTimeout>

  constructor(params: {
    id: string
    name: string
    avatarIndex: number
    playerCount: number
    aiCount: number
  }) {
    this.id = params.id
    this.name = params.name
    this.avatarIndex = params.avatarIndex
    this.systemPrompt = buildSystemPrompt({
      playerCount: params.playerCount,
      aiCount: params.aiCount,
      nickname: params.name,
      persona: AI_PERSONAS[Math.floor(Math.random() * AI_PERSONAS.length)],
    })
  }

  anonymize(name: string, avatarIndex: number): void {
    this.name = name
    this.avatarIndex = avatarIndex
  }

  // 排程在回合聊天期間隨機發 3–6 則訊息
  scheduleChatMessages(
    chatHistory: Message[],
    onSend: (content: string) => void
  ): void {
    const count = 3 + Math.floor(Math.random() * 4)  // 3–6
    let sent = 0

    const sendNext = () => {
      if (sent >= count) return
      const delay = (15 + Math.random() * 30) * 1000  // 15–45 秒
      this.chatSchedule = setTimeout(async () => {
        const content = await this.generateMessage(chatHistory)
        if (content) {
          onSend(content)
          sent++
        }
        sendNext()
      }, delay)
    }

    sendNext()
  }

  stopChat(): void {
    if (this.chatSchedule) {
      clearTimeout(this.chatSchedule)
      this.chatSchedule = undefined
    }
  }

  async generateMessage(chatHistory: Message[]): Promise<string | null> {
    try {
      const res = await client.messages.create({
        model: 'claude-haiku-4-5',
        max_tokens: 100,
        system: this.systemPrompt,
        messages: [
          { role: 'user', content: buildChatPrompt(chatHistory, this.name) }
        ],
      })
      const block = res.content[0]
      return block.type === 'text' ? block.text.trim().slice(0, 200) : null
    } catch (err) {
      console.error('[AIPlayer] generateMessage error:', err)
      return null
    }
  }

  async vote(
    chatHistory: Message[],
    players: Player[],
    aiTeamIds: string[]
  ): Promise<string | null> {
    const candidates = players.filter(
      p => !p.isEliminated && p.id !== this.id && !aiTeamIds.includes(p.id)
    )
    if (candidates.length === 0) return null

    try {
      const res = await client.messages.create({
        model: 'claude-haiku-4-5',
        max_tokens: 50,
        system: this.systemPrompt,
        messages: [
          {
            role: 'user',
            content: buildVotePrompt(chatHistory, candidates, aiTeamIds, this.id),
          },
        ],
      })
      const block = res.content[0]
      if (block.type !== 'text') return candidates[0].id

      const raw = block.text.trim()
      const match = candidates.find(c => c.id === raw)
      return match ? match.id : candidates[Math.floor(Math.random() * candidates.length)].id
    } catch (err) {
      console.error('[AIPlayer] vote error:', err)
      return candidates[Math.floor(Math.random() * candidates.length)].id
    }
  }
}
