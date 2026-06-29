import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0F0F14);
  static const surface = Color(0xFF13131A);
  static const surfaceLight = Color(0xFF1E1E2E);
  static const primary = Color(0xFF7C3AED);
  static const primaryLight = Color(0xFFA78BFA);
  static const textPrimary = Color(0xFFD4D4E8);
  static const textMuted = Color(0xFF555566);
  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const border = Color(0xFF2A2A35);

  static const avatarPalette = [
    Color(0xFF3B82F6), // 0 藍
    Color(0xFFEC4899), // 1 粉
    Color(0xFF10B981), // 2 綠
    Color(0xFFF59E0B), // 3 橙
    Color(0xFF8B5CF6), // 4 紫
    Color(0xFFEF4444), // 5 紅
    Color(0xFF06B6D4), // 6 青
    Color(0xFFF97316), // 7 深橙
  ];

  static Color avatarColor(int index) =>
      avatarPalette[index % avatarPalette.length];
}

// 預設使用 localhost，部署時用 --dart-define=SERVER_URL=wss://...
const String kServerUrl = String.fromEnvironment(
  'SERVER_URL',
  defaultValue: 'http://localhost:3000',
);
