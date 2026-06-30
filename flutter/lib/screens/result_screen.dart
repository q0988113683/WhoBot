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

    final isFindHuman = state.variant == GameVariant.findHuman;
    final isWin = state.gameResult == 'humans_win'; // 玩家恆為真人陣營
    final reason = state.endReason ?? '';

    String title;
    String subtitle;
    if (isFindHuman) {
      if (isWin) {
        title = '人類獲勝！';
        subtitle = reason == 'all_ai_eliminated'
            ? '把 AI 全投出去了'
            : '成功偽裝成 AI，撐到了最後';
      } else {
        title = '被識破了...';
        subtitle = '偽裝的人類全被 AI 揪出來了';
      }
    } else {
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
    }

    final accent = isWin ? AppColors.success : AppColors.danger;

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
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accent.withAlpha((0.14 * 255).round()),
                      AppColors.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: accent.withAlpha((0.45 * 255).round())),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withAlpha((0.18 * 255).round()),
                      blurRadius: 24,
                      spreadRadius: -6,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: accent.withAlpha((0.15 * 255).round()),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isWin
                            ? Icons.emoji_events
                            : Icons.sentiment_dissatisfied,
                        color: accent,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: Text('身份揭曉',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
              ),
              const SizedBox(height: 10),

              // 玩家揭露
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: state.revealPlayers.map((p) {
                    final isAI = p.isAI == true;
                    final isElim = p.isEliminated;
                    final tone = isAI ? AppColors.danger : AppColors.success;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tone.withAlpha((0.08 * 255).round()),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: tone.withAlpha((0.3 * 255).round()),
                        ),
                      ),
                      child: Row(
                        children: [
                          PlayerAvatar(
                            avatarIndex: p.avatarIndex,
                            label: avatarLabel(p.name, p.id == state.mySocketId),
                            size: 42,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                                if (p.lobbyName != null &&
                                    p.lobbyName != p.name)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 1),
                                    child: Text(
                                      '原本是 ${p.lobbyName}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                        isAI
                                            ? Icons.smart_toy
                                            : Icons.person,
                                        color: tone,
                                        size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      isAI ? 'Claude AI' : '真人玩家',
                                      style: TextStyle(
                                          color: tone,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isElim)
                            () {
                              // 被淘汰者是否屬於「被獵殺隊伍」（找出AI→AI；找出人類→人類）
                              final wasHunted = isFindHuman ? !isAI : isAI;
                              return _Badge(
                                label: wasHunted ? '找到了' : '誤判',
                                color: wasHunted
                                    ? AppColors.success
                                    : AppColors.danger,
                              );
                            }(),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => state.setScreen(GamePhase.leaderboard),
                      icon: const Icon(Icons.emoji_events_outlined, size: 18),
                      label: const Text('排行榜',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => state.reset(),
                      icon: const Icon(Icons.replay,
                          size: 18, color: Colors.white),
                      label: const Text('再玩一局',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
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
    final isFindHuman = state.variant == GameVariant.findHuman;
    // 是否投中「被獵殺隊伍」（找出AI→AI；找出人類→人類）
    final foundHunted = isFindHuman ? !wasAI : wasAI;
    final accent = foundHunted ? AppColors.success : AppColors.danger;
    final identityTone = wasAI ? AppColors.danger : AppColors.success;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: accent.withAlpha((0.12 * 255).round()),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withAlpha((0.2 * 255).round()),
                        blurRadius: 28,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Icon(
                    foundHunted ? Icons.check_circle : Icons.cancel,
                    color: accent,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  foundHunted ? '找到${state.huntedLabel}了！' : '誤判了...',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 20),
                if (elim != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: accent.withAlpha((0.35 * 255).round())),
                    ),
                    child: Column(
                      children: [
                        PlayerAvatar(
                            avatarIndex: elim.avatarIndex,
                            label: avatarLabel(
                                elim.name, elim.id == state.mySocketId),
                            size: 60),
                        const SizedBox(height: 10),
                        Text(elim.name,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(wasAI ? Icons.smart_toy : Icons.person,
                                color: identityTone, size: 14),
                            const SizedBox(width: 4),
                            Text(wasAI ? 'Claude AI' : '真人玩家',
                                style: TextStyle(
                                    color: identityTone,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 28),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withAlpha((0.12 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${state.huntedRemaining} 個${state.huntedLabel}還在潛伏...',
                      style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.textMuted),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('下一回合即將開始',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha((0.4 * 255).round())),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
