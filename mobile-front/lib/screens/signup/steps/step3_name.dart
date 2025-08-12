import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/widgets/dismiss_keyboard.dart';

class Step3NameScreen extends StatefulWidget {
  final String name;
  final Function(String) onNext;
  final VoidCallback onBack;

  const Step3NameScreen({
    Key? key,
    required this.name,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<Step3NameScreen> createState() => _Step3NameScreenState();
}

class _Step3NameScreenState extends State<Step3NameScreen> {
  late TextEditingController _nameController;
  final RegExp _nameRegex = RegExp(r'^[가-힣]{2,5}$');

  bool _isValid = false;
  String? _errorMessage;

  @override
  void initState() {
    // 키보드 닫기
    Future.delayed(Duration.zero, () {
      FocusScope.of(context).unfocus();
    });
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _nameController.addListener(_validate);
    _validate();
  }

  void _validate() {
    final name = _nameController.text.trim();
    final valid = _nameRegex.hasMatch(name);

    setState(() {
      _isValid = valid;
      _errorMessage = valid || name.isEmpty ? null : '한글 2~5자로 입력해주세요';
    });
  }

  void _handleNext() {
    if (_isValid) {
      widget.onNext(_nameController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.primaryBlue),
            onPressed: widget.onBack,
          ),
          title: Text("회원가입", style: TextStyle(fontSize: 18, color: AppColors.primaryBlue)),
          centerTitle: true,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text("이름", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                cursorColor: AppColors.primaryBlue,
                decoration: InputDecoration(
                  hintText: "이름을 입력하세요",
                  suffixIcon: SizedBox(
                    height: 24,
                    width: 24,
                    child: _isValid
                        ? Icon(Icons.check, color: Colors.green, size: 20)
                        : null,
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: _isValid ? AppColors.primaryBlue : Colors.red,
                    ),
                  ),
                ),
              ),
      
              const SizedBox(height: 8),
              const Text("※ 한글 2~5자", style: TextStyle(fontSize: 12)),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: 3 / 5,
                      backgroundColor: Colors.grey[300],
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text("3 / 5"),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isValid ? _handleNext : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isValid ? AppColors.primaryBlue : Colors.grey[300],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("다음"),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
