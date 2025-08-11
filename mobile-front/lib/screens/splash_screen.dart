import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_front/core/constants/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/screens/onboarding_screen.dart';
import 'package:mobile_front/screens/login_screen.dart';
import 'package:mobile_front/main.dart'; // sessionManager, ApiConfig
// TODO: 실제 홈으로 교체
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    const secure = FlutterSecureStorage();

    // (선택) 서버에 refresh 로그아웃 알리기
    final rt = await secure.read(key: 'refreshToken');
    if (rt != null) {
      try {
        await http.post(
          Uri.parse(ApiConfig.logout), // ApiConfig.logout = '/api/auth/logout'
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': rt}),
        );
      } catch (_) {}
    }

    await prefs.setBool('isAutoLogin', false);
    await secure.delete(key: 'accessToken');
    await secure.delete(key: 'refreshToken');

    // 전역 세션 타이머 정지
    sessionManager.stop();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈 화면'),
        backgroundColor: AppColors.primaryBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: const Center(
        child: Text(
          '홈 화면 (교체하세요)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

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

  Future<void> _decideRoute() async {
    // 로고/스피너 잠깐 표시
    await Future.delayed(const Duration(milliseconds: 900));

    final prefs = await SharedPreferences.getInstance();

    // 1) 최초 실행이면 온보딩
    final isFirst = prefs.getBool('isFirstLaunch') ?? true;
    if (isFirst) {
      return _go(OnboardingScreen());
    }

    // 2) 자동로그인 여부 확인
    final isAutoLogin = prefs.getBool('isAutoLogin') ?? false;

    if (isAutoLogin) {
      // 자동로그인 ON → refresh로 조용히 복구 시도
      final ok = await _silentLoginWithRefresh();
      if (ok) {
        sessionManager.setAutoLogin(true);
        sessionManager.start();
        return _go(const HomeScreen());
      }
      await _secure.delete(key: 'accessToken');
      await _secure.delete(key: 'refreshToken');
      await prefs.setBool('isAutoLogin', false);
      return _go(const LoginScreen());
    } else {
      // ✅ 자동로그인 OFF → 무조건 로그인 화면으로
      return _go(const LoginScreen());
    }
  }

  /// 자동로그인 ON일 때, refreshToken으로 조용히 세션 복구
  Future<bool> _silentLoginWithRefresh() async {
    final rt = await _secure.read(key: 'refreshToken');
    if (rt == null) return false;

    try {
      final resp = await http.post(
        Uri.parse(ApiConfig.refresh), // '/api/auth/refresh'
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
      }
    } catch (_) {}
    return false;
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
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: const Center(
              child: Text('© 2025 F4', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}
