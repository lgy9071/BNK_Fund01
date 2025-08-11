import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_front/core/constants/api.dart';
import 'package:mobile_front/core/routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/screens/signup/signup_screen.dart';
import 'package:mobile_front/utils/exit_popup.dart';
import 'package:mobile_front/main.dart'; // navigatorKey, sessionManager, ApiConfig

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final _secure = const FlutterSecureStorage();

  bool _autoLogin = false;
  bool _loading = false;

  final _loginUrl = ApiConfig.login;

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final id = _idController.text.trim();
    final pw = _pwController.text;

    if (id.isEmpty || pw.isEmpty) {
      _toast('아이디와 비밀번호를 입력하세요.');
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await http.post(
        Uri.parse(_loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': id,
          'password': pw,
          'autoLogin': _autoLogin, // ✅ 서버에 전달
        }),
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(res.body);
        final access = body['accessToken'] as String?;
        final refresh = body['refreshToken'] as String?;

        if (access == null) {
          _toast('로그인 실패: 액세스 토큰이 없습니다.');
          return;
        }

        await _secure.write(key: 'accessToken', value: access);
        if (_autoLogin && refresh != null) {
          await _secure.write(key: 'refreshToken', value: refresh);
        } else {
          await _secure.delete(key: 'refreshToken');
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAutoLogin', _autoLogin);

        // ✅ 전역 세션 설정/시작
        sessionManager.setAutoLogin(_autoLogin);
        sessionManager.start();

        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
              (_) => false,
        );
        //Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);

      } else if (res.statusCode == 401) {
        _toast('아이디 또는 비밀번호가 올바르지 않습니다.');
      } else {
        _toast('로그인 실패 (${res.statusCode})');
      }
    } catch (e) {
      _toast('네트워크 오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    final ctx = context;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await showExitPopup(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/splash_logo.png', width: 300, height: 60, fit: BoxFit.contain),
                  const SizedBox(height: 40),

                  TextFormField(
                    cursorColor: AppColors.primaryBlue,
                    controller: _idController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      hintText: '아이디',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _pwController,
                    obscureText: true,
                    cursorColor: AppColors.primaryBlue,
                    onFieldSubmitted: (_) => _loading ? null : _login(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      hintText: '비밀번호',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Checkbox(
                        value: _autoLogin,
                        activeColor: AppColors.primaryBlue,
                        checkColor: Colors.white,
                        onChanged: (v) => setState(() => _autoLogin = v ?? false),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _autoLogin = !_autoLogin),
                        child: const Text('자동 로그인'),
                      ),
                      const Spacer(),
                      if (_loading)
                        const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                        ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : (){
                        FocusScope.of(context).unfocus();
                        _login();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('로그인', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('회원이 아니라면?'),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => SignupScreen()));
                        },
                        child: const Text(
                          '회원가입',
                          style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}