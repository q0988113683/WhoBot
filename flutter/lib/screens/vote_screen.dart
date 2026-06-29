import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../core/socket_service.dart';
import '../widgets/player_avatar.dart';
import '../widgets/countdown_timer.dart';

class VoteScreen extends StatelessWidget {
  const VoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final myId = state.mySocketId;
    final alive =
        state.players.where((p) => !p.isEliminated && p.id != myId).toList();
    final totalVotes =
        state.voteCounts.values.fold(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 標題列
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('誰是 AI？',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        Text('還有 ${state.aiRemaining} 個 AI 未找出',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                  CountdownTimer(
                      secondsLeft: state.secondsLeft, phase: 'vote'),
                ],
              ),
            ),

            // 玩家卡片
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: alive.length,
                itemBuilder: (_, i) {
                  final p = alive[i];
                  final votes = state.voteCounts[p.id] ?? 0;
                  final ratio =
                      totalVotes > 0 ? votes / totalVotes : 0.0;
                  final selected = state.myVoteTargetId == p.id;

                  return GestureDetector(
                    onTap: () {
                      state.myVoteTargetId = p.id;
                      state.notify();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withAlpha(((0.15)*255).round())
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              PlayerAvatar(
                                avatarIndex: p.avatarIndex,
                                label: avatarLabel(p.name, false),
                                size: 40,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(p.name,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                              ),
                              Text('$votes 票',
                                  style: const TextStyle(
                                      color: AppColors.primaryLight,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // 懷疑度進度條
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: AppColors.surfaceLight,
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary),
                              minHeight: 6,
                            ),
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
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.myVoteTargetId != null
                        ? AppColors.primary
                        : AppColors.surfaceLight,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: state.myVoteTargetId != null
                      ? () {
                          context
                              .read<SocketService>()
                              .castVote(state.myVoteTargetId!);
                        }
                      : null,
                  child: const Text('確認投票',
                      style: TextStyle(
                          color: Colors.white,
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
