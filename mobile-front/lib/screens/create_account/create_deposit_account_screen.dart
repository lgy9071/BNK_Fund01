import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_front/core/constants/api.dart';
import 'package:mobile_front/core/services/user_service.dart';

class CreateDepositAccountScreen extends StatefulWidget {
  final String? accessToken;
  final UserService? userService;

  const CreateDepositAccountScreen({
    super.key,
    this.accessToken,
    this.userService,
  });

  @override
  State<CreateDepositAccountScreen> createState() =>
      _CreateDepositAccountScreenState();
}

class _CreateDepositAccountScreenState extends State<CreateDepositAccountScreen> {
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountPinController = TextEditingController();

  String _userEmail = '';
  int _userId = 0;
  bool _isLoading = false;
  bool _isFormValid = false;

  // 테마 색상
  static const Color primaryColor = Color(0xFF0064FF);

  // api 주소
  final _createDepositAccount = ApiConfig.createDepositAccount;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    // 입력 필드 변경 감지
    _accountNameController.addListener(_validateForm);
    _accountPinController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountPinController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final token = widget.accessToken;
    if (token == null || token.isEmpty) return;

    try {
      final userService =
          widget.userService ?? UserService(); // 기본 UserService 사용
      final userProfile = await userService.getMe(token);
      setState(() {
        _userEmail = userProfile.email;
        _userId = userProfile.userId; // String을 int로 변환
      });
    } catch (e) {
      debugPrint('프로필 로드 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('사용자 정보를 불러올 수 없습니다.')));
      }
    }
  }

  void _validateForm() {
    final accountName = _accountNameController.text.trim();
    final accountPin = _accountPinController.text.trim();

    setState(() {
      // 계좌명은 선택사항이므로 비어있어도 OK
      // PIN은 4자리 숫자만 필수
      _isFormValid =
          accountPin.length == 4 && RegExp(r'^\d{4}$').hasMatch(accountPin);
    });
  }

  Future<bool> _showExitConfirmDialog() async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 경고 아이콘
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade600,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),

                // 제목
                const Text(
                  '계좌 생성 중단',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // 설명 텍스트
                const Text(
                  '계좌 생성을 중단하시겠습니까?\n입력한 정보가 모두 삭제됩니다.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 버튼들
                Row(
                  children: [
                    // 계속 작성 버튼
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false); // 나가지 않음
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: const Text(
                          '계속 작성',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // 나가기 버튼
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(true); // 나가기
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '나가기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false; // null이면 false 반환
  }

  Future<void> _createAccount() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = widget.accessToken;
      if (token == null || token.isEmpty) {
        throw Exception('액세스 토큰이 없습니다.');
      }

      // 계좌명이 비어있으면 기본값 설정
      String accountName = _accountNameController.text.trim();
      if (accountName.isEmpty) {
        // 사용자 이메일에서 이름 부분 추출 (@ 앞부분)
        String userName = _userEmail.split('@')[0];
        accountName = '$userName의 입출금 계좌';
      }

      final requestBody = {
        'userId': _userId, // 이미 int 타입이므로 바로 사용
        'accountName': accountName,
        'pin': _accountPinController.text.trim(),
      };

      final uri = Uri.parse(_createDepositAccount); // 실제 API URL로 변경 필요
      debugPrint('[POST] $uri');
      debugPrint('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('↳ status: ${response.statusCode}');
      debugPrint('↳ response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final accountData = responseData['data'];

          if (mounted) {
            // 성공 메시지와 함께 계좌 정보 표시
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return Dialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 체크 아이콘
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 제목
                        const Text(
                          '계좌 생성 완료',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // 간단한 설명 텍스트
                        const Text(
                          '입출금 계좌가 생성되었습니다.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // 버튼들
                        Row(
                          children: [
                            // 취소 버튼
                            Expanded(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // 다이얼로그만 닫기
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  '취소',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // 계속 진행 버튼
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // 다이얼로그 닫기
                                  Navigator.of(context).pop(); // 이전 화면으로 돌아가기
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  '계속 진행',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        } else {
          throw Exception(responseData['message'] ?? '계좌 생성에 실패했습니다.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? '계좌 생성 실패: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('계좌 생성 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('계좌 생성에 실패했습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _showExitConfirmDialog,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('입출금 계좌 생성'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldExit = await _showExitConfirmDialog();
              if (shouldExit && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),

        // 프레임워크의 자동 밀어올리기 비활성화 (우리가 직접 처리)
        resizeToAvoidBottomInset: false,

        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    // 내용이 적을 때도 화면을 꽉 채워 overflow 방지
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 사용자 정보 표시
                        if (_userEmail.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '사용자 정보',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _userEmail,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // 계좌 이름 입력
                        const Text(
                          '계좌 이름 (선택사항)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '입력하지 않으면 자동으로 설정됩니다',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _accountNameController,
                          decoration: InputDecoration(
                            hintText: '계좌의 별칭을 입력해주세요 (선택사항)',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),

                        const SizedBox(height: 32),

                        // 계좌 비밀번호 입력
                        const Text(
                          '계좌 비밀번호',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _accountPinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: InputDecoration(
                            hintText: '숫자 4자리를 입력해주세요',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            counterText: '',
                          ),
                          style: const TextStyle(fontSize: 16, letterSpacing: 8),
                        ),

                        // 남는 공간을 채워 버튼이 항상 하단에 위치하도록
                        const SizedBox(height: 24),
                        const SizedBox(height: 56), // bottom 버튼 높이만큼 여유 (겹침 방지)
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 하단 버튼: 키보드 높이만큼 자동으로 들어올림
        bottomNavigationBar: SafeArea(
          top: false,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isFormValid && !_isLoading ? _createAccount : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  '계좌 생성',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

