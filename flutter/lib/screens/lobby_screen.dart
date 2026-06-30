import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../core/socket_service.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final players = state.lobbyPlayers;
    final mode = state.mode;
    final humanCount = state.lobbyHumanCount > 0
        ? state.lobbyHumanCount
        : mode?.humanCount ?? players.length;
    final joined = state.lobbyJoined > 0 ? state.lobbyJoined : players.length;
    final isHost = players.any((p) => p.id == state.mySocketId && p.isHost);
    final canStart = isHost && joined >= humanCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '等待房間',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mode == null
                              ? '把代碼分享給朋友'
                              : '${mode.playerCount} 人局・等待 $humanCount 位真人',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => state.reset(),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    tooltip: '離開',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: state.roomCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已複製房間代碼')),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withAlpha(115)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '房間代碼',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              state.roomCode,
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.copy, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: humanCount == 0 ? 0 : joined / humanCount,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: const AlwaysStoppedAnimation(AppColors.success),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$joined / $humanCount',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.builder(
                  itemCount: humanCount,
                  itemBuilder: (_, i) {
                    if (i >= players.length) return _EmptyHumanSlot(index: i + 1);
                    final p = players[i];
                    final isMe = p.id == state.mySocketId;
                    return _LobbyPlayerTile(player: p, isMe: isMe);
                  },
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.visibility_off_outlined,
                      color: AppColors.primaryLight,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        canStart
                            ? '真人到齊了。開始後系統會補入 ${mode?.aiCount ?? 0} 個 AI 並匿名排序。'
                            : joined >= humanCount
                                ? '等待房主開始遊戲。'
                                : 'AI 不佔大廳名額，開始後才會加入。',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canStart ? AppColors.primary : AppColors.surfaceLight,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: AppColors.textMuted,
                    disabledBackgroundColor: AppColors.surfaceLight,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: canStart
                      ? () => context.read<SocketService>().startGame()
                      : null,
                  icon: const Icon(Icons.play_arrow, size: 22),
                  label: Text(
                    isHost ? '開始遊戲' : '等待房主開始',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LobbyPlayerTile extends StatelessWidget {
  final PlayerModel player;
  final bool isMe;

  const _LobbyPlayerTile({required this.player, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMe ? AppColors.primary : AppColors.border,
          width: isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceLight,
            child: Icon(
              player.isHost ? Icons.key : Icons.person_outline,
              color: player.isHost ? AppColors.warning : AppColors.textMuted,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player.lobbyName ?? player.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (isMe) const _SmallBadge(label: '你'),
          if (player.isHost) const SizedBox(width: 6),
          if (player.isHost) const _SmallBadge(label: '房主'),
        ],
      ),
    );
  }
}

class _EmptyHumanSlot extends StatelessWidget {
  final int index;

  const _EmptyHumanSlot({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(150),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surfaceLight,
            child: Icon(Icons.person_add_alt_1, color: AppColors.textMuted, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            '等待真人 $index',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;

  const _SmallBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withAlpha(90)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primaryLight,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
