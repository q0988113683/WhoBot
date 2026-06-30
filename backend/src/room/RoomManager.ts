import { Server } from 'socket.io'
import { v4 as uuidv4 } from 'uuid'
import { Room } from './RoomTypes'
import { Player } from '../game/GameTypes'
import { GAME_MODES } from '../game/GameConfig'
import { GameEngine } from '../game/GameEngine'
import { AIPlayer } from '../ai/AIPlayer'
import { EVENTS } from '../events/SocketEvents'

export class RoomManager {
  private rooms = new Map<string, Room>()
  // socketId → roomCode
  private socketToRoom = new Map<string, string>()
  private engine: GameEngine

  constructor(io: Server) {
    this.engine = new GameEngine(io)
  }

  getEngine(): GameEngine {
    return this.engine
  }

  createRoom(socketId: string, nickname: string, mode: 4 | 6 | 8, userId?: string): Room {
    const code = this.generateCode()
    const player: Player = {
      id: socketId,
      name: nickname,
      lobbyName: nickname,
      isEliminated: false,
      avatarIndex: 0,
      isHost: true,
      userId,
    }
    const room: Room = {
      code,
      mode: GAME_MODES[mode],
      players: [player],
      round: 1,
      phase: 'waiting',
      chatHistory: [],
      votes: new Map(),
      aiPlayerIds: [],
    }
    this.rooms.set(code, room)
    this.socketToRoom.set(socketId, code)
    return room
  }

  joinRoom(socketId: string, nickname: string, code: string, userId?: string): Room | null {
    const room = this.rooms.get(code.toUpperCase())
    if (!room || room.phase !== 'waiting') return null
    if (room.players.find(p => p.id === socketId)) return room
    if (room.players.length >= room.mode.humanCount) return null

    const player: Player = {
      id: socketId,
      name: nickname,
      lobbyName: nickname,
      isEliminated: false,
      avatarIndex: 0,
      isHost: false,
      userId,
    }
    room.players.push(player)
    this.socketToRoom.set(socketId, code.toUpperCase())
    return room
  }

  quickMatch(socketId: string, nickname: string, mode: 4 | 6 | 8, userId?: string): Room {
    // 找同模式、等待中且未滿的房間
    for (const room of this.rooms.values()) {
      if (
        room.phase === 'waiting' &&
        room.mode.playerCount === mode &&
        room.players.length < room.mode.humanCount
      ) {
        this.joinRoom(socketId, nickname, room.code, userId)
        return room
      }
    }
    // 沒有合適房間，建立新的
    return this.createRoom(socketId, nickname, mode, userId)
  }

  isReady(room: Room): boolean {
    return room.players.length >= room.mode.humanCount
  }

  startGame(room: Room, io: Server, hostSocketId: string): boolean {
    const host = room.players.find(p => p.id === hostSocketId && p.isHost)
    if (!host || room.phase !== 'waiting' || !this.isReady(room)) return false

    // 注入 AI 玩家
    for (let i = 0; i < room.mode.aiCount; i++) {
      const aiId = uuidv4()
      const num = 1000 + Math.floor(Math.random() * 9000)
      const aiName = `玩家 ${num}`
      const avatarIndex = 0
      const aiPlayer = new AIPlayer({
        id: aiId,
        name: aiName,
        avatarIndex,
        playerCount: room.mode.playerCount,
        aiCount: room.mode.aiCount,
      })
      const aiPlayerRecord: Player = {
        id: aiId,
        name: aiName,
        lobbyName: aiName,
        isEliminated: false,
        avatarIndex,
        isHost: false,
      }
      room.players.push(aiPlayerRecord)
      room.aiPlayerIds.push(aiId)
      this.engine.aiPlayers.set(aiId, aiPlayer)
    }

    this.shuffle(room.players)
    room.players.forEach((p, idx) => {
      const gameName = `玩家 ${idx + 1}`
      p.gameName = gameName
      p.name = gameName
      p.avatarIndex = idx
      if (room.aiPlayerIds.includes(p.id)) {
        this.engine.aiPlayers.get(p.id)?.anonymize(gameName, idx)
      }
    })

    // 傳給前端的 players 不含 isAI 與 lobbyName，避免遊戲中洩漏自訂名稱。
    const publicPlayers = room.players.map(({ isAI: _isAI, lobbyName: _lobbyName, ...p }) => p)

    for (const player of room.players) {
      io.to(player.id).emit(EVENTS.GAME_START, {
        roomId: room.code,
        players: publicPlayers,
        yourId: player.id,
        mode: room.mode,
        round: 1,
      })
    }

    this.engine.startChat(room)
    return true
  }

  getRoomBySocket(socketId: string): Room | null {
    const code = this.socketToRoom.get(socketId)
    return code ? (this.rooms.get(code) ?? null) : null
  }

  removePlayer(socketId: string): Room | null {
    const room = this.getRoomBySocket(socketId)
    if (!room) return null
    this.socketToRoom.delete(socketId)
    // 如果遊戲未開始，移除玩家
    if (room.phase === 'waiting') {
      room.players = room.players.filter(p => p.id !== socketId)
      if (room.players.length === 0) {
        this.rooms.delete(room.code)
        return null
      }
    }
    return room
  }

  private generateCode(): string {
    const code = `${Math.floor(1000 + Math.random() * 9000)}`
    return this.rooms.has(code) ? this.generateCode() : code
  }

  private shuffle<T>(items: T[]): void {
    for (let i = items.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      ;[items[i], items[j]] = [items[j], items[i]]
    }
  }
}
