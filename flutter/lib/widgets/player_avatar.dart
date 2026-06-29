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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.avatarColor(avatarIndex),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.bold,
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
