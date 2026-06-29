import 'package:flutter/material.dart';
import '../core/constants.dart';

class CountdownTimer extends StatelessWidget {
  final int secondsLeft;
  final String phase;

  const CountdownTimer(
      {super.key, required this.secondsLeft, required this.phase});

  @override
  Widget build(BuildContext context) {
    final isUrgent = secondsLeft < 20;
    final mm = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (secondsLeft % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.danger.withAlpha(((0.2)*255).round()) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUrgent ? AppColors.danger : AppColors.border,
        ),
      ),
      child: Text(
        '$mm:$ss',
        style: TextStyle(
          color: isUrgent ? AppColors.danger : AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
