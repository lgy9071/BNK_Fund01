import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_front/core/constants/api.dart';
import 'package:mobile_front/utils/exit_guard.dart';
import 'package:mobile_front/widgets/dismiss_keyboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_front/screens/main_scaffold.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/screens/signup/signup_screen.dart';
import 'package:mobile_front/main.dart';

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

  String cleanToken(String? t) {
    if (t == null) return '';
    return t
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF\u00A0]'), '')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
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
      final res = await http
          .post(
        Uri.parse(_loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': id,
          'password': pw,
          'autoLogin': _autoLogin,
        }),
      )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        debugPrint('[LOGIN RAW] ${res.body}');
        final Map<String, dynamic> body = jsonDecode(res.body);

        // camelCase / snake_case 모두 대응
        String access = cleanToken(
          (body['accessToken'] ?? body['access_token']) as String?,
        );
        String refresh = cleanToken(
          (body['refreshToken'] ?? body['refresh_token']) as String?,
        );

        // 방어: 만약 서버에서 autoLogin=true일 때 access가 비어온다면 즉시 회전 호출(안 올 상황은 거의 없지만 안전망)
        if (access.isEmpty && _autoLogin && refresh.isNotEmpty) {
          final rotated = await _refreshRotate(refresh);
          access = rotated.$1;
          refresh = rotated.$2;
        }

        if (access.isEmpty) {
          _toast('로그인 실패: 액세스 토큰이 없습니다.');
          return;
        }

        // 저장
        await _secure.write(key: 'accessToken', value: access);
        if (_autoLogin && refresh.isNotEmpty) {
          await _secure.write(key: 'refreshToken', value: refresh);
        } else {
          await _secure.delete(key: 'refreshToken');
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAutoLogin', _autoLogin);

        sessionManager.setAutoLogin(_autoLogin);
        sessionManager.start();

        if (!mounted) return;

        // ✅ 옵션 B: 항상 MainScaffold 내부에서 토큰을 읽도록 통일
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScaffold()),
              (_) => false,
        );
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

  /// /refresh 회전 호출 (성공 시 새 access, 새 refresh 반환; 실패 시 ('',''))
  Future<(String, String)> _refreshRotate(String refreshToken) async {
    try {
      final resp = await http
          .post(
        Uri.parse(ApiConfig.refresh),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final m = jsonDecode(resp.body) as Map<String, dynamic>;
        final newAt = cleanToken((m['accessToken'] ?? m['access_token']) as String?);
        final newRt = cleanToken((m['refreshToken'] ?? m['refresh_token']) as String?);

        if (newAt.isNotEmpty) {
          await _secure.write(key: 'accessToken', value: newAt);
        }
        if (newRt.isNotEmpty) {
          await _secure.write(key: 'refreshToken', value: newRt);
        }
        return (newAt, newRt);
      } else {
        debugPrint('[REFRESH] http ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('[REFRESH] error: $e');
    }
    return ('', '');
  }

  void _toast(String msg) {
    final ctx = context;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: ExitGuard(
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
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                          ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () {
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
      ),
    );
  }
}
