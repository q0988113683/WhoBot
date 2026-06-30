import { GAME_MODES, GAME_MODES_FIND_HUMAN, getMode } from '../src/game/GameConfig'
import { Room } from '../src/room/RoomTypes'
import { Player } from '../src/game/GameTypes'
import { VoteManager } from '../src/game/VoteManager'
import { evaluateWin } from '../src/game/winCondition'

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
  return {
    id,
    name: `玩家 ${id}`,
    lobbyName: `測試玩家 ${id}`,
    isEliminated,
    avatarIndex: 0,
    isHost: false,
  }
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

describe('找出人類模式設定', () => {
  it('3 人場 = 1 真人 + 2 AI', () => {
    expect(GAME_MODES_FIND_HUMAN[3].humanCount).toBe(1)
    expect(GAME_MODES_FIND_HUMAN[3].aiCount).toBe(2)
    expect(GAME_MODES_FIND_HUMAN[3].variant).toBe('find_human')
  })
  it('5 人場 = 2 真人 + 3 AI', () => {
    expect(GAME_MODES_FIND_HUMAN[5].humanCount).toBe(2)
    expect(GAME_MODES_FIND_HUMAN[5].aiCount).toBe(3)
  })
  it('3 人場只有 1 回合', () => {
    expect(GAME_MODES_FIND_HUMAN[3].totalRounds).toBe(1)
  })
  it('getMode 依玩法取設定', () => {
    expect(getMode('find_ai', 6)).toBe(GAME_MODES[6])
    expect(getMode('find_human', 3)).toBe(GAME_MODES_FIND_HUMAN[3])
    expect(getMode('find_human', 4)).toBeNull()
  })
})

describe('勝負判定 evaluateWin', () => {
  it('找出AI：AI 全滅 → 真人勝', () => {
    expect(evaluateWin({ variant: 'find_ai', aliveAI: 0, aliveHumans: 3, round: 1, totalRounds: 4 }))
      .toEqual({ result: 'humans_win', reason: 'all_ai_found' })
  })
  it('找出AI：回合用完 → AI 勝', () => {
    expect(evaluateWin({ variant: 'find_ai', aliveAI: 1, aliveHumans: 3, round: 4, totalRounds: 4 }))
      .toEqual({ result: 'ai_wins', reason: 'rounds_exhausted' })
  })

  it('找出人類：人類全被投出 → AI 勝', () => {
    expect(evaluateWin({ variant: 'find_human', aliveAI: 2, aliveHumans: 0, round: 1, totalRounds: 2 }))
      .toEqual({ result: 'ai_wins', reason: 'all_humans_found' })
  })
  it('找出人類：回合用完人類存活 → 人類勝', () => {
    expect(evaluateWin({ variant: 'find_human', aliveAI: 1, aliveHumans: 1, round: 2, totalRounds: 2 }))
      .toEqual({ result: 'humans_win', reason: 'rounds_exhausted' })
  })
  it('找出人類：AI 全被投出 → 人類勝', () => {
    expect(evaluateWin({ variant: 'find_human', aliveAI: 0, aliveHumans: 1, round: 1, totalRounds: 2 }))
      .toEqual({ result: 'humans_win', reason: 'all_ai_eliminated' })
  })
  it('找出人類：未結束回傳 null', () => {
    expect(evaluateWin({ variant: 'find_human', aliveAI: 2, aliveHumans: 1, round: 1, totalRounds: 2 }))
      .toBeNull()
  })

  // 3 人場單回合
  it('找出人類 3人場：R1 抓到人類 → AI 勝', () => {
    expect(evaluateWin({ variant: 'find_human', aliveAI: 2, aliveHumans: 0, round: 1, totalRounds: 1 }))
      .toEqual({ result: 'ai_wins', reason: 'all_humans_found' })
  })
  it('找出人類 3人場：R1 投到 AI、人類存活 → 人類勝', () => {
    expect(evaluateWin({ variant: 'find_human', aliveAI: 1, aliveHumans: 1, round: 1, totalRounds: 1 }))
      .toEqual({ result: 'humans_win', reason: 'rounds_exhausted' })
  })
})
