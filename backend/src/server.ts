import express from 'express'
import { randomUUID } from 'crypto'
import { createServer } from 'http'
import { Server } from 'socket.io'
import cors from 'cors'
import { RoomManager } from './room/RoomManager'
import { EVENTS } from './events/SocketEvents'
import { Room } from './room/RoomTypes'
import { GameVariant } from './game/GameTypes'
import { initDb } from './db/init'
import { upsertUser, getLeaderboard, getUserRank } from './db/queries'

const app = express()
app.use(cors({ origin: process.env.CORS_ORIGIN ?? '*' }))
app.use(express.json())

const httpServer = createServer(app)
const io = new Server(httpServer, {
  cors: { origin: '*' },
})

const roomManager = new RoomManager(io)

// socketId → 持久 userId（排行榜身份，來自 client 的 device_id）
const socketToUser = new Map<string, string>()

function emitLobbyUpdate(room: Room): void {
  const payload = {
    players: room.players.map(p => ({
      id: p.id,
      lobbyName: p.lobbyName,
      name: p.lobbyName,
      isHost: p.isHost,
    })),
    joined: room.players.length,
    humanCount: room.mode.humanCount,
    isFull: room.players.length >= room.mode.humanCount,
    mode: room.mode,
  }
  io.to(room.code).emit(EVENTS.LOBBY_UPDATE, payload)
  for (const player of room.players) {
    io.to(player.id).emit(EVENTS.LOBBY_READY, {
      canStart: player.isHost && room.players.length >= room.mode.humanCount,
    })
  }
}

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', time: new Date().toISOString() })
})

io.on('connection', (socket) => {
  console.log(`[Socket] 連線：${socket.id}`)

  // 身份識別：client 連線後送 device_id + 暱稱，用於排行榜統計
  socket.on(EVENTS.IDENTIFY, async ({ deviceId, nickname }: { deviceId?: string; nickname?: string }) => {
    if (!deviceId) return
    const userId = await upsertUser(deviceId, nickname ?? '玩家')
    if (userId) socketToUser.set(socket.id, userId)
  })

  // 建立房間
  socket.on(EVENTS.CREATE_ROOM, ({ name, nickname, mode, variant }: { name?: string; nickname?: string; mode: number; variant?: GameVariant }) => {
    const room = roomManager.createRoom(socket.id, name ?? nickname ?? '玩家', mode, variant ?? 'find_ai', socketToUser.get(socket.id))
    if (!room) {
      socket.emit(EVENTS.ERROR, { message: '無效的遊戲模式' })
      return
    }
    socket.join(room.code)
    socket.emit(EVENTS.ROOM_CREATED, { roomCode: room.code, mode: room.mode })
    emitLobbyUpdate(room)
  })

  // 用代碼加入房間
  socket.on(EVENTS.JOIN_ROOM, ({ name, nickname, roomCode }: { name?: string; nickname?: string; roomCode: string }) => {
    const room = roomManager.joinRoom(socket.id, name ?? nickname ?? '玩家', roomCode, socketToUser.get(socket.id))
    if (!room) {
      socket.emit(EVENTS.ERROR, { message: '房間不存在或已開始' })
      return
    }
    socket.join(room.code)
    emitLobbyUpdate(room)
  })

  // 快速配對
  socket.on(EVENTS.QUICK_MATCH, ({ name, nickname, mode, variant }: { name?: string; nickname?: string; mode: number; variant?: GameVariant }) => {
    const room = roomManager.quickMatch(socket.id, name ?? nickname ?? '玩家', mode, variant ?? 'find_ai', socketToUser.get(socket.id))
    if (!room) {
      socket.emit(EVENTS.ERROR, { message: '無效的遊戲模式' })
      return
    }
    socket.join(room.code)
    socket.emit(EVENTS.ROOM_CREATED, { roomCode: room.code, mode: room.mode })
    emitLobbyUpdate(room)
  })

  // 排行榜
  socket.on(EVENTS.GET_LEADERBOARD, async ({ limit }: { limit?: number } = {}) => {
    const entries = await getLeaderboard(limit ?? 50)
    const userId = socketToUser.get(socket.id)
    const myRank = userId ? await getUserRank(userId) : null
    socket.emit(EVENTS.LEADERBOARD_DATA, { entries, myRank })
  })

  socket.on(EVENTS.START_GAME, () => {
    const room = roomManager.getRoomBySocket(socket.id)
    if (!room) return
    const ok = roomManager.startGame(room, io, socket.id)
    if (!ok) {
      socket.emit(EVENTS.ERROR, { message: '尚未滿員，或只有房主可以開始遊戲' })
    }
  })

  // 發送聊天訊息
  socket.on(EVENTS.SEND_MESSAGE, ({ content }: { content: string }) => {
    const room = roomManager.getRoomBySocket(socket.id)
    if (!room || room.phase !== 'chat') return
    const player = room.players.find(p => p.id === socket.id)
    if (!player || player.isEliminated) return

    const safe = content.slice(0, 200)
    const msg = {
      id: randomUUID(),
      senderId: socket.id,
      senderName: player.name,
      senderGameName: player.gameName ?? player.name,
      senderAvatarIndex: player.avatarIndex,
      content: safe,
      timestamp: Date.now(),
      round: room.round,
    }
    room.chatHistory.push(msg)
    io.to(room.code).emit(EVENTS.NEW_MESSAGE, msg)
  })

  // 投票
  socket.on(EVENTS.CAST_VOTE, ({ targetId }: { targetId: string }) => {
    const room = roomManager.getRoomBySocket(socket.id)
    if (!room) return
    roomManager.getEngine().castVote(room, socket.id, targetId)
  })

  // 斷線處理
  socket.on('disconnect', () => {
    console.log(`[Socket] 斷線：${socket.id}`)
    socketToUser.delete(socket.id)
    roomManager.removePlayer(socket.id)
  })
})

const PORT = process.env.PORT ?? 3000
void initDb()
httpServer.listen(PORT, () => {
  console.log(`[Server] WhoBot 後端啟動 port ${PORT}`)
})
