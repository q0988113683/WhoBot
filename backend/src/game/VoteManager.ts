import { Room } from '../room/RoomTypes'
import { Player } from './GameTypes'

export class VoteManager {
  // 記錄投票，每人只能投一票（覆蓋舊票）
  castVote(room: Room, voterId: string, targetId: string): void {
    const voter = room.players.find(p => p.id === voterId && !p.isEliminated)
    const target = room.players.find(p => p.id === targetId && !p.isEliminated)
    if (!voter || !target) return
    room.votes.set(voterId, targetId)
  }

  // 計票，取票數最多者淘汰；平票時隨機選一個
  tally(room: Room): Player | null {
    const counts = new Map<string, number>()
    for (const targetId of room.votes.values()) {
      counts.set(targetId, (counts.get(targetId) ?? 0) + 1)
    }
    if (counts.size === 0) return null

    let maxVotes = 0
    for (const count of counts.values()) {
      if (count > maxVotes) maxVotes = count
    }

    const topIds = [...counts.entries()]
      .filter(([, c]) => c === maxVotes)
      .map(([id]) => id)

    const winnerId = topIds[Math.floor(Math.random() * topIds.length)]
    const eliminated = room.players.find(p => p.id === winnerId)
    return eliminated ?? null
  }

  getVoteCounts(room: Room): Record<string, number> {
    const counts: Record<string, number> = {}
    for (const targetId of room.votes.values()) {
      counts[targetId] = (counts[targetId] ?? 0) + 1
    }
    return counts
  }
}
