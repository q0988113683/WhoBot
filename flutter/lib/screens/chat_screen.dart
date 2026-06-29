import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../core/socket_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/player_avatar.dart';
import '../widgets/countdown_timer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(GameState state) {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    context.read<SocketService>().sendMessage(text);
    _ctrl.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();
    final myId = state.mySocketId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 頂部：計時器 + 回合
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  CountdownTimer(
                      secondsLeft: state.secondsLeft, phase: state.phase),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '回合 ${state.round} / ${state.totalRounds}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            // 頭像列
            SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.players.length,
                itemBuilder: (_, i) {
                  final p = state.players[i];
                  final isMe = p.id == myId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Opacity(
                      opacity: p.isEliminated ? 0.3 : 1,
                      child: PlayerAvatar(
                        avatarIndex: p.avatarIndex,
                        label: avatarLabel(p.name, isMe),
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(color: AppColors.border, height: 1),

            // 訊息區
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                itemCount: state.messages.length,
                itemBuilder: (_, i) {
                  final msg = state.messages[i];
                  return MessageBubble(
                    message: msg,
                    isMe: msg.senderId == myId,
                  );
                },
              ),
            ),

            // 輸入框
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style:
                          const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: '說點什麼...',
                        hintStyle:
                            const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLength: 200,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                          null,
                      onSubmitted: (_) => _send(state),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _send(state),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
