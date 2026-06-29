import { GAME_MODES } from '../src/game/GameConfig'
import { Room } from '../src/room/RoomTypes'
import { Player } from '../src/game/GameTypes'
import { VoteManager } from '../src/game/VoteManager'

function makeRoom(mode: 4 | 6 | 8): Room {
  return {
    code: 'TEST01',
    mode: GAME_MODES[mode],
    players: [],
    round: 1,
    phase: 'waiting',
    chatHistory: [],
    votes: new Map(),
    aiPlayerIds: [],
  }
}

function makePlayer(id: string, isEliminated = false): Player {
  return { id, name: `玩家 ${id}`, isEliminated, avatarIndex: 0, isHost: false }
}

describe('GameConfig', () => {
  it('4人模式設定正確', () => {
    expect(GAME_MODES[4].aiCount).toBe(1)
    expect(GAME_MODES[4].totalRounds).toBe(2)
  })
  it('6人模式設定正確', () => {
    expect(GAME_MODES[6].aiCount).toBe(2)
    expect(GAME_MODES[6].totalRounds).toBe(4)
  })
  it('8人模式設定正確', () => {
    expect(GAME_MODES[8].aiCount).toBe(2)
    expect(GAME_MODES[8].totalRounds).toBe(6)
  })
})

describe('VoteManager', () => {
  const vm = new VoteManager()

  it('正確計票', () => {
    const room = makeRoom(4)
    room.players = [makePlayer('A'), makePlayer('B'), makePlayer('C')]
    vm.castVote(room, 'A', 'C')
    vm.castVote(room, 'B', 'C')
    const eliminated = vm.tally(room)
    expect(eliminated?.id).toBe('C')
  })

  it('平票時回傳其中一個', () => {
    const room = makeRoom(4)
    room.players = [makePlayer('A'), makePlayer('B'), makePlayer('C'), makePlayer('D')]
    vm.castVote(room, 'A', 'B')
    vm.castVote(room, 'C', 'D')
    const eliminated = vm.tally(room)
    expect(['B', 'D']).toContain(eliminated?.id)
  })

  it('被淘汰者無法投票', () => {
    const room = makeRoom(4)
    room.players = [makePlayer('A', true), makePlayer('B')]
    vm.castVote(room, 'A', 'B')
    expect(room.votes.size).toBe(0)
  })
})
