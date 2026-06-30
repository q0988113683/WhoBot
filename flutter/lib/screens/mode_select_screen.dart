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
  late int _selected;

  // 找出 AI（真人多數）
  static const _modesFindAi = [
    {'count': 4, 'human': 3, 'ai': 1, 'rounds': 2, 'mins': '~6 分', 'recommended': false},
    {'count': 6, 'human': 4, 'ai': 2, 'rounds': 4, 'mins': '~12 分', 'recommended': true},
    {'count': 8, 'human': 6, 'ai': 2, 'rounds': 6, 'mins': '~18 分', 'recommended': false},
  ];
  // 找出人類（AI 多數）
  static const _modesFindHuman = [
    {'count': 3, 'human': 1, 'ai': 2, 'rounds': 2, 'mins': '~5 分', 'recommended': false},
    {'count': 5, 'human': 2, 'ai': 3, 'rounds': 3, 'mins': '~9 分', 'recommended': true},
  ];

  List<Map<String, Object>> get _modes =>
      context.read<GameState>().variant == GameVariant.findHuman
          ? _modesFindHuman
          : _modesFindAi;

  @override
  void initState() {
    super.initState();
    final v = context.read<GameState>().variant;
    _selected = v == GameVariant.findHuman ? 5 : 6;
  }

  @override
  Widget build(BuildContext context) {
    final variant = context.watch<GameState>().variant;
    final isFindHuman = variant == GameVariant.findHuman;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          isFindHuman ? '找出人類・選擇人數' : '找出 AI・選擇人數',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFindHuman
                    ? '你是少數真人，假裝成 AI 活到最後'
                    : '人越多，遊戲越久越刺激',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
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
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    final state = context.read<GameState>();
                    context.read<SocketService>().quickMatch(
                          state.nickname,
                          _selected,
                          variant: state.variant,
                        );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.bolt, size: 21, color: Colors.white),
                  label: const Text('快速配對',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    final state = context.read<GameState>();
                    context.read<SocketService>().createRoom(
                          state.nickname,
                          _selected,
                          variant: state.variant,
                        );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('建立私人房間（分享代碼）',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
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
    final isRecommended = mode['recommended'] as bool? ?? false;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withAlpha(((0.14) * 255).round())
              : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(45),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('$count',
                              style: TextStyle(
                                color: selected
                                    ? AppColors.primaryLight
                                    : AppColors.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              )),
                          const SizedBox(width: 3),
                          const Text('人',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Tag(
                            icon: Icons.person,
                            label: '$human 真人',
                            color: AppColors.success,
                          ),
                          _Tag(
                            icon: Icons.smart_toy_outlined,
                            label: '$ai AI',
                            color: AppColors.danger,
                          ),
                          _MetaText(text: '$rounds 回合'),
                          _MetaText(text: mins),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // 真人/AI 點點
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    ...List.generate(
                        human, (_) => const _Dot(color: AppColors.success)),
                    ...List.generate(
                        ai, (_) => const _Dot(color: AppColors.danger)),
                  ],
                ),
              ],
            ),
            if (isRecommended)
              Positioned(
                top: -10,
                right: -8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(90),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Text('推薦',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Tag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final String text;
  const _MetaText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withAlpha(110), blurRadius: 5),
        ],
      ),
    );
  }
}
