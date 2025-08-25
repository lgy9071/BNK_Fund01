import 'package:shared_preferences/shared_preferences.dart';

class ClickLogThrottle {
  static const _prefix = 'fundClickLast';
  static const cooldown = Duration(minutes: 10);

  static String _key(String userId, String fundId) => '$_prefix:$userId:$fundId';

  /// 지금 보내도 되는지?
  static Future<bool> shouldLog({
    required String userId,
    required String fundId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_key(userId, fundId));
    if (last == null) return true;
    final elapsed = DateTime.now().millisecondsSinceEpoch - last;
    return elapsed >= cooldown.inMilliseconds;
  }

  /// 성공적으로 보냈다면 타임스탬프 기록
  static Future<void> markLogged({
    required String userId,
    required String fundId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _key(userId, fundId),
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}