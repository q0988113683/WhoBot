import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/game_state.dart';

class HostBanner extends StatelessWidget {
  final HostMessageModel? message;

  const HostBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    final isVoteStart = message!.kind == 'vote_start';
    final isWarning = message!.kind == 'warning' || isVoteStart;
    final emphasized = message!.emphasis || isVoteStart;
    final accent = isWarning ? AppColors.warning : AppColors.primaryLight;

    return Center(
      child: AnimatedScale(
        scale: emphasized ? 1.04 : 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: emphasized ? 14 : 11,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(emphasized ? 242 : 222),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: emphasized ? accent : accent.withAlpha(140),
              width: emphasized ? 1.4 : 1,
            ),
            boxShadow: emphasized
                ? [
                    BoxShadow(
                      color: accent.withAlpha(64),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isWarning ? Icons.campaign_rounded : Icons.auto_awesome,
                color: accent,
                size: emphasized ? 20 : 17,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message!.text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: emphasized ? 14.5 : 13,
                    fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
