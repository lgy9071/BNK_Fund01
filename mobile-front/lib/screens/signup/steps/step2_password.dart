import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';

class Step2PasswordScreen extends StatefulWidget {
  final String password;
  final Function(String) onNext;
  final VoidCallback onBack;

  const Step2PasswordScreen({
    Key? key,
    required this.password,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<Step2PasswordScreen> createState() => _Step2PasswordScreenState();
}

class _Step2PasswordScreenState extends State<Step2PasswordScreen> {
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  final RegExp _pwRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*[^a-zA-Z0-9])\S{8,15}$');

  bool _isPwValid = false;
  bool _isMatch = false;
  bool _showPw = false;
  bool _showConfirm = false;

  String? _pwErrorMessage;
  String? _confirmErrorMessage;

  @override
  void initState() {
    // 키보드 닫기
    Future.delayed(Duration.zero, () {
      FocusScope.of(context).unfocus();
    });
    super.initState();
    _pwController.text = widget.password;

    _pwController.addListener(_validate);
    _confirmController.addListener(_validate);
    _validate();
  }

  void _validate() {
    final pw = _pwController.text;
    final confirm = _confirmController.text;

    final isValid = _pwRegex.hasMatch(pw);
    final isSame = pw == confirm && confirm.isNotEmpty;

    setState(() {
      _isPwValid = isValid;
      _isMatch = isSame;

      _pwErrorMessage =
      pw.isEmpty ? null : (isValid ? null : '비밀번호 조건이 맞지 않습니다');
      _confirmErrorMessage =
      isValid && !isSame && confirm.isNotEmpty ? '비밀번호가 일치하지 않습니다' : null;
    });
  }

  void _handleNext() {
    if (_isPwValid && _isMatch) {
      widget.onNext(_pwController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool nextEnabled = _isPwValid && _isMatch;

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
            const Text("비밀번호", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, )),
            const SizedBox(height: 10),
            TextField(
              controller: _pwController,
              obscureText: !_showPw,
              cursorColor: AppColors.primaryBlue,
              decoration: InputDecoration(
                hintText: "비밀번호를 입력하세요",
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _showPw ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPw = !_showPw;
                        });
                      },
                    ),
                    if (_isPwValid)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.check, color: Colors.green),
                      ),
                  ],
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: _isPwValid ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),



            const SizedBox(height: 8),
            const Text("※ 8~15자 (대/소문자/숫자/특수문자 포함)", style: TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            if (_pwErrorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _pwErrorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),

            const SizedBox(height: 24),
            const Text("비밀번호 확인", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmController,
              obscureText: !_showConfirm,
              cursorColor: AppColors.primaryBlue,
              decoration: InputDecoration(
                hintText: "비밀번호를 입력하세요",
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        _showConfirm ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _showConfirm = !_showConfirm;
                        });
                      },
                    ),
                    if (_isMatch)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.check, color: Colors.green),
                      ),
                  ],
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: _isMatch ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ),

            if (_confirmErrorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _confirmErrorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),

            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 2 / 5,
                    backgroundColor: Colors.grey[300],
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 8),
                const Text("2 / 5"),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: nextEnabled ? _handleNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: nextEnabled ? Color(0xFF0064FF) : Colors.grey[300],
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
