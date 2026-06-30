import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../core/socket_service.dart';
import '../widgets/player_avatar.dart';
import '../widgets/host_banner.dart';
import '../widgets/countdown_timer.dart';

class VoteScreen extends StatelessWidget {
  const VoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final myId = state.mySocketId;
    final alive =
        state.players.where((p) => !p.isEliminated && p.id != myId).toList();
    final totalVotes = state.voteCounts.values.fold(0, (a, b) => a + b);
    final hasSelection = state.myVoteTargetId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 主持人提示
            HostBanner(message: state.hostMessage),

            // 標題列
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('誰是 AI？',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.danger
                                    .withAlpha((0.15 * 255).round()),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('還有 ${state.aiRemaining} 個 AI 未找出',
                                  style: const TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  CountdownTimer(secondsLeft: state.secondsLeft, phase: 'vote'),
                ],
              ),
            ),

            // 玩家卡片
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                itemCount: alive.length,
                itemBuilder: (_, i) {
                  final p = alive[i];
                  final votes = state.voteCounts[p.id] ?? 0;
                  final ratio = totalVotes > 0 ? votes / totalVotes : 0.0;
                  final selected = state.myVoteTargetId == p.id;

                  return GestureDetector(
                    onTap: () {
                      state.myVoteTargetId = p.id;
                      state.notify();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withAlpha((0.15 * 255).round())
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withAlpha((0.25 * 255).round()),
                                  blurRadius: 16,
                                  spreadRadius: -2,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              PlayerAvatar(
                                avatarIndex: p.avatarIndex,
                                label: avatarLabel(p.name, false),
                                size: 42,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(p.name,
                                    style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500)),
                              ),
                              if (selected)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Icon(Icons.check_circle,
                                      color: AppColors.primaryLight, size: 20),
                                ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('$votes',
                                      style: const TextStyle(
                                          color: AppColors.primaryLight,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const Text('票',
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 懷疑度進度條
                          Row(
                            children: [
                              const Text('懷疑度',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: ratio),
                                    duration:
                                        const Duration(milliseconds: 350),
                                    curve: Curves.easeOut,
                                    builder: (_, v, __) =>
                                        LinearProgressIndicator(
                                      value: v,
                                      backgroundColor: AppColors.surfaceLight,
                                      valueColor: AlwaysStoppedAnimation(
                                          selected
                                              ? AppColors.primaryLight
                                              : AppColors.primary),
                                      minHeight: 7,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 確認投票
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasSelection
                        ? AppColors.primary
                        : AppColors.surfaceLight,
                    disabledBackgroundColor: AppColors.surfaceLight,
                    elevation: hasSelection ? 4 : 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: hasSelection
                      ? () {
                          context
                              .read<SocketService>()
                              .castVote(state.myVoteTargetId!);
                        }
                      : null,
                  icon: Icon(Icons.how_to_vote,
                      size: 20,
                      color: hasSelection
                          ? Colors.white
                          : AppColors.textMuted),
                  label: Text(hasSelection ? '確認投票' : '選一位玩家投票',
                      style: TextStyle(
                          color:
                              hasSelection ? Colors.white : AppColors.textMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
