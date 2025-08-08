import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/screens/onboarding_screen.dart';
import 'package:mobile_front/screens/login_screen.dart';
// TODO: 실제 홈으로 교체
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final _secure = const FlutterSecureStorage();

    await prefs.setBool('isAutoLogin', false); // ✅ 수정된 키 이름
    await prefs.remove('tokenExpiresAt');
    await _secure.delete(key: 'accessToken');   // ✅ 토큰도 삭제

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
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
    // 로고/스피너 살짝 보여주기
    await Future.delayed(const Duration(milliseconds: 900));

    final prefs = await SharedPreferences.getInstance();

    // 1) 최초 실행이면 온보딩
    final isFirst = prefs.getBool('isFirstLaunch') ?? true;
    if (isFirst) {
      return _go(OnboardingScreen());
    }

    // 2) 자동로그인 설정 여부 확인
    final isAutoLogin = prefs.getBool('isAutoLogin') ?? false;
    if (!isAutoLogin) {
      return _go(const LoginScreen());
    }

    // 3) 토큰/만료 확인
    final token = await _secure.read(key: 'accessToken');
    final expIso = prefs.getString('tokenExpiresAt');

    final hasValidToken = token != null && expIso != null && _notExpired(expIso);

    if (hasValidToken) {
      // (선택) 서버 검증까지 하고 싶으면 여기서 /api/auth/me 같은 핑을 한 번 더 보내도 됨
      return _go(const HomeScreen()); // TODO: 실제 홈으로 교체
    } else {
      // 자동로그인 청소
      await _secure.delete(key: 'accessToken');
      await prefs.remove('tokenExpiresAt');
      await prefs.setBool('isAutoLogin', false);
      return _go(const LoginScreen());
    }
  }

  bool _notExpired(String iso) {
    try {
      final exp = DateTime.parse(iso);
      return DateTime.now().isBefore(exp);
    } catch (_) {
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
          // 가운데 로고 + 텍스트 + 로딩
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/splash_logo.png', // 🔺 이 파일 준비 필요
                  width: 250,
                ),
                SizedBox(height: 100),
                CircularProgressIndicator(color: AppColors.primaryBlue,), // 로딩 애니메이션
              ],
            ),
          ),

          // 하단 크레딧
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '© 2025 F4',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
