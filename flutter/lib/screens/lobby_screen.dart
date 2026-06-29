import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../widgets/player_avatar.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final players = state.lobbyPlayers;
    final total = state.mode?.playerCount ?? 4;
    final myId = state.mySocketId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('等待玩家',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('把代碼分享給朋友一起玩',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 24),

              // 房間代碼
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: state.roomCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已複製房間代碼')),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withAlpha(((0.4)*255).round()),
                        style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      const Text('房間代碼',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(
                        state.roomCode,
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.copy, color: AppColors.textMuted, size: 14),
                          SizedBox(width: 4),
                          Text('點擊複製',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text('已加入 ${players.length} / $total 人...',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),

              // 玩家格子
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: total,
                  itemBuilder: (_, i) {
                    if (i < players.length) {
                      final p = players[i];
                      final isMe = p.id == myId;
                      return _PlayerSlot(player: p, isMe: isMe);
                    }
                    return _EmptySlot();
                  },
                ),
              ),

              const SizedBox(height: 12),
              const Center(
                child: Text(
                  '進房順序決定顏色：藍→粉→綠→橙→紫→紅\n每人專屬，整局不撞色',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerSlot extends StatelessWidget {
  final PlayerModel player;
  final bool isMe;

  const _PlayerSlot({required this.player, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isMe
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PlayerAvatar(
            avatarIndex: player.avatarIndex,
            label: avatarLabel(player.name, isMe),
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            player.name,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
          if (isMe)
            const Text('你',
                style:
                    TextStyle(color: AppColors.primaryLight, fontSize: 11)),
        ],
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          style: BorderStyle.solid,
        ),
      ),
      child: const Center(
        child: Text('···',
            style: TextStyle(color: AppColors.textMuted, fontSize: 18)),
      ),
    );
  }
}
