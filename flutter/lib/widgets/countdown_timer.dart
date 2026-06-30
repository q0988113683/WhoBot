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
    final isVote = phase == 'vote';
    final accent = isUrgent
        ? AppColors.danger
        : (isVote ? AppColors.warning : AppColors.primaryLight);
    final mm = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (secondsLeft % 60).toString().padLeft(2, '0');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent
            ? AppColors.danger.withAlpha(46)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUrgent ? AppColors.danger : AppColors.border),
        boxShadow: isUrgent
            ? [
                BoxShadow(
                  color: AppColors.danger.withAlpha(89),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVote ? Icons.how_to_vote_outlined : Icons.timer_outlined,
            color: accent,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$mm:$ss',
            style: TextStyle(
              color: isUrgent ? AppColors.danger : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
