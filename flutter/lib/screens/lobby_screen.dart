import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../core/socket_service.dart';
import '../widgets/player_avatar.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final players = state.lobbyPlayers;
    final mode = state.mode;
    final humanCount = state.lobbyHumanCount > 0
        ? state.lobbyHumanCount
        : mode?.humanCount ?? players.length;
    final joined = state.lobbyJoined > 0 ? state.lobbyJoined : players.length;
    final isHost = players.any((p) => p.id == state.mySocketId && p.isHost);
    final canStart = isHost && joined >= humanCount;
    final isFull = joined >= humanCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== 標題列 =====
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '等待房間',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mode == null
                              ? '把代碼分享給朋友'
                              : '${mode.playerCount} 人局・等待 $humanCount 位真人',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => state.reset(),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    tooltip: '離開',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ===== 房間代碼卡 =====
              _RoomCodeCard(roomCode: state.roomCode),
              const SizedBox(height: 18),

              // ===== 加入人數狀態列 =====
              _JoinStatus(joined: joined, humanCount: humanCount, isFull: isFull),
              const SizedBox(height: 18),

              // ===== 玩家格狀清單 =====
              Expanded(
                child: _PlayerGrid(
                  players: players,
                  humanCount: humanCount,
                  mySocketId: state.mySocketId,
                ),
              ),
              const SizedBox(height: 14),

              // ===== 提示卡 =====
              _HintCard(
                canStart: canStart,
                isFull: isFull,
                aiCount: mode?.aiCount ?? 0,
              ),
              const SizedBox(height: 12),

              // ===== 底部開始按鈕 =====
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canStart ? AppColors.primary : AppColors.surfaceLight,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: AppColors.textMuted,
                    disabledBackgroundColor: AppColors.surfaceLight,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: canStart
                      ? () => context.read<SocketService>().startGame()
                      : null,
                  icon: Icon(
                    isHost ? Icons.play_arrow_rounded : Icons.hourglass_top_rounded,
                    size: 22,
                  ),
                  label: Text(
                    isHost ? '開始遊戲' : '等待房主開始...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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

// ============================================================
// 房間代碼卡：大型數字 + 複製按鈕
// ============================================================
class _RoomCodeCard extends StatelessWidget {
  final String roomCode;

  const _RoomCodeCard({required this.roomCode});

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceLight,
        content: const Text(
          '已複製房間代碼',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _copy(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.surfaceLight, AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withAlpha(115)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.tag, color: AppColors.textMuted, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '房間代碼',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    roomCode,
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 10,
                      fontFeatures: [FontFeature.tabularFigures()],
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            // 複製按鈕
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(40),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withAlpha(90)),
              ),
              child: const Icon(
                Icons.copy_rounded,
                color: AppColors.primaryLight,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 加入人數狀態列（僅計真人）
// ============================================================
class _JoinStatus extends StatelessWidget {
  final int joined;
  final int humanCount;
  final bool isFull;

  const _JoinStatus({
    required this.joined,
    required this.humanCount,
    required this.isFull,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isFull ? Icons.check_circle_rounded : Icons.group_outlined,
              size: 16,
              color: isFull ? AppColors.success : AppColors.primaryLight,
            ),
            const SizedBox(width: 6),
            Text(
              isFull ? '真人已到齊' : '已加入',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$joined',
                    style: TextStyle(
                      color: isFull ? AppColors.success : AppColors.primaryLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: ' / $humanCount',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: humanCount == 0 ? 0 : (joined / humanCount).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation(
              isFull ? AppColors.success : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 玩家格狀清單
// ============================================================
class _PlayerGrid extends StatelessWidget {
  final List<PlayerModel> players;
  final int humanCount;
  final String mySocketId;

  const _PlayerGrid({
    required this.players,
    required this.humanCount,
    required this.mySocketId,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 響應式欄數：依寬度決定
        final crossAxisCount = constraints.maxWidth >= 520
            ? 4
            : constraints.maxWidth >= 360
                ? 3
                : 2;
        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
          ),
          itemCount: humanCount,
          itemBuilder: (_, i) {
            if (i >= players.length) {
              return _EmptyHumanSlot(index: i + 1);
            }
            final p = players[i];
            final isMe = p.id == mySocketId;
            return _LobbyPlayerCard(player: p, isMe: isMe);
          },
        );
      },
    );
  }
}

// ============================================================
// 已加入玩家卡：彩色頭像 + 名稱 + 你/房主 徽章
// ============================================================
class _LobbyPlayerCard extends StatelessWidget {
  final PlayerModel player;
  final bool isMe;

  const _LobbyPlayerCard({required this.player, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final name = player.lobbyName ?? player.name;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? AppColors.primary : AppColors.border,
          width: isMe ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              PlayerAvatar(
                avatarIndex: player.avatarIndex,
                label: avatarLabel(name, isMe),
                size: 52,
              ),
              if (player.isHost)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: const Icon(Icons.key, color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isMe) const _SmallBadge(label: '你'),
              if (isMe && player.isHost) const SizedBox(width: 4),
              if (player.isHost) const _SmallBadge(label: '房主', warning: true),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 空位卡：虛線邊框 + 等待圖示
// ============================================================
class _EmptyHumanSlot extends StatelessWidget {
  final int index;

  const _EmptyHumanSlot({required this.index});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: AppColors.border,
        radius: 16,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(120),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                color: AppColors.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '等待真人 $index',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const _SmallBadge(label: '空位', muted: true),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 底部提示卡
// ============================================================
class _HintCard extends StatelessWidget {
  final bool canStart;
  final bool isFull;
  final int aiCount;

  const _HintCard({
    required this.canStart,
    required this.isFull,
    required this.aiCount,
  });

  @override
  Widget build(BuildContext context) {
    final text = canStart
        ? '真人到齊了。開始後系統會補入 $aiCount 個 AI 並匿名排序。'
        : isFull
            ? '等待房主開始遊戲。'
            : 'AI 不佔大廳名額，開始後才會加入。';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_off_outlined,
            color: AppColors.primaryLight,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 小徽章
// ============================================================
class _SmallBadge extends StatelessWidget {
  final String label;
  final bool warning;
  final bool muted;

  const _SmallBadge({
    required this.label,
    this.warning = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = muted
        ? AppColors.textMuted
        : warning
            ? AppColors.warning
            : AppColors.primary;
    final fg = muted
        ? AppColors.textMuted
        : warning
            ? AppColors.warning
            : AppColors.primaryLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withAlpha(35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withAlpha(90)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// 虛線邊框繪製
// ============================================================
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
