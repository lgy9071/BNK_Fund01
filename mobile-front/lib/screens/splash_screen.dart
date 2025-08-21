import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_front/core/constants/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/screens/onboarding_screen.dart';
import 'package:mobile_front/screens/login_screen.dart';
import 'package:mobile_front/screens/main_scaffold.dart';
import 'package:mobile_front/main.dart'; // sessionManager, ApiConfig

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _secure = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _decideRoute();
  }

  // 로그인 화면/온보딩/메인으로 갈지 결정
  Future<void> _decideRoute() async {
    // 로고 잠깐 노출
    await Future.delayed(const Duration(milliseconds: 900));

    final prefs = await SharedPreferences.getInstance();

    // 최초 실행 → 온보딩
    final isFirst = prefs.getBool('isFirstLaunch') ?? true;
    if (isFirst) {
      return _go(OnboardingScreen());
    }

    // 자동로그인 여부
    final isAutoLogin = prefs.getBool('isAutoLogin') ?? false;

    if (!isAutoLogin) {
      return _go(const LoginScreen());
    }

    // 자동로그인 ON → refresh로 조용히 복구 시도
    final ok = await _silentLoginWithRefresh();
    if (ok) {
      sessionManager.setAutoLogin(true);
      sessionManager.start();
      return _go(const MainScaffold());
    }

    // 실패 시 깔끔히 정리
    await _secure.delete(key: 'accessToken');
    await _secure.delete(key: 'refreshToken');
    await prefs.setBool('isAutoLogin', false);
    return _go(const LoginScreen());
  }

  /// 제로폭/공백류 제거 + trim
  String cleanToken(String? t) {
    if (t == null) return '';
    final cleaned = t
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF\u00A0]'), '')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
    return cleaned;
  }

  /// 자동로그인 ON일 때, refreshToken으로 조용히 세션 복구
  Future<bool> _silentLoginWithRefresh() async {
    // 저장된 refresh 읽기 + 클린
    final storedRtRaw = await _secure.read(key: 'refreshToken');
    final rt = cleanToken(storedRtRaw);
    if (rt.isEmpty) {
      debugPrint('[SPLASH] no refreshToken in storage');
      return false;
    }

    try {
      final resp = await http
          .post(
        Uri.parse(ApiConfig.refresh), // '/api/auth/refresh'
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': rt}),
      )
          .timeout(const Duration(seconds: 10));

      debugPrint('[SPLASH][REFRESH] status=${resp.statusCode}');
      // 참고용: 실제 바디를 한 번 보세요(민감하면 비활성화)
      // debugPrint('[SPLASH][REFRESH] body=${resp.body}');

      if (resp.statusCode == 200) {
        final Map<String, dynamic> m = jsonDecode(resp.body);

        // camelCase/snake_case 모두 수용
        final newAt = cleanToken(
          (m['accessToken'] ?? m['access_token']) as String?,
        );
        final newRt = cleanToken(
          (m['refreshToken'] ?? m['refresh_token']) as String?,
        );

        // 회전형이면 두 값이 같이 와야 정상
        if (newAt.isNotEmpty && newRt.isNotEmpty) {
          await _secure.write(key: 'accessToken', value: newAt);
          await _secure.write(key: 'refreshToken', value: newRt); // ← 회전된 RT로 교체 저장 (중요)
          debugPrint('[SPLASH][REFRESH] success: at=${newAt.substring(0, newAt.length >= 12 ? 12 : newAt.length)}...');
          return true;
        }

        // 혹시 서버가 access만 주는 특수 케이스도 방어
        if (newAt.isNotEmpty && newRt.isEmpty) {
          await _secure.write(key: 'accessToken', value: newAt);
          debugPrint('[SPLASH][REFRESH] access only');
          return true;
        }

        debugPrint('[SPLASH][REFRESH] missing tokens in body');
        return false;
      }

      // 401/403/4xx/5xx
      debugPrint('[SPLASH][REFRESH] http error: ${resp.statusCode} ${resp.body}');
      return false;
    } catch (e) {
      debugPrint('[SPLASH][REFRESH] error: $e');
      return false;
    }
  }

  void _go(Widget page) {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/splash_logo.png',
                  width: 250,
                ),
                const SizedBox(height: 100),
                const CircularProgressIndicator(color: AppColors.primaryBlue),
              ],
            ),
          ),
          const Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text('© 2025 F4', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}
