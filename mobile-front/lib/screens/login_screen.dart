import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/screens/signup/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  bool _autoLogin = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 로고
                Image.asset(
                  'assets/images/splash_logo.png', // TODO: 로고 이미지 경로 추가
                  width: 300,
                  height: 60,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 40),

                // 아이디 입력
                TextFormField(
                  cursorColor: AppColors.primaryBlue,
                  controller: _idController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person), // 아이디 아이콘
                    hintText: '아이디',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // 비밀번호 입력
                TextFormField(
                  controller: _pwController,
                  obscureText: true,
                  cursorColor: AppColors.primaryBlue,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock), // 비밀번호 아이콘
                    hintText: '비밀번호',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 12),

                // 자동 로그인 체크박스
                Row(
                  children: [
                    Checkbox(
                      value: _autoLogin,
                      activeColor: AppColors.primaryBlue,
                      checkColor: Colors.white,
                      onChanged: (value) {
                        setState(() {
                          _autoLogin = value ?? false;
                        });
                      },
                    ),
                    Text('자동 로그인'),
                  ],
                ),
                SizedBox(height: 40),

                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: 로그인 처리
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '로그인',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // 회원가입 링크
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('회원이 아니라면?'),
                    SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        // TODO: 회원가입 화면 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SignupScreen()),
                        );
                      },
                      child: Text(
                        '회원가입',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
