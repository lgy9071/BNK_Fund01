import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_front/core/constants/api.dart';
import 'package:mobile_front/core/routes/routes.dart';
import 'package:mobile_front/core/services/user_service.dart';
import 'package:mobile_front/widgets/common_loading_button.dart';
import '../../core/constants/colors.dart';


class OptScreen extends StatefulWidget {
  final String? accessToken;      // ← 추가 필요
  final UserService? userService; // ← 추가 필요

  const OptScreen({
    super.key,
    this.accessToken,
    this.userService,
  });

  @override
  State<OptScreen> createState() => _OptScreenState();
}

class _OptScreenState extends State<OptScreen> {
  final _formKey = GlobalKey<FormState>();

  // OTP 위젯 키와 현재 OTP 값
  final GlobalKey<_OtpInputFieldsState> _otpKey = GlobalKey<_OtpInputFieldsState>();
  String _currentOtp = '';

  bool _isRequestingOtp = false;
  bool _isVerifyingOtp = false;
  bool _otpSent = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  String? _userEmail; // ✅ 추가: 토큰에서 추출한 이메일 저장

  final _otpRequest = ApiConfig.otpRequest;
  final _otpVerify = ApiConfig.otpVerify;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ✅ 추가: 화면 로드 시 사용자 이메일 미리 가져오기 (선택사항)
  @override
  void initState() {
    super.initState();
    _preloadUserEmail(); // 미리 이메일을 가져와서 화면에 표시
  }

