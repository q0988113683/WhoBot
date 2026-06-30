import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// 持久化裝置身份與暱稱（排行榜用）。Web 走 localStorage，行動裝置走原生儲存。
class Prefs {
  static const _kDeviceId = 'device_id';
  static const _kNickname = 'nickname';

  final SharedPreferences _sp;
  Prefs(this._sp);

  static Future<Prefs> load() async {
    final sp = await SharedPreferences.getInstance();
    return Prefs(sp);
  }

  /// 取得（或第一次產生）此裝置的持久 id。
  String deviceId() {
    var id = _sp.getString(_kDeviceId);
    if (id == null || id.isEmpty) {
      id = _generateId();
      _sp.setString(_kDeviceId, id);
    }
    return id;
  }

  String? savedNickname() => _sp.getString(_kNickname);

  void saveNickname(String nickname) {
    _sp.setString(_kNickname, nickname);
  }

  static String _generateId() {
    final r = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(24, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
