import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../core/socket_service.dart';

class ModeSelectScreen extends StatefulWidget {
  const ModeSelectScreen({super.key});

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  int _selected = 6; // 預設推薦 6 人

  static const _modes = [
    {'count': 4, 'human': 3, 'ai': 1, 'rounds': 2, 'mins': '~6 分'},
    {'count': 6, 'human': 4, 'ai': 2, 'rounds': 4, 'mins': '~12 分'},
    {'count': 8, 'human': 6, 'ai': 2, 'rounds': 6, 'mins': '~18 分'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: const Text('選擇人數'),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('人越多，遊戲越久越刺激',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            ..._modes.map((m) => _ModeCard(
                  mode: m,
                  selected: _selected == m['count'],
                  onTap: () => setState(() => _selected = m['count'] as int),
                )),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final state = context.read<GameState>();
                  context.read<SocketService>().quickMatch(
                        state.nickname,
                        _selected,
                      );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.bolt, size: 20, color: Colors.white),
                label: const Text('快速配對',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final state = context.read<GameState>();
                  context.read<SocketService>().createRoom(
                        state.nickname,
                        _selected,
                      );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('建立私人房間（分享代碼）',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final Map<String, Object> mode;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard(
      {required this.mode, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = mode['count'] as int;
    final human = mode['human'] as int;
    final ai = mode['ai'] as int;
    final rounds = mode['rounds'] as int;
    final mins = mode['mins'] as String;
    final isRecommended = count == 6;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(((0.15)*255).round()) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$count 人',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          )),
                      const SizedBox(height: 4),
                      Text(
                        '$human 真人・$ai AI   $rounds 回合   $mins',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // 真人/AI 點點
                Row(
                  children: [
                    ...List.generate(human,
                        (_) => _Dot(color: AppColors.success)),
                    ...List.generate(ai, (_) => _Dot(color: AppColors.danger)),
                  ],
                ),
              ],
            ),
            if (isRecommended)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('推薦',
                      style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
