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

  createRoom(socketId: string, nickname: string, mode: 4 | 6 | 8): Room {
    const code = this.generateCode()
    const player: Player = {
      id: socketId,
      name: nickname,
      isEliminated: false,
      avatarIndex: 0,
      isHost: true,
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

  joinRoom(socketId: string, nickname: string, code: string): Room | null {
    const room = this.rooms.get(code.toUpperCase())
    if (!room || room.phase !== 'waiting') return null
    if (room.players.find(p => p.id === socketId)) return room

    const player: Player = {
      id: socketId,
      name: nickname,
      isEliminated: false,
      avatarIndex: room.players.length,  // 進房順序決定 avatarIndex
      isHost: false,
    }
    room.players.push(player)
    this.socketToRoom.set(socketId, code.toUpperCase())
    return room
  }

  quickMatch(socketId: string, nickname: string, mode: 4 | 6 | 8): Room {
    // 找同模式、等待中且未滿的房間
    for (const room of this.rooms.values()) {
      if (
        room.phase === 'waiting' &&
        room.mode.playerCount === mode &&
        room.players.length < room.mode.playerCount
      ) {
        this.joinRoom(socketId, nickname, room.code)
        return room
      }
    }
    // 沒有合適房間，建立新的
    return this.createRoom(socketId, nickname, mode)
  }

  // 判斷房間是否人滿可開始
  checkAndStart(room: Room, io: Server): void {
    if (room.players.length < room.mode.playerCount) return
    this.startGame(room, io)
  }

  private startGame(room: Room, io: Server): void {
    // 注入 AI 玩家
    for (let i = 0; i < room.mode.aiCount; i++) {
      const aiId = uuidv4()
      const num = 1000 + Math.floor(Math.random() * 9000)
      const aiName = `玩家 ${num}`
      const avatarIndex = room.players.length  // AI 也佔一個 index
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
        isEliminated: false,
        avatarIndex,
        isHost: false,
      }
      room.players.push(aiPlayerRecord)
      room.aiPlayerIds.push(aiId)
      this.engine.aiPlayers.set(aiId, aiPlayer)
    }

    // 傳給前端的 players 不含 isAI
    const publicPlayers = room.players.map(({ isAI: _isAI, ...p }) => p)

    io.to(room.code).emit(EVENTS.GAME_START, {
      roomId: room.code,
      players: publicPlayers,
      mode: room.mode,
      round: 1,
    })

    this.engine.startChat(room)
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
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    let code = ''
    for (let i = 0; i < 6; i++) {
      code += chars[Math.floor(Math.random() * chars.length)]
    }
    return this.rooms.has(code) ? this.generateCode() : code
  }
}
