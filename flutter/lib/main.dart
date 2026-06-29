import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'core/game_state.dart';
import 'core/socket_service.dart';
import 'screens/home_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/vote_screen.dart';
import 'screens/result_screen.dart';

void main() {
  final state = GameState();
  final socket = SocketService(state);
  socket.connect();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        Provider.value(value: socket),
      ],
      child: const WhoBotApp(),
    ),
  );
}

class WhoBotApp extends StatelessWidget {
  const WhoBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhoBot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const _RootNavigator(),
    );
  }
}

class _RootNavigator extends StatelessWidget {
  const _RootNavigator();

  @override
  Widget build(BuildContext context) {
    final screen = context.watch<GameState>().screen;
    return switch (screen) {
      GamePhase.home => const HomeScreen(),
      GamePhase.modeSelect => const HomeScreen(),
      GamePhase.lobby => const LobbyScreen(),
      GamePhase.chat => const ChatScreen(),
      GamePhase.vote => const VoteScreen(),
      GamePhase.result => const ResultScreen(),
    };
  }
}
