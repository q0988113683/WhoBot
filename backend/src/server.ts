import express from 'express'
import { createServer } from 'http'
import { Server } from 'socket.io'
import cors from 'cors'
import { RoomManager } from './room/RoomManager'
import { EVENTS } from './events/SocketEvents'
import { Room } from './room/RoomTypes'

const app = express()
app.use(cors({ origin: process.env.CORS_ORIGIN ?? '*' }))
app.use(express.json())

const httpServer = createServer(app)
const io = new Server(httpServer, {
  cors: { origin: '*' },
})

const roomManager = new RoomManager(io)

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

  // 建立房間
  socket.on(EVENTS.CREATE_ROOM, ({ name, nickname, mode }: { name?: string; nickname?: string; mode: 4 | 6 | 8 }) => {
    const room = roomManager.createRoom(socket.id, name ?? nickname ?? '玩家', mode)
    socket.join(room.code)
    socket.emit(EVENTS.ROOM_CREATED, { roomCode: room.code, mode: room.mode })
    emitLobbyUpdate(room)
  })

  // 用代碼加入房間
  socket.on(EVENTS.JOIN_ROOM, ({ name, nickname, roomCode }: { name?: string; nickname?: string; roomCode: string }) => {
    const room = roomManager.joinRoom(socket.id, name ?? nickname ?? '玩家', roomCode)
    if (!room) {
      socket.emit(EVENTS.ERROR, { message: '房間不存在或已開始' })
      return
    }
    socket.join(room.code)
    emitLobbyUpdate(room)
  })

  // 快速配對
  socket.on(EVENTS.QUICK_MATCH, ({ name, nickname, mode }: { name?: string; nickname?: string; mode: 4 | 6 | 8 }) => {
    const room = roomManager.quickMatch(socket.id, name ?? nickname ?? '玩家', mode)
    socket.join(room.code)
    emitLobbyUpdate(room)
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
      id: crypto.randomUUID(),
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
    roomManager.removePlayer(socket.id)
  })
})

const PORT = process.env.PORT ?? 3000
httpServer.listen(PORT, () => {
  console.log(`[Server] WhoBot 後端啟動 port ${PORT}`)
})
