import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../core/socket_service.dart';
import 'mode_select_screen.dart';
import 'join_room_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(((0.2)*255).round()),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withAlpha(((0.5)*255).round())),
                  ),
                  child: const Icon(Icons.smart_toy_outlined,
                      color: AppColors.primaryLight, size: 40),
                ),
                const SizedBox(height: 20),
                const Text('WhoBot',
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 6),
                const Text('找出聊天室裡的 AI',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                const SizedBox(height: 48),

                // 暱稱卡
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Text('你的暱稱',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(state.nickname,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => context.read<GameState>().regenNickname(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.refresh,
                                color: AppColors.primaryLight, size: 16),
                            SizedBox(width: 4),
                            Text('換一個',
                                style: TextStyle(
                                    color: AppColors.primaryLight,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 建立房間
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ModeSelectScreen()),
                      );
                    },
                    child: const Text('建立房間',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),

                // 輸入代碼加入
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: AppColors.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (_) => JoinRoomSheet(
                          onJoin: (code) {
                            context.read<SocketService>().joinRoom(
                                  state.nickname,
                                  code,
                                );
                          },
                        ),
                      );
                    },
                    child: const Text('輸入代碼加入',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
