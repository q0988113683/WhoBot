import 'package:flutter/foundation.dart';

class PlayerModel {
  final String id;
  final String name;
  final int avatarIndex;
  final bool isEliminated;
  final bool isHost;
  final bool? isAI; // 只在 game_over 揭露

  const PlayerModel({
    required this.id,
    required this.name,
    required this.avatarIndex,
    required this.isEliminated,
    required this.isHost,
    this.isAI,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> j) => PlayerModel(
        id: j['id'] as String,
        name: j['name'] as String,
        avatarIndex: j['avatarIndex'] as int,
        isEliminated: j['isEliminated'] as bool? ?? false,
        isHost: j['isHost'] as bool? ?? false,
        isAI: j['isAI'] as bool?,
      );

  PlayerModel copyWith({bool? isEliminated, bool? isAI}) => PlayerModel(
        id: id,
        name: name,
        avatarIndex: avatarIndex,
        isEliminated: isEliminated ?? this.isEliminated,
        isHost: isHost,
        isAI: isAI ?? this.isAI,
      );
}

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final int senderAvatarIndex;
  final String content;
  final int timestamp;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarIndex,
    required this.content,
    required this.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
        id: j['id'] as String,
        senderId: j['senderId'] as String,
        senderName: j['senderName'] as String,
        senderAvatarIndex: j['senderAvatarIndex'] as int,
        content: j['content'] as String,
        timestamp: j['timestamp'] as int,
      );
}

class ModeConfig {
  final int playerCount;
  final int humanCount;
  final int aiCount;
  final int totalRounds;

  const ModeConfig({
    required this.playerCount,
    required this.humanCount,
    required this.aiCount,
    required this.totalRounds,
  });

  factory ModeConfig.fromJson(Map<String, dynamic> j) => ModeConfig(
        playerCount: j['playerCount'] as int,
        humanCount: j['humanCount'] as int,
        aiCount: j['aiCount'] as int,
        totalRounds: j['totalRounds'] as int,
      );
}

enum GamePhase { home, modeSelect, lobby, chat, vote, result }

class GameState extends ChangeNotifier {
  // 玩家自己的 socket id（由 socket_service 設定）
  String mySocketId = '';

  // 首頁暱稱
  String nickname = _genNickname();

  // 大廳
  String roomCode = '';
  ModeConfig? mode;
  List<PlayerModel> lobbyPlayers = [];

  // 遊戲中
  List<PlayerModel> players = [];
  List<MessageModel> messages = [];
  int round = 1;
  int totalRounds = 1;
  int aiTotal = 1;
  int aiRemaining = 1;

  // 計時器
  String phase = 'chat'; // chat | vote
  int secondsLeft = 120;

  // 投票
  Map<String, int> voteCounts = {};
  String? myVoteTargetId;

  // 結算
  PlayerModel? eliminatedPlayer;
  bool wasAI = false;

  // 遊戲結束
  String? gameResult;   // humans_win | ai_wins
  String? endReason;
  List<PlayerModel> revealPlayers = [];

  GamePhase screen = GamePhase.home;

  void regenNickname() {
    nickname = _genNickname();
    notifyListeners();
  }

  void setScreen(GamePhase s) {
    screen = s;
    notifyListeners();
  }

  static String _genNickname() {
    final n = 1000 + (DateTime.now().millisecondsSinceEpoch % 9000);
    return '玩家 $n';
  }

  void notify() => notifyListeners();

  void reset() {
    roomCode = '';
    mode = null;
    lobbyPlayers = [];
    players = [];
    messages = [];
    round = 1;
    voteCounts = {};
    myVoteTargetId = null;
    eliminatedPlayer = null;
    wasAI = false;
    gameResult = null;
    endReason = null;
    revealPlayers = [];
    screen = GamePhase.home;
    notifyListeners();
  }
}
