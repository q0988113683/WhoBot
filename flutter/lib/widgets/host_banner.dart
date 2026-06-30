import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/game_state.dart';

class HostBanner extends StatelessWidget {
  final HostMessageModel? message;

  const HostBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    final isWarning = message!.kind == 'warning' || message!.kind == 'vote_start';
    return AnimatedScale(
      scale: message!.emphasis ? 1.02 : 1,
      duration: const Duration(milliseconds: 180),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(230),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isWarning ? AppColors.warning : AppColors.primaryLight,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isWarning ? Icons.campaign_outlined : Icons.auto_awesome,
              color: isWarning ? AppColors.warning : AppColors.primaryLight,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message!.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
