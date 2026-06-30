import 'package:socket_io_client/socket_io_client.dart' as io;
import 'game_state.dart';
import 'constants.dart';

class SocketService {
  late io.Socket _socket;
  final GameState state;

  SocketService(this.state);

  void connect() {
    _socket = io.io(kServerUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket.onConnect((_) {
      state.mySocketId = _socket.id ?? '';
      // 連線後送出裝置身份，供排行榜統計
      if (state.deviceId.isNotEmpty) {
        _socket.emit('identify', {
          'deviceId': state.deviceId,
          'nickname': state.nickname,
        });
      }
    });

    _socket.on('leaderboard_data', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      final entries = (d['entries'] as List)
          .map((e) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      state.setLeaderboard(entries, d['myRank'] as int?);
    });

    _socket.on('lobby_update', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      state.lobbyPlayers = (d['players'] as List)
          .map((p) => PlayerModel.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
      state.mode = ModeConfig.fromJson(Map<String, dynamic>.from(d['mode'] as Map));
      state.lobbyJoined = d['joined'] as int? ?? state.lobbyPlayers.length;
      state.lobbyHumanCount =
          d['humanCount'] as int? ?? state.mode?.humanCount ?? state.lobbyPlayers.length;
      state.lobbyIsFull = d['isFull'] as bool? ??
          state.lobbyJoined >= (state.mode?.humanCount ?? state.lobbyPlayers.length);
      state.setScreen(GamePhase.lobby);
    });

    _socket.on('lobby_ready', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      state.canStartGame = d['canStart'] as bool? ?? false;
      state.lobbyIsFull = true;
      state.notify();
    });

    _socket.on('room_created', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      state.roomCode = d['roomCode'] as String;
      state.mode = ModeConfig.fromJson(Map<String, dynamic>.from(d['mode'] as Map));
      state.setScreen(GamePhase.lobby);
    });

    _socket.on('game_start', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      state.players = (d['players'] as List)
          .map((p) => PlayerModel.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
      state.mySocketId = d['yourId'] as String? ?? state.mySocketId;
      state.mode = ModeConfig.fromJson(Map<String, dynamic>.from(d['mode'] as Map));
      state.round = d['round'] as int;
      state.totalRounds = state.mode!.totalRounds;
      state.aiTotal = state.mode!.aiCount;
      state.aiRemaining = state.mode!.aiCount;
      state.messages = [];
      state.hostMessage = null;
      state.setScreen(GamePhase.chat);
    });

    _socket.on('new_message', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      state.messages = [...state.messages, MessageModel.fromJson(d)];
      state.notify();
    });

    _socket.on('host_message', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      state.hostMessage = HostMessageModel.fromJson(d);
      state.notify();
    });

    _socket.on('timer_update', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      final newPhase = d['phase'] as String;
      // 新一回合的聊天開始：後端只發 timer_update / host_message，
      // 因此在這裡負責把畫面從上一回合的結算切回聊天。
      if (newPhase == 'chat' && state.screen != GamePhase.chat) {
        state.messages = [];
        state.eliminatedPlayer = null;
        if (d['round'] != null) state.round = d['round'] as int;
        state.setScreen(GamePhase.chat);
      }
      state.phase = newPhase;
      state.secondsLeft = d['secondsLeft'] as int;
      state.notify();
    });

    _socket.on('vote_phase_start', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      state.round = d['round'] as int;
      state.totalRounds = d['totalRounds'] as int;
      state.voteCounts = {};
      state.myVoteTargetId = null;
      state.setScreen(GamePhase.vote);
    });

    _socket.on('vote_update', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      final raw = Map<String, dynamic>.from(d['votes'] as Map);
      state.voteCounts = raw.map((k, v) => MapEntry(k, v as int));
      state.notify();
    });

    _socket.on('round_result', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      if (d['eliminated'] != null) {
        final elim = PlayerModel.fromJson(
            Map<String, dynamic>.from(d['eliminated'] as Map));
        // 更新 players 淘汰狀態
        state.players = state.players.map((p) {
          if (p.id == elim.id) return p.copyWith(isEliminated: true);
          return p;
        }).toList();
        state.eliminatedPlayer = elim.copyWith(isEliminated: true);
      }
      state.wasAI = d['wasAI'] as bool;
      state.aiRemaining = d['aiRemaining'] as int;
      state.setScreen(GamePhase.result);
    });

    _socket.on('game_over', (data) {
      final d = Map<String, dynamic>.from(data as Map);
      state.gameResult = d['result'] as String;
      state.endReason = d['reason'] as String;
      state.revealPlayers = (d['reveal'] as List)
          .map((p) => PlayerModel.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
      state.setScreen(GamePhase.result);
    });

    _socket.on('error', (data) {
      try {
        final d = Map<String, dynamic>.from(data as Map);
        state.setError(d['message'] as String? ?? '發生錯誤，請再試一次');
      } catch (_) {
        state.setError('發生錯誤，請再試一次');
      }
    });
  }

  void createRoom(String nickname, int mode) {
    _socket.emit('create_room', {'name': nickname, 'nickname': nickname, 'mode': mode});
  }

  void joinRoom(String nickname, String roomCode) {
    _socket.emit('join_room', {'name': nickname, 'nickname': nickname, 'roomCode': roomCode});
  }

  void quickMatch(String nickname, int mode) {
    _socket.emit('quick_match', {'name': nickname, 'nickname': nickname, 'mode': mode});
  }

  void startGame() {
    _socket.emit('start_game');
  }

  void sendMessage(String content) {
    _socket.emit('send_message', {'content': content});
  }

  void castVote(String targetId) {
    _socket.emit('cast_vote', {'targetId': targetId});
  }

  void getLeaderboard({int limit = 50}) {
    _socket.emit('get_leaderboard', {'limit': limit});
  }

  void disconnect() {
    _socket.disconnect();
  }
}
