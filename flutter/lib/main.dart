import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'core/game_state.dart';
import 'core/socket_service.dart';
import 'core/prefs.dart';
import 'screens/home_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/vote_screen.dart';
import 'screens/result_screen.dart';
import 'screens/leaderboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final state = GameState();
  final prefs = await Prefs.load();
  state.prefs = prefs;
  state.deviceId = prefs.deviceId();
  final savedNick = prefs.savedNickname();
  if (savedNick != null && savedNick.isNotEmpty) state.nickname = savedNick;

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

class _RootNavigator extends StatefulWidget {
  const _RootNavigator();

  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<GameState>();

    // 顯示 socket 傳來的錯誤（例如房間不存在）
    final err = state.errorMessage;
    if (err != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text(err),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ));
        state.clearError();
      });
    }

    final screen = state.screen;
    return switch (screen) {
      GamePhase.home => const HomeScreen(),
      GamePhase.modeSelect => const HomeScreen(),
      GamePhase.lobby => const LobbyScreen(),
      GamePhase.chat => const ChatScreen(),
      GamePhase.vote => const VoteScreen(),
      GamePhase.result => const ResultScreen(),
      GamePhase.leaderboard => const LeaderboardScreen(),
    };
  }
}
