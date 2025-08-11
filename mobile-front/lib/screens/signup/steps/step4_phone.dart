import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_front/core/constants/colors.dart';

class Step4PhoneScreen extends StatefulWidget {
  final String phone;
  final Function(String) onNext;
  final VoidCallback onBack;

  const Step4PhoneScreen({
    Key? key,
    required this.phone,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<Step4PhoneScreen> createState() => _Step4PhoneScreenState();
}

class _Step4PhoneScreenState extends State<Step4PhoneScreen> {
  late TextEditingController _phoneController;
  bool _isValid = false;

  @override
  void initState() {
    // 키보드 닫기
    Future.delayed(Duration.zero, () {
      FocusScope.of(context).unfocus();
    });
    super.initState();
    _phoneController = TextEditingController(text: widget.phone);
    _phoneController.addListener(_validate);
    _validate();
  }

  void _validate() {
    final text = _phoneController.text;
    setState(() {
      _isValid = text.length == 9 && RegExp(r'^\d{4}-\d{4}$').hasMatch(text);
    });
  }

  void _handleNext() {
    if (_isValid) {
      widget.onNext('010-' + _phoneController.text);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool nextEnabled = _isValid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryBlue),
          onPressed: widget.onBack,
        ),
        centerTitle: true,
        title: Text("회원가입", style: TextStyle(fontSize: 18, color: AppColors.primaryBlue)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text("연락처", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '010 - ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: 24),
                    decoration: InputDecoration(
                      hintText: '0000 - 0000',
                      suffixIcon: _phoneController.text.isNotEmpty
                          ? (_isValid
                          ? Icon(Icons.check, color: Colors.green, size: 20) // ✅ 조건 만족 시 체크 표시
                          : IconButton(
                        icon: Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _phoneController.clear();
                        },
                      ))
                          : null,
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: nextEnabled ? Colors.green : Colors.grey,
                          width: 1,
                        ),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      _PhoneNumberHyphenFormatter(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text("※ 숫자만 입력하세요 (예: 12345678 → 1234-5678)", style: TextStyle(fontSize: 12)),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 4 / 5,
                    backgroundColor: Colors.grey[300],
                    color: AppColors.primaryBlue
                  ),
                ),
                const SizedBox(width: 8),
                const Text("4 / 5"),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: nextEnabled ? _handleNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: nextEnabled ? AppColors.primaryBlue : Colors.grey[300],
                  foregroundColor: Colors.white,
                ),
                child: const Text("다음"),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// 📞 자동 하이픈 포맷터 (입력 시 0000-0000 형태로)
class _PhoneNumberHyphenFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 8) digits = digits.substring(0, 8);

    String formatted = '';
    if (digits.length >= 4) {
      formatted = digits.substring(0, 4) + '-' + digits.substring(4);
    } else {
      formatted = digits;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
