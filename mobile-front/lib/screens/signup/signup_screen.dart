import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_front/screens/signup/steps/step1_id.dart';
import 'package:mobile_front/screens/signup/steps/step2_password.dart';
import 'package:mobile_front/screens/signup/steps/step3_name.dart';
import 'package:mobile_front/screens/signup/steps/step4_phone.dart';
import 'package:mobile_front/screens/signup/steps/step5_email.dart';
import 'package:mobile_front/screens/signup/steps/step6_success.dart';


class SignupScreen extends StatefulWidget {
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 사용자 입력값 저장
  String userId = '';
  String password = '';
  String name = '';
  String phone = '';
  String email = '';

  void _nextPage() {
    if (_currentPage < 5) {
      setState(() => _currentPage++);
      _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.ease);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.ease);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentPage > 0) {
          _prevPage();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            Step1IdScreen(userId: userId, onNext: (val) { userId = val; _nextPage(); }),
            Step2PasswordScreen(password: password, onNext: (val) { password = val; _nextPage(); }, onBack: _prevPage),
            Step3NameScreen(name: name, onNext: (val) { name = val; _nextPage(); }, onBack: _prevPage),
            Step4PhoneScreen(phone: phone, onNext: (val) { phone = val; _nextPage(); }, onBack: _prevPage),
            Step5EmailScreen(
              email: email,
              onComplete: (val) {
                email = val;
                _sendSignupRequest();
                _nextPage();
              },
              onBack: _prevPage,
            ),

            SignupCompleteScreen(), // 회원가입 완료 화면
          ],
        ),
      ),
    );
  }

  void _sendSignupRequest() async {
    final body = {
      "username": userId,
      "password": password,
      "name": name,
      "phone": phone,
      "email": email,
    };

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.245:8090/api/signup'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        print("회원가입 실패");
      }
    } catch (e) {
      print("에러 발생: $e");
    }
  }
}
