import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../core/socket_service.dart';
import 'join_room_sheet.dart';
import 'mode_select_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: context.read<GameState>().nickname);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _syncName() {
    context.read<GameState>().setNickname(_nameCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Hero logo block ──────────────────────────────
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary.withAlpha(70),
                                AppColors.surfaceLight,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: AppColors.primary.withAlpha(140),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(60),
                                blurRadius: 32,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.smart_toy_outlined,
                            color: AppColors.primaryLight,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'WhosBot',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            '找出聊天室裡的 AI',
                            style: TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 44),
                        // ── Nickname card ────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.badge_outlined,
                                    size: 15,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '你的暱稱',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: () {
                                      context.read<GameState>().regenNickname();
                                      _nameCtrl.text =
                                          context.read<GameState>().nickname;
                                    },
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('換一個'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primaryLight,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      minimumSize: const Size(0, 32),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _nameCtrl,
                                maxLength: 10,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: AppColors.surfaceLight,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onChanged: (_) => _syncName(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // ── Primary action: 建立房間 ──────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withAlpha(80),
                              disabledForegroundColor:
                                  Colors.white.withAlpha(140),
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: state.nickname.isEmpty
                                ? null
                                : () {
                                    _syncName();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ModeSelectScreen(),
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.add_circle_outline, size: 21),
                            label: const Text(
                              '建立房間',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // ── Secondary action: 輸入代碼加入 ────────────────
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              backgroundColor: AppColors.surface,
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: state.nickname.isEmpty
                                ? null
                                : () {
                                    _syncName();
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: AppColors.surface,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      builder: (_) => JoinRoomSheet(
                                        onJoin: (code) {
                                          context
                                              .read<SocketService>()
                                              .joinRoom(
                                                state.nickname,
                                                code,
                                              );
                                        },
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.login, size: 20),
                            label: const Text(
                              '輸入代碼加入',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // ── Leaderboard entry ────────────────────────────
                        TextButton.icon(
                          onPressed: () => context
                              .read<GameState>()
                              .setScreen(GamePhase.leaderboard),
                          icon: const Icon(Icons.emoji_events_outlined, size: 18),
                          label: const Text('查看排行榜'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryLight,
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
