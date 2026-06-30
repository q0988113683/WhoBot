// 所有 Socket.io event 名稱常數，前後端共用格式
export const EVENTS = {
  // Client → Server
  IDENTIFY: 'identify',
  CREATE_ROOM: 'create_room',
  JOIN_ROOM: 'join_room',
  QUICK_MATCH: 'quick_match',
  START_GAME: 'start_game',
  SEND_MESSAGE: 'send_message',
  CAST_VOTE: 'cast_vote',
  READY_NEXT_ROUND: 'ready_next_round',
  GET_LEADERBOARD: 'get_leaderboard',

  // Server → Client
  LEADERBOARD_DATA: 'leaderboard_data',
  ROOM_CREATED: 'room_created',
  LOBBY_UPDATE: 'lobby_update',
  LOBBY_READY: 'lobby_ready',
  GAME_START: 'game_start',
  NEW_MESSAGE: 'new_message',
  VOTE_PHASE_START: 'vote_phase_start',
  VOTE_UPDATE: 'vote_update',
  ROUND_RESULT: 'round_result',
  GAME_OVER: 'game_over',
  TIMER_UPDATE: 'timer_update',
  HOST_MESSAGE: 'host_message',
  ERROR: 'error',
} as const
