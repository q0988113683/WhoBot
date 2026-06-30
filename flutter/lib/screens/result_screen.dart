import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../widgets/player_avatar.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final isGameOver = state.gameResult != null;

    if (!isGameOver) {
      return _RoundResultScreen(state: state);
    }

    final isWin = state.gameResult == 'humans_win';
    final reason = state.endReason ?? '';

    String title;
    String subtitle;
    if (isWin) {
      final aiCount = state.revealPlayers.where((p) => p.isAI == true).length;
      title = '勝利！${aiCount > 1 ? '兩隻' : ''}AI 都找到了';
      subtitle = reason == 'all_ai_found'
          ? '提早找出全部 AI・${state.round} 回合'
          : '找出全部 AI';
    } else {
      title = '失敗...';
      subtitle = reason == 'rounds_exhausted' ? '回合用完，AI 還潛伏著' : '真人全被淘汰了';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 結果 banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isWin
                          ? AppColors.success.withAlpha(((0.4)*255).round())
                          : AppColors.danger.withAlpha(((0.4)*255).round())),
                ),
                child: Column(
                  children: [
                    Icon(
                      isWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                      color: isWin ? AppColors.success : AppColors.danger,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 玩家揭露
              Expanded(
                child: ListView(
                  children: state.revealPlayers.map((p) {
                    final isAI = p.isAI == true;
                    final isElim = p.isEliminated;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isAI
                            ? AppColors.danger.withAlpha(((0.1)*255).round())
                            : AppColors.success.withAlpha(((0.08)*255).round()),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isAI
                              ? AppColors.danger.withAlpha(((0.3)*255).round())
                              : AppColors.success.withAlpha(((0.3)*255).round()),
                        ),
                      ),
                      child: Row(
                        children: [
                          PlayerAvatar(
                            avatarIndex: p.avatarIndex,
                            label: avatarLabel(p.name,
                                p.id == state.mySocketId),
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500)),
                                if (p.lobbyName != null && p.lobbyName != p.name)
                                  Text(
                                    '原本是 ${p.lobbyName}',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                Text(
                                  isAI ? 'Claude AI' : '真人玩家',
                                  style: TextStyle(
                                      color: isAI
                                          ? AppColors.danger
                                          : AppColors.success,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (isElim)
                            _Badge(
                              label: isAI ? '找到了' : '誤判',
                              color:
                                  isAI ? AppColors.success : AppColors.danger,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => state.reset(),
                  child: const Text('再玩一局',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 每回合結算畫面（非遊戲結束）
class _RoundResultScreen extends StatelessWidget {
  final GameState state;
  const _RoundResultScreen({required this.state});

  @override
  Widget build(BuildContext context) {
    final elim = state.eliminatedPlayer;
    final wasAI = state.wasAI;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  wasAI ? Icons.check_circle : Icons.cancel,
                  color: wasAI ? AppColors.success : AppColors.danger,
                  size: 64,
                ),
                const SizedBox(height: 20),
                Text(
                  wasAI ? '找到 AI 了！' : '誤判了...',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (elim != null)
                  Column(
                    children: [
                      PlayerAvatar(
                          avatarIndex: elim.avatarIndex,
                          label: avatarLabel(
                              elim.name, elim.id == state.mySocketId),
                          size: 56),
                      const SizedBox(height: 8),
                      Text(elim.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 16)),
                      Text(wasAI ? 'Claude AI' : '真人玩家',
                          style: TextStyle(
                              color: wasAI ? AppColors.danger : AppColors.success,
                              fontSize: 13)),
                    ],
                  ),
                const SizedBox(height: 24),
                Text('${state.aiRemaining} 個 AI 還在潛伏...',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 8),
                const Text('下一回合即將開始',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(((0.15)*255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(((0.4)*255).round())),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
