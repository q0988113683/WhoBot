import 'package:flutter/material.dart';
import '../core/constants.dart';

class PlayerAvatar extends StatelessWidget {
  final int avatarIndex;
  final String label; // 暱稱數字第一位，或「你」
  final double size;

  const PlayerAvatar({
    super.key,
    required this.avatarIndex,
    required this.label,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final base = AppColors.avatarColor(avatarIndex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(base, Colors.white, 0.18) ?? base,
            base,
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(38), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: base.withAlpha(89),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

/// 產生頭像顯示文字（自己顯示「你」，他人顯示暱稱第一個數字）
String avatarLabel(String name, bool isMe) {
  if (isMe) return '你';
  // 「玩家 4271」→ 取數字部分第一位 = '4'
  final match = RegExp(r'\d').firstMatch(name);
  return match?.group(0) ?? name[0];
}
