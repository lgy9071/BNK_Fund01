import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_front/core/services/user_service.dart';

class CddScreen extends StatefulWidget {
  final String? accessToken; // 액세스 토큰
  final UserService? userService; // 사용자 서비스

  const CddScreen({super.key, this.accessToken, this.userService});

  @override
  State<CddScreen> createState() => _CddScreenState();
}

class _CddScreenState extends State<CddScreen> {
  // 사용자 정보
  String? userId; // 토큰에서 추출한 사용자 ID (String으로 변환해서 저장)
  bool isLoading = true; // 초기 로딩 상태
  // 메인 테마 색상
  static const Color primaryColor = Color(0xFF0064FF);

  // 현재 단계 (0부터 시작)
  int currentStep = 0;

  // 총 단계 수
  final int totalSteps = 6;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  // 사용자 정보 초기화
  Future<void> _initializeUserData() async {
    // 디버깅을 위한 로그 추가
    debugPrint(
      'CddScreen - accessToken: ${widget.accessToken != null ? "있음" : "없음"}',
    );
    debugPrint(
      'CddScreen - userService: ${widget.userService != null ? "있음" : "없음"}',
    );

    try {
      if (widget.accessToken != null) {
        debugPrint('CddScreen - 사용자 정보 요청 시작');

        // UserService 인스턴스 생성 (주입받은 것이 있으면 사용, 없으면 새로 생성)
        final svc = widget.userService ?? UserService();
        final me = await svc.getMe(widget.accessToken!);

        debugPrint('CddScreen - 사용자 정보 요청 성공: userId=${me.userId}');

        setState(() {
          userId = me.userId.toString(); // int를 String으로 변환해서 저장
          isLoading = false;
        });
      } else {
        // 토큰이 없는 경우 에러 처리
        debugPrint('CddScreen - 액세스 토큰이 null입니다');
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('액세스 토큰이 필요합니다.')));
        }
      }
    } catch (e) {
      debugPrint('CddScreen - 사용자 정보 로딩 실패: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('사용자 정보 로딩 실패: $e')));
      }
    }
  }

  // 주민등록번호 컨트롤러들 (앞자리, 뒷자리)
  final TextEditingController ssnFrontController = TextEditingController();
  final TextEditingController ssnBackController = TextEditingController();
  final FocusNode ssnFrontFocusNode = FocusNode();
  final FocusNode ssnBackFocusNode = FocusNode();

  // 기타 입력 필드 컨트롤러들
  final TextEditingController addressController = TextEditingController();
  final TextEditingController jobController = TextEditingController();

  // 라디오 버튼 값들
  String? nationality; // 국적 (domestic/foreign)
  String? incomeSource; // 소득원
  String? transactionPurpose; // 거래목적

  @override
  void dispose() {
    // 메모리 해제
    ssnFrontController.dispose();
    ssnBackController.dispose();
    ssnFrontFocusNode.dispose();
    ssnBackFocusNode.dispose();
    addressController.dispose();
    jobController.dispose();
    super.dispose();
  }

  // 다음 단계로 이동
  void nextStep() {
    if (currentStep < totalSteps - 1) {
      setState(() {
        currentStep++;
      });
    }
  }

  // 이전 단계로 이동
  void previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  // 현재 단계 검증
  bool isCurrentStepValid() {
    switch (currentStep) {
      case 0: // 주민등록번호
        return ssnFrontController.text.length == 6 &&
            ssnBackController.text.length == 7;
      case 1: // 주소
        return addressController.text.isNotEmpty;
      case 2: // 국적
        return nationality != null;
      case 3: // 직업
        return jobController.text.isNotEmpty;
      case 4: // 소득원
        return incomeSource != null;
      case 5: // 거래목적
        return transactionPurpose != null;
      default:
        return false;
    }
  }

  // 모든 필드가 입력되었는지 확인
  bool isAllFieldsValid() {
    return ssnFrontController.text.length == 6 &&
        ssnBackController.text.length == 7 &&
        addressController.text.isNotEmpty &&
        nationality != null &&
        jobController.text.isNotEmpty &&
        incomeSource != null &&
        transactionPurpose != null;
  }

  // CDD 요청 전송
  Future<void> submitCDDRequest() async {
    if (!isAllFieldsValid()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('모든 필드를 입력해주세요.')));
      return;
    }

    try {
      // 주민등록번호 조합 (수정된 버전)
      String socialSecurityNumber =
          '${ssnFrontController.text}-${ssnBackController.text}';

      // 백엔드로 전송할 데이터 구성
      Map<String, dynamic> requestData = {
        'userId': int.parse(userId!), // String을 int로 변환
        'socialSecurityNumber': socialSecurityNumber,
        'address': addressController.text,
        'nationality': nationality,
        'job': jobController.text,
        'incomeSource': incomeSource,
        'transactionPurpose': transactionPurpose,
      };

      print('CDD 요청 데이터: $requestData'); // 디버깅용

      // HTTP 요청 (실제 백엔드 구현 시 주석 해제)
      /*
      final response = await http.post(
        Uri.parse('YOUR_BASE_URL/cdd/request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        // 성공 처리
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CDD 요청이 성공적으로 전송되었습니다.')),
        );
        Navigator.pop(context);
      } else {
        // 에러 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('요청 실패: ${response.statusCode}')),
        );
      }
      */

      // 임시로 성공 메시지 표시
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('CDD 요청이 성공적으로 전송되었습니다.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중이거나 userId가 없는 경우
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('사용자 신원 확인'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );
    }

    if (userId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('사용자 신원 확인'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('액세스 토큰이 필요합니다.', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('사용자 신원 확인'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 진행률 표시바
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${currentStep + 1} / $totalSteps'),
                      Text(_getStepTitle()),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (currentStep + 1) / totalSteps,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // 메인 컨텐츠
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStepContent(),
              ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildBottomButtons(),
            ),
          ],
        ),
      ),
    );
  }

  // 현재 단계 제목 반환
  String _getStepTitle() {
    switch (currentStep) {
      case 0: return '주민등록번호';
      case 1: return '주소';
      case 2: return '국적';
      case 3: return '직업';
      case 4: return '소득원';
      case 5: return '거래목적';
      default: return '';
    }
  }

  // 현재 단계에 맞는 컨텐츠 빌드
  Widget _buildCurrentStepContent() {
    switch (currentStep) {
      case 0: return _buildSSNStep();
      case 1: return _buildAddressStep();
      case 2: return _buildNationalityStep();
      case 3: return _buildJobStep();
      case 4: return _buildIncomeSourceStep();
      case 5: return _buildTransactionPurposeStep();
      default: return Container();
    }
  }

  // 1단계: 주민등록번호 입력
  Widget _buildSSNStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Text(
          '본인확인을 위한 주민등록번호를\n입력해주세요',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        const Text(
          '주민등록번호',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            // 앞자리 입력 필드 (6자리)
            Expanded(
              flex: 3,
              child: TextField(
                controller: ssnFrontController,
                focusNode: ssnFrontFocusNode,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(fontSize: 18, letterSpacing: 2),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                  counterText: '', // 글자 수 카운터 숨김
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (value) {
                  // 6자리가 모두 입력되면 뒷자리로 포커스 이동
                  if (value.length == 6) {
                    ssnBackFocusNode.requestFocus();
                  }
                },
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(' - ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),

            // 뒷자리 입력 필드 (7자리, 전체 숨김 처리)
            Expanded(
              flex: 3,
              child: TextField(
                controller: ssnBackController,
                focusNode: ssnBackFocusNode,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 7,
                style: const TextStyle(fontSize: 18, letterSpacing: 2),
                obscureText: true, // 전체를 숨김 처리
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey, width: 1),
                  ),
                  counterText: '', // 글자 수 카운터 숨김
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2단계: 주소 입력
  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Text(
          '거주하고 계신 주소를\n입력해주세요',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        const Text(
          '주소',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: addressController,
          decoration: const InputDecoration(
            hintText: '주소를 입력해주세요',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryColor),
            ),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  // 3단계: 국적 선택
  Widget _buildNationalityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Text(
          '국적을 선택해주세요',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        const Text(
          '국적',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        _buildRadioOption('domestic', '국내', nationality, (value) {
          setState(() {
            nationality = value;
          });
        }),
        _buildRadioOption('foreign', '국외', nationality, (value) {
          setState(() {
            nationality = value;
          });
        }),
      ],
    );
  }

  // 4단계: 직업 입력
  Widget _buildJobStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Text(
          '현재 직업을 입력해주세요',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        const Text(
          '직업',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: jobController,
          decoration: const InputDecoration(
            hintText: '직업을 입력해주세요',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  // 5단계: 소득원 선택
  Widget _buildIncomeSourceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Text(
          '주요 소득원을 선택해주세요',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        const Text(
          '소득원',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        _buildRadioOption('salary', '급여', incomeSource, (value) {
          setState(() {
            incomeSource = value;
          });
        }),
        _buildRadioOption('business', '사업소득', incomeSource, (value) {
          setState(() {
            incomeSource = value;
          });
        }),
        _buildRadioOption('investment', '투자수익', incomeSource, (value) {
          setState(() {
            incomeSource = value;
          });
        }),
        _buildRadioOption('pension', '연금', incomeSource, (value) {
          setState(() {
            incomeSource = value;
          });
        }),
        _buildRadioOption('other', '기타', incomeSource, (value) {
          setState(() {
            incomeSource = value;
          });
        }),
      ],
    );
  }

  // 6단계: 거래목적 선택
  Widget _buildTransactionPurposeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Text(
          '거래목적을 선택해주세요',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 40),
        const Text(
          '거래목적',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        _buildRadioOption('investment', '투자', transactionPurpose, (value) {
          setState(() {
            transactionPurpose = value;
          });
        }),
        _buildRadioOption('savings', '저축', transactionPurpose, (value) {
          setState(() {
            transactionPurpose = value;
          });
        }),
        _buildRadioOption('pension', '연금', transactionPurpose, (value) {
          setState(() {
            transactionPurpose = value;
          });
        }),
        _buildRadioOption('education', '교육자금', transactionPurpose, (value) {
          setState(() {
            transactionPurpose = value;
          });
        }),
        _buildRadioOption('etc', '기타', transactionPurpose, (value) {
          setState(() {
            transactionPurpose = value;
          });
        }),
      ],
    );
  }

  // 라디오 버튼 옵션 위젯
  Widget _buildRadioOption(String value, String title, String? groupValue, Function(String?) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: groupValue == value ? primaryColor : Colors.grey[300]!,
          width: groupValue == value ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<String>(
        title: Text(title),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: primaryColor,
      ),
    );
  }

  // 하단 버튼들
  Widget _buildBottomButtons() {
    if (currentStep == totalSteps - 1) {
      // 마지막 단계: 제출 버튼
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isCurrentStepValid() ? submitCDDRequest : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            '완료',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    } else {
      // 일반 단계: 다음/이전 버튼
      return Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: Container(
                height: 50,
                margin: const EdgeInsets.only(right: 10),
                child: OutlinedButton(
                  onPressed: previousStep,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '이전',
                    style: TextStyle(color: primaryColor, fontSize: 16),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Container(
              height: 50,
              child: ElevatedButton(
                onPressed: isCurrentStepValid() ? nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '다음',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}
