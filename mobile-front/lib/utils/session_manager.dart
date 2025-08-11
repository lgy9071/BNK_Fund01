import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_front/core/constants/colors.dart';

class SessionManager extends ChangeNotifier {
  SessionManager({
    required this.extendUrl,
    required this.refreshUrl,
    required this.navigatorKey,
  });

  final String extendUrl;
  final String refreshUrl;
  final GlobalKey<NavigatorState> navigatorKey;

  final _secure = const FlutterSecureStorage();

  // 설정
  bool _autoLogin = false;
  bool _active = false;
  Duration total = const Duration(minutes: 10);

  // 상태
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  bool _warned = false;
  bool _dialogOpen = false;

  void setAutoLogin(bool v) {
    _autoLogin = v;
  }

  void start() {
    _active = true;
    _reset();
  }

  void stop() {
    _active = false;
    _ticker?.cancel();
    _ticker = null;
    _warned = false;
    _dialogOpen = false;
  }

  void resetOnUserInteraction() {
    if (!_active) return;
    _reset();
  }

  void _reset() {
    if (!_active) return;
    _ticker?.cancel();
    _remaining = total;
    _warned = false;
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      _remaining -= const Duration(seconds: 1);
      if (!_warned && _remaining.inSeconds == 60) {
        _warned = true;
        _showWarnDialog();
      }
      if (_remaining.inSeconds <= 0) {
        t.cancel();
        _onTimeout();
      }
    });
  }

  Future<void> _showWarnDialog() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    final ctx = navigatorKey.currentState?.overlay?.context;
    if (ctx == null) {
      _dialogOpen = false;
      return;
    }

    final ok = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '사용 시간이 곧 종료됩니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF383E56),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                '1분 후 앱이 자동으로 종료됩니다. \n계속 이용하시겠습니까?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        Navigator.of(ctx, rootNavigator: true).pop(false);
                        await Future.delayed(const Duration(milliseconds: 30));
                        SystemNavigator.pop();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF0F1F5),
                        foregroundColor: const Color(0xFF383E56),
                        shape: const StadiumBorder(),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text(
                        '종료',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text(
                        '연장',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    _dialogOpen = false;

    if (ok == true) {
      final success = await _extendSession();
      if (!success) {
        _showSnack('연장 실패. 앱을 종료합니다');
        await _secure.delete(key: 'accessToken');
        if (!_autoLogin) await _secure.delete(key: 'refreshToken');
        await _exitApp();
      } else {
        _showSnack('세션이 연장되었습니다');
      }
    } else if (ok == false) {
      await _secure.delete(key: 'accessToken');
      if (!_autoLogin) await _secure.delete(key: 'refreshToken');
      await _exitApp();
    }
  }

  Future<void> _onTimeout() async {
    await _secure.delete(key: 'accessToken');
    await _exitApp();
  }

  Future<void> _exitApp() async {
    await Future.delayed(const Duration(milliseconds: 50));
    SystemNavigator.pop(); // Android 종료
  }

  Future<bool> _extendSession() async {
    final at = await _secure.read(key: 'accessToken');
    if (at == null) return false;

    final resp = await http.post(
      Uri.parse(extendUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $at',
      },
    );

    if (resp.statusCode == 200) {
      final m = jsonDecode(resp.body) as Map<String, dynamic>;
      final newAt = m['accessToken'] as String?;
      if (newAt != null) {
        await _secure.write(key: 'accessToken', value: newAt);
        _reset();
        return true;
      }
    }
    return false;
  }

  // 현재는 자동복구를 사용하지 않지만, 필요 시 재활용 가능
  Future<bool> _refreshTokens() async {
    final rt = await _secure.read(key: 'refreshToken');
    if (rt == null) return false;

    final resp = await http.post(
      Uri.parse(refreshUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': rt}),
    );

    if (resp.statusCode == 200) {
      final m = jsonDecode(resp.body) as Map<String, dynamic>;
      final newAt = m['accessToken'] as String?;
      final newRt = m['refreshToken'] as String?;
      if (newAt != null && newRt != null) {
        await _secure.write(key: 'accessToken', value: newAt);
        await _secure.write(key: 'refreshToken', value: newRt);
        return true;
      }
    } else {
      await _secure.delete(key: 'refreshToken');
      await _secure.delete(key: 'accessToken');
    }
    return false;
  }

  void _showSnack(String msg) {
    final ctx = navigatorKey.currentState?.overlay?.context;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}