  // otp 요청
  Future<void> _requestOtp() async {
    setState(() => _isRequestingOtp = true);

    try {
      // 토큰 확인
      final token = widget.accessToken;
      if (token == null || token.isEmpty) {
        _showSnackBar('로그인이 필요합니다.');
        return;
      }

      // ✅ 수정: getMe()를 사용해서 사용자 정보 및 이메일 추출
      final userService = widget.userService ?? UserService();
      final userProfile = await userService.getMe(token);
      final email = userProfile.email; // ✅ 수정: UserProfile에서 이메일 추출

      setState(() {
        _userEmail = email; // 추출한 이메일 저장
      });

      // OTP 요청 API 호출
      final response = await http.post(
        Uri.parse(_otpRequest),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}), // 추출한 이메일 사용
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _otpSent = true;
          _remainingSeconds = 180; // 3분 = 180초
        });
        _startTimer();
        _showSnackBar(data['message'], isError: false);
      } else {
        _showSnackBar(data['message'] ?? '인증번호 요청에 실패했습니다.');
      }
    } catch (e) {
      _showSnackBar('네트워크 오류가 발생했습니다: $e');
    } finally {
      setState(() => _isRequestingOtp = false);
    }
  }

  // otp 인증
  Future<void> _verifyOtp() async {
    if (_currentOtp.length != 6) {
      _showSnackBar('인증번호 6자리를 모두 입력해주세요.');
      return;
    }

    if (_userEmail == null) {
      _showSnackBar('이메일 정보를 찾을 수 없습니다.');
      return;
    }

    setState(() => _isVerifyingOtp = true);

    try {
      final response = await http.post(
        Uri.parse(_otpVerify),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _userEmail!,
          'otp': _currentOtp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _showSnackBar(data['message'], isError: false);
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          // ✅ 수정: 동적 라우터로 CDD 화면으로 이동
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.cdd,
            arguments: {
              'accessToken': widget.accessToken,
              'userService': widget.userService,
            },
          );
        }
      } else {
        _showSnackBar(data['message'] ?? '인증에 실패했습니다.');
        _otpKey.currentState?.clearAll();
        _currentOtp = '';
      }
    } catch (e) {
      _showSnackBar('네트워크 오류가 발생했습니다.');
    } finally {
      setState(() => _isVerifyingOtp = false);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _otpSent = false;
          _otpKey.currentState?.clearAll();
          _currentOtp = '';
        }
      });
    });
  }

  // 스낵바 표시
  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _preloadUserEmail() async {
    final token = widget.accessToken;
    if (token == null || token.isEmpty) return;

    try {
      final userService = widget.userService ?? UserService();
      final userProfile = await userService.getMe(token);
      setState(() {
        _userEmail = userProfile.email;
      });
    } catch (e) {
      debugPrint('Failed to preload user email: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('사용자 신원 확인'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        // foregroundColor: AppColors.fontColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // 제목 및 설명
                const Center(
                  child: Icon(
                    Icons.security,
                    size: 80,
                    color: Color(0xFF0064FF),
                  ),
                ),
                const SizedBox(height: 24),

                const Center(
                  child: Text(
                    '사용자 신원 확인',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.fontColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Center(
                  child: Text(
                    'OTP 인증을 통해 본인 확인을 진행합니다.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.fontColor.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),

                // ✅ 수정: 사용자 이메일 표시 (미리 로드된 경우)
                if (_userEmail != null) ...[
                  const Text(
                    '인증 이메일',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.fontColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade100,
                    ),
                    child: Text(
                      _userEmail!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.fontColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // OTP 요청 버튼
                CommonLoadingButton(
                  text: '인증번호 요청',
                  padding: EdgeInsets.symmetric(vertical: 12),
                  onPressed: _requestOtp,
                  isLoading: _isRequestingOtp,
                ),
                /*
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _otpSent ? null : (_isRequestingOtp ? null : _requestOtp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0064FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: _isRequestingOtp
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      _otpSent ? '인증번호 전송됨' : '인증번호 요청',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                */

                // OTP 입력 섹션 (인증번호 전송 후에만 표시)
                if (_otpSent) ...[
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '인증번호 (6자리)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.fontColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _remainingSeconds > 60
                              ? const Color(0xFF0064FF).withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _formatTime(_remainingSeconds),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _remainingSeconds > 60
                                ? const Color(0xFF0064FF)
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 새로운 OTP 입력 필드
                  _OtpInputFields(
                    key: _otpKey,
                    onCompleted: (otp) {
                      setState(() {
                        _currentOtp = otp;
                      });
                    },
                    onChanged: () {
                      setState(() {
                        final currentOtp = _otpKey.currentState?._controllers.map((c) => c.text).join() ?? '';
                        _currentOtp = currentOtp;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // 인증 확인 버튼
                  CommonLoadingButton(
                    text: '인증 확인',
                    padding: EdgeInsets.symmetric(vertical: 12),
                    onPressed: _remainingSeconds > 0 && !_isVerifyingOtp && _currentOtp.length == 6 ? _verifyOtp : null,
                    isLoading: _isVerifyingOtp,
                  ),
                  /*
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      // 6자리 모두 입력되어야만 버튼 활성화
                      onPressed: _remainingSeconds > 0 && !_isVerifyingOtp && _currentOtp.length == 6 ? _verifyOtp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0064FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _isVerifyingOtp
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        '인증 확인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  */
                  const SizedBox(height: 16),

                  // 재전송 버튼
                  Center(
                    child: TextButton(
                      onPressed: _remainingSeconds == 0 ? _requestOtp : null,
                      child: Text(
                        _remainingSeconds > 0 ? '인증번호 재전송' : '인증번호 재전송',
                        style: TextStyle(
                          color: _remainingSeconds == 0
                              ? const Color(0xFF0064FF)
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // 안내 문구
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0064FF).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0064FF).withOpacity(0.2),
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📌 인증 안내',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.fontColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• 인증번호는 6자리 숫자로 구성됩니다\n'
                              '• 인증번호 유효시간은 3분입니다\n'
                              '• 시간 초과 시 재전송을 눌러주세요',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.fontColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}











// 6자리 개별 입력 위젯
class _OtpInputFields extends StatefulWidget {
  final Function(String) onCompleted;
  final VoidCallback onChanged;

  const _OtpInputFields({
    required this.onCompleted,
    required this.onChanged, required GlobalKey<_OtpInputFieldsState> key,
  });

  @override
  State<_OtpInputFields> createState() => _OtpInputFieldsState();
}

class _OtpInputFieldsState extends State<_OtpInputFields> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      // 다음 필드로 이동
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // 마지막 필드면 키보드 숨기기
        FocusScope.of(context).unfocus();
      }
    }

    // ✅ 수정: onChanged를 먼저 호출하여 _currentOtp 업데이트
    widget.onChanged();

    // ✅ 수정: 그 다음에 6자리 완성 여부 확인
    final otpCode = _controllers.map((c) => c.text).join();
    if (otpCode.length == 6) {
      widget.onCompleted(otpCode);
    }
  }

  void _onKeyPressed(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        // 현재 필드가 비어있고 백스페이스를 누르면 이전 필드로 이동
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void clearAll() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 45,
          height: 55,
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (event) => _onKeyPressed(event, index),
            child: TextFormField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0064FF), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                // ✅ 텍스트 중앙 정렬을 위해 패딩 제거
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => _onChanged(value, index),
            ),
          ),
        );
      }),
    );
  }
}
