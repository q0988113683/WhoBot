import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../core/socket_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    final state = context.read<GameState>();
    state.leaderboardLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocketService>().getLeaderboard(limit: 50);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final entries = state.leaderboard;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 標題列
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => state.closeLeaderboard(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                  const Text('🏆 ',
                      style: TextStyle(fontSize: 20)),
                  const Text('排行榜',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (state.myRank != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(40),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withAlpha(120)),
                      ),
                      child: Text('我的排名 #${state.myRank}',
                          style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('勝率 = 猜中 AI 次數 ÷ 總投票（至少投 5 票才上榜）',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: state.leaderboardLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : entries.isEmpty
                      ? _empty()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: entries.length,
                          itemBuilder: (_, i) => _row(entries[i], state.nickname),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_outlined,
                  color: AppColors.textMuted, size: 48),
              SizedBox(height: 12),
              Text('還沒有人上榜',
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 16)),
              SizedBox(height: 6),
              Text('多玩幾局、投出 5 票以上就會出現在這裡',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ],
          ),
        ),
      );

  Widget _row(LeaderboardEntry e, String myNick) {
    final medal = switch (e.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };
    final isTop = e.rank <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isTop ? AppColors.surfaceLight : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop ? AppColors.primary.withAlpha(90) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: medal != null
                ? Text(medal, style: const TextStyle(fontSize: 22))
                : Text('${e.rank}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.nickname,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${e.correctVotes} / ${e.totalVotes} 票・${e.gamesPlayed} 局',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${e.winRate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const Text('勝率',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
