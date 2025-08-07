import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _moveToOnboarding();
  }

  Future<void> _moveToOnboarding() async {
    await Future.delayed(Duration(seconds: 2)); // 로딩 애니메이션 잠깐 보여주기

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OnboardingScreen()),
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
