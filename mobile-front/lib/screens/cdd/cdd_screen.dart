import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_front/core/services/user_service.dart';

class CddScreen extends StatefulWidget {
  final String? accessToken;
  final UserService? userService;

  const CddScreen({
    super.key,
    this.accessToken,
    this.userService,
  });

  @override
  State<CddScreen> createState() => _CddScreenState();
}

class _CddScreenState extends State<CddScreen> {
  final _formKey = GlobalKey<FormState>();

  // 텍스트 컨트롤러들
  final _rrnController = TextEditingController();
  final _addressController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _occupationController = TextEditingController();
  final _transactionPurposeController = TextEditingController();

  // 드롭다운 선택값들
  String? _selectedIncomeSource;
  String? _selectedRiskLevel;

  // 소득원 선택지
  final List<String> _incomeSources = [
    '급여',
    '사업소득',
    '투자수익',
    '연금',
    '기타'
  ];

  // 위험등급 선택지
  final List<String> _riskLevels = [
    '저위험',
    '중위험',
    '고위험'
  ];

  @override
  void initState() {
    super.initState();
    // 입력값 변경 감지를 위한 리스너 추가
    _rrnController.addListener(_checkFormValidity);
    _addressController.addListener(_checkFormValidity);
    _nationalityController.addListener(_checkFormValidity);
    _occupationController.addListener(_checkFormValidity);
    _transactionPurposeController.addListener(_checkFormValidity);
  }

  @override
  void dispose() {
    _rrnController.dispose();
    _addressController.dispose();
    _nationalityController.dispose();
    _occupationController.dispose();
    _transactionPurposeController.dispose();
    super.dispose();
  }

  // 폼 유효성 검사
  bool _isFormValid() {
    return _rrnController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        _nationalityController.text.isNotEmpty &&
        _occupationController.text.isNotEmpty &&
        _transactionPurposeController.text.isNotEmpty &&
        _selectedIncomeSource != null &&
        _selectedRiskLevel != null;
  }

  void _checkFormValidity() {
    setState(() {
      // 폼 유효성 상태 업데이트
    });
  }

  // CDD 요청 처리
  Future<void> _submitCddRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // CDD 데이터 준비
      final cddData = {
        'rrn': _rrnController.text,
        'address': _addressController.text,
        'nationality': _nationalityController.text,
        'occupation': _occupationController.text,
        'income_source': _selectedIncomeSource,
        'transaction_purpose': _transactionPurposeController.text,
        'risk_level': _selectedRiskLevel,
      };

      // API 호출 (실제 구현 필요)
      // await widget.userService?.submitCddData(cddData);

      // 로딩 다이얼로그 닫기
      Navigator.pop(context);

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CDD 정보가 성공적으로 제출되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );

      // 이전 화면으로 돌아가기
      Navigator.pop(context);

    } catch (e) {
      // 로딩 다이얼로그 닫기
      Navigator.pop(context);

      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CDD 제출 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('고객확인의무(CDD)'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 메시지
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '고객확인의무(CDD) 정보 입력',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '금융서비스 이용을 위해 필요한 정보를 입력해주세요.\n모든 항목은 필수입력사항입니다.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 주민등록번호
              TextFormField(
                controller: _rrnController,
                decoration: const InputDecoration(
                  labelText: '주민등록번호',
                  hintText: '123456-1234567',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '주민등록번호를 입력해주세요.';
                  }
                  // 간단한 형식 검증
                  if (!RegExp(r'^\d{6}-\d{7}$').hasMatch(value)) {
                    return '올바른 주민등록번호 형식으로 입력해주세요.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 주소
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '주소',
                  hintText: '거주지 또는 사업장 주소를 입력해주세요',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '주소를 입력해주세요.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 국적
              TextFormField(
                controller: _nationalityController,
                decoration: const InputDecoration(
                  labelText: '국적',
                  hintText: '예: 대한민국',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '국적을 입력해주세요.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 직업
              TextFormField(
                controller: _occupationController,
                decoration: const InputDecoration(
                  labelText: '직업',
                  hintText: '예: 회사원, 자영업, 학생 등',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '직업을 입력해주세요.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 소득원 (드롭다운)
              DropdownButtonFormField<String>(
                value: _selectedIncomeSource,
                decoration: const InputDecoration(
                  labelText: '소득원',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                items: _incomeSources.map((String source) {
                  return DropdownMenuItem<String>(
                    value: source,
                    child: Text(source),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedIncomeSource = newValue;
                  });
                  _checkFormValidity();
                },
                validator: (value) {
                  if (value == null) {
                    return '소득원을 선택해주세요.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 거래목적
              TextFormField(
                controller: _transactionPurposeController,
                decoration: const InputDecoration(
                  labelText: '거래 목적',
                  hintText: '예: 계좌 개설, 투자, 송금 등',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '거래 목적을 입력해주세요.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 위험등급 (드롭다운)
              DropdownButtonFormField<String>(
                value: _selectedRiskLevel,
                decoration: const InputDecoration(
                  labelText: '위험 등급',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                items: _riskLevels.map((String level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRiskLevel = newValue;
                  });
                  _checkFormValidity();
                },
                validator: (value) {
                  if (value == null) {
                    return '위험 등급을 선택해주세요.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // CDD 요청 버튼
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isFormValid() ? _submitCddRequest : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid() ? Colors.blue : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    _isFormValid() ? 'CDD 정보 제출' : '모든 항목을 입력해주세요',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 개인정보 처리 안내
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Text(
                  '※ 입력하신 개인정보는 고객확인의무(CDD) 이행을 위해 수집·이용되며, 관련 법령에 따라 안전하게 보호됩니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}