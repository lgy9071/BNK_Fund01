import 'package:flutter/material.dart';
import 'dart:math';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/screens/login_screen.dart';


class SignupCompleteScreen extends StatefulWidget {
  const SignupCompleteScreen({Key? key}) : super(key: key);

  @override
  State<SignupCompleteScreen> createState() => _SignupCompleteScreenState();
}

class _SignupCompleteScreenState extends State<SignupCompleteScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation = const AlwaysStoppedAnimation(0); // ✅ 기본값 줌

  @override
  void initState() {
    super.initState();

    // 키보드 닫기
    Future.delayed(Duration.zero, () {
      FocusScope.of(context).unfocus();
    });

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    _rotation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _rotation,
              builder: (context, child) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_rotation.value),
                  child: child,
                );
              },
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryBlue,
                child: const Icon(Icons.check, color: Colors.white, size: 60),
              ),
            ),
            const SizedBox(height: 60),
            const Text(
              "회원가입이\n정상적으로 처리되었습니다",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 25),
            ),
            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                      (Route<dynamic> route) => false, // 모든 이전 화면 제거
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(140, 50),
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,

              ),
              child: const Text("로그인",style: TextStyle(fontSize: 18),),
            ),
          ],
        ),
      ),
    );
  }
}
