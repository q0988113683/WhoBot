import 'package:flutter_test/flutter_test.dart';
import 'package:whobot_app/core/game_state.dart';

void main() {
  test('暱稱格式正確', () {
    final s = GameState();
    expect(s.nickname, startsWith('玩家 '));
    final num = int.parse(s.nickname.split(' ')[1]);
    expect(num, greaterThanOrEqualTo(1000));
    expect(num, lessThan(10000));
  });

  test('regenNickname 會換新暱稱', () {
    final s = GameState();
    for (int i = 0; i < 10; i++) {
      s.regenNickname();
    }
    expect(s.nickname, startsWith('玩家 '));
  });
}
