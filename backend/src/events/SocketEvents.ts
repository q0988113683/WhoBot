// 所有 Socket.io event 名稱常數，前後端共用格式
export const EVENTS = {
  // Client → Server
  CREATE_ROOM: 'create_room',
  JOIN_ROOM: 'join_room',
  QUICK_MATCH: 'quick_match',
  SEND_MESSAGE: 'send_message',
  CAST_VOTE: 'cast_vote',
  READY_NEXT_ROUND: 'ready_next_round',

  // Server → Client
  ROOM_CREATED: 'room_created',
  LOBBY_UPDATE: 'lobby_update',
  GAME_START: 'game_start',
  NEW_MESSAGE: 'new_message',
  VOTE_PHASE_START: 'vote_phase_start',
  VOTE_UPDATE: 'vote_update',
  ROUND_RESULT: 'round_result',
  GAME_OVER: 'game_over',
  TIMER_UPDATE: 'timer_update',
  ERROR: 'error',
} as const
