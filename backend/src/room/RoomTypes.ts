import { Player, Message, ModeConfig, GamePhase } from '../game/GameTypes'

export interface Room {
  code: string
  mode: ModeConfig
  players: Player[]
  round: number
  phase: GamePhase
  chatHistory: Message[]
  votes: Map<string, string>  // voterId → targetId
  aiPlayerIds: string[]
  chatTimer?: ReturnType<typeof setTimeout>
  voteTimer?: ReturnType<typeof setTimeout>
  resultTimer?: ReturnType<typeof setTimeout>
  timerInterval?: ReturnType<typeof setInterval>
}
