import { Server } from 'socket.io'
import { Room } from '../room/RoomTypes'
import { GameEndResult, Player } from './GameTypes'
import { CHAT_DURATION, VOTE_DURATION, RESULT_DURATION } from './GameConfig'
import { VoteManager } from './VoteManager'
import { EVENTS } from '../events/SocketEvents'
import { AIPlayer } from '../ai/AIPlayer'
import { HostMessages } from './HostMessages'

export class GameEngine {
  private io: Server
  private voteManager = new VoteManager()
  // aiPlayer 實例由 RoomManager 建立後注入
  aiPlayers: Map<string, AIPlayer> = new Map()

  constructor(io: Server) {
    this.io = io
  }

  startChat(room: Room): void {
    room.phase = 'chat'
    room.votes = new Map()
    let secondsLeft = CHAT_DURATION

    this.io.to(room.code).emit(EVENTS.TIMER_UPDATE, { phase: 'chat', secondsLeft })
    this.io.to(room.code).emit(EVENTS.HOST_MESSAGE, {
      text: room.round === 1
        ? HostMessages.gameStart(room.mode)
        : HostMessages.roundStart(room.round),
      kind: 'intro',
      emphasis: room.round === 1,
    })

    room.timerInterval = setInterval(() => {
      secondsLeft--
      this.io.to(room.code).emit(EVENTS.TIMER_UPDATE, { phase: 'chat', secondsLeft })
      if (secondsLeft === 30) {
        this.io.to(room.code).emit(EVENTS.HOST_MESSAGE, {
          text: HostMessages.chatTimeWarning(),
          kind: 'warning',
          emphasis: true,
        })
      }
      if (secondsLeft <= 0) {
        clearInterval(room.timerInterval)
        this.startVote(room)
      }
    }, 1000)

    // 讓所有 AI 玩家開始排程發訊
    for (const aiId of room.aiPlayerIds) {
      const ai = this.aiPlayers.get(aiId)
      if (!ai) continue
      ai.scheduleChatMessages(room.chatHistory, (content) => {
        const msg = {
          id: crypto.randomUUID(),
          senderId: ai.id,
          senderName: ai.name,
          senderGameName: ai.name,
          senderAvatarIndex: ai.avatarIndex,
          content,
          timestamp: Date.now(),
          round: room.round,
        }
        room.chatHistory.push(msg)
        this.io.to(room.code).emit(EVENTS.NEW_MESSAGE, msg)
      })
    }
  }

  startVote(room: Room): void {
    // 停止 AI 聊天排程
    for (const aiId of room.aiPlayerIds) {
      this.aiPlayers.get(aiId)?.stopChat()
    }

    room.phase = 'vote'
    let secondsLeft = VOTE_DURATION

    this.io.to(room.code).emit(EVENTS.VOTE_PHASE_START, {
      round: room.round,
      totalRounds: room.mode.totalRounds,
      timeLimit: VOTE_DURATION,
    })
    this.io.to(room.code).emit(EVENTS.HOST_MESSAGE, {
      text: HostMessages.voteStart(room.round, room.mode.totalRounds),
      kind: 'vote_start',
      emphasis: true,
    })
    this.io.to(room.code).emit(EVENTS.TIMER_UPDATE, { phase: 'vote', secondsLeft })

    // AI 投票
    for (const aiId of room.aiPlayerIds) {
      const ai = this.aiPlayers.get(aiId)
      if (!ai) continue
      const delay = Math.random() * 20000  // 0–20 秒內隨機投票
      setTimeout(async () => {
        if (room.phase !== 'vote') return
        const alivePlayers = room.players.filter(p => !p.isEliminated)
        const targetId = await ai.vote(room.chatHistory, alivePlayers, room.aiPlayerIds)
        if (targetId) {
          this.voteManager.castVote(room, aiId, targetId)
          this.io.to(room.code).emit(EVENTS.VOTE_UPDATE, {
            votes: this.voteManager.getVoteCounts(room),
          })
        }
      }, delay)
    }

    room.timerInterval = setInterval(() => {
      secondsLeft--
      this.io.to(room.code).emit(EVENTS.TIMER_UPDATE, { phase: 'vote', secondsLeft })
      if (secondsLeft === 10) {
        this.io.to(room.code).emit(EVENTS.HOST_MESSAGE, {
          text: HostMessages.voteTimeWarning(),
          kind: 'warning',
          emphasis: true,
        })
      }
      if (secondsLeft <= 0) {
        clearInterval(room.timerInterval)
        this.resolveVote(room)
      }
    }, 1000)
  }

  castVote(room: Room, voterId: string, targetId: string): void {
    if (room.phase !== 'vote') return
    this.voteManager.castVote(room, voterId, targetId)
    this.io.to(room.code).emit(EVENTS.VOTE_UPDATE, {
      votes: this.voteManager.getVoteCounts(room),
    })
  }

  private resolveVote(room: Room): void {
    clearInterval(room.timerInterval)
    room.phase = 'result'

    const eliminated = this.voteManager.tally(room)
    if (eliminated) {
      eliminated.isEliminated = true
    }

    const aliveAI = room.players.filter(
      p => !p.isEliminated && room.aiPlayerIds.includes(p.id)
    )

    this.io.to(room.code).emit(EVENTS.ROUND_RESULT, {
      eliminated: eliminated ?? null,
      wasAI: eliminated ? room.aiPlayerIds.includes(eliminated.id) : false,
      round: room.round,
      aiRemaining: aliveAI.length,
      aiTotal: room.mode.aiCount,
    })
    if (eliminated) {
      this.io.to(room.code).emit(EVENTS.HOST_MESSAGE, {
        text: HostMessages.roundResult(
          eliminated.name,
          room.aiPlayerIds.includes(eliminated.id),
          aliveAI.length
        ),
        kind: 'result',
        emphasis: true,
      })
    }

    setTimeout(() => this.checkGameEnd(room), RESULT_DURATION * 1000)
  }

  private checkGameEnd(room: Room): void {
    const result = this.evaluateEnd(room)
    if (result) {
      room.phase = 'ended'
      const revealedPlayers: Player[] = room.players.map(p => ({
        ...p,
        isAI: room.aiPlayerIds.includes(p.id),
      }))
      this.io.to(room.code).emit(EVENTS.GAME_OVER, {
        result: result.result,
        reason: result.reason,
        reveal: revealedPlayers,
      })
      this.io.to(room.code).emit(EVENTS.HOST_MESSAGE, {
        text: HostMessages.gameOver(result.result, result.reason),
        kind: 'game_over',
        emphasis: true,
      })
    } else {
      room.round++
      this.startChat(room)
    }
  }

  private evaluateEnd(room: Room): GameEndResult | null {
    const alive = room.players.filter(p => !p.isEliminated)
    const aliveAI = alive.filter(p => room.aiPlayerIds.includes(p.id))
    const aliveHumans = alive.filter(p => !room.aiPlayerIds.includes(p.id))

    if (aliveAI.length === 0) {
      return { result: 'humans_win', reason: 'all_ai_found' }
    }
    if (aliveHumans.length === 0) {
      return { result: 'ai_wins', reason: 'humans_eliminated' }
    }
    if (room.round >= room.mode.totalRounds) {
      return { result: 'ai_wins', reason: 'rounds_exhausted' }
    }
    return null
  }
}
