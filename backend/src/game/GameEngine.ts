import { randomUUID } from 'crypto'
import { Server } from 'socket.io'
import { Room } from '../room/RoomTypes'
import { GameEndResult, Player } from './GameTypes'
import { CHAT_DURATION, VOTE_DURATION, RESULT_DURATION } from './GameConfig'
import { VoteManager } from './VoteManager'
import { EVENTS } from '../events/SocketEvents'
import { AIPlayer } from '../ai/AIPlayer'
import { HostMessages } from './HostMessages'
import { evaluateWin } from './winCondition'
import { recordVotes, incrementGamesPlayed, saveGameSession } from '../db/queries'

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

    this.io.to(room.code).emit(EVENTS.TIMER_UPDATE, { phase: 'chat', secondsLeft, round: room.round })
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
          id: randomUUID(),
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
      text: HostMessages.voteStart(room.round, room.mode.totalRounds, room.mode.variant),
      kind: 'vote_start',
      emphasis: true,
    })
    this.io.to(room.code).emit(EVENTS.TIMER_UPDATE, { phase: 'vote', secondsLeft })

    // 找出人類模式：AI 不知道隊友，投票候選含所有人（傳空陣列）
    const teamIds = room.mode.variant === 'find_human' ? [] : room.aiPlayerIds

    // AI 投票
    for (const aiId of room.aiPlayerIds) {
      const ai = this.aiPlayers.get(aiId)
      if (!ai) continue
      const delay = Math.random() * 20000  // 0–20 秒內隨機投票
      setTimeout(async () => {
        if (room.phase !== 'vote') return
        const alivePlayers = room.players.filter(p => !p.isEliminated)
        const targetId = await ai.vote(room.chatHistory, alivePlayers, teamIds)
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

    const isFindHuman = room.mode.variant === 'find_human'

    // 記錄真人這回合的投票到排行榜（best-effort）。
    // 「猜中」= 投到被獵殺隊伍：找出AI→投到AI；找出人類→投到人類。
    const voteEntries = [...room.votes.entries()]
      .map(([voterId, targetId]) => {
        const voter = room.players.find(p => p.id === voterId)
        if (!voter?.userId) return null
        const targetIsAi = room.aiPlayerIds.includes(targetId)
        const correct = isFindHuman ? !targetIsAi : targetIsAi
        return { userId: voter.userId, targetIsAi: correct, round: room.round }
      })
      .filter((e): e is { userId: string; targetIsAi: boolean; round: number } => e !== null)
    void recordVotes(voteEntries)

    const eliminated = this.voteManager.tally(room)
    if (eliminated) {
      eliminated.isEliminated = true
    }

    const aliveAI = room.players.filter(
      p => !p.isEliminated && room.aiPlayerIds.includes(p.id)
    )
    const aliveHumans = room.players.filter(
      p => !p.isEliminated && !room.aiPlayerIds.includes(p.id)
    )
    const huntedRemaining = isFindHuman ? aliveHumans.length : aliveAI.length
    const eliminatedIsAi = eliminated ? room.aiPlayerIds.includes(eliminated.id) : false
    const eliminatedWasHunted = eliminated ? (isFindHuman ? !eliminatedIsAi : eliminatedIsAi) : false

    this.io.to(room.code).emit(EVENTS.ROUND_RESULT, {
      eliminated: eliminated ?? null,
      wasAI: eliminatedIsAi,
      round: room.round,
      aiRemaining: aliveAI.length,
      aiTotal: room.mode.aiCount,
      // 找出人類模式用：被淘汰者是否為「被獵殺隊伍」、被獵殺隊伍剩餘數
      variant: room.mode.variant,
      eliminatedWasHunted,
      huntedRemaining,
    })
    if (eliminated) {
      this.io.to(room.code).emit(EVENTS.HOST_MESSAGE, {
        text: HostMessages.roundResult(
          eliminated.name,
          eliminatedWasHunted,
          huntedRemaining,
          room.mode.variant
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
        text: HostMessages.gameOver(result.result, result.reason, room.mode.variant),
        kind: 'game_over',
        emphasis: true,
      })

      // 排行榜 / 對局統計（best-effort）
      const humanUserIds = room.players
        .filter(p => !room.aiPlayerIds.includes(p.id) && p.userId)
        .map(p => p.userId as string)
      void incrementGamesPlayed(humanUserIds)
      void saveGameSession({
        roomCode: room.code,
        mode: room.mode.playerCount,
        result: result.result,
        endReason: result.reason,
        roundsPlayed: room.round,
        playerCount: room.mode.playerCount,
      })
    } else {
      room.round++
      this.startChat(room)
    }
  }

  private evaluateEnd(room: Room): GameEndResult | null {
    const alive = room.players.filter(p => !p.isEliminated)
    return evaluateWin({
      variant: room.mode.variant,
      aliveAI: alive.filter(p => room.aiPlayerIds.includes(p.id)).length,
      aliveHumans: alive.filter(p => !room.aiPlayerIds.includes(p.id)).length,
      round: room.round,
      totalRounds: room.mode.totalRounds,
    })
  }
}
