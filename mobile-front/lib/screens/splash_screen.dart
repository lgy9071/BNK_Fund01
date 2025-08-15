import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_front/core/constants/api.dart';
import 'package:mobile_front/dev_jiyong/main_home.dart';
import 'package:mobile_front/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/screens/onboarding_screen.dart';
import 'package:mobile_front/screens/login_screen.dart';
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
        return _go(const MainScaffold());
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
