import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';

class Step5EmailScreen extends StatefulWidget {
  final String email;
  final Function(String) onComplete;
  final VoidCallback onBack;

  const Step5EmailScreen({
    Key? key,
    required this.email,
    required this.onComplete,
    required this.onBack,
  }) : super(key: key);

  @override
  State<Step5EmailScreen> createState() => _Step5EmailScreenState();
}

class _Step5EmailScreenState extends State<Step5EmailScreen> {
  final TextEditingController _localPartController = TextEditingController();
  String? _selectedDomain;

  final List<String> _emailDomains = [
    "naver.com",
    "gmail.com",
    "hanmail.net",
    "daum.net",
    "nate.com",
    "kakao.com",
  ];

  bool _isValid = false;

  @override
  void initState() {
    // 키보드 닫기
    Future.delayed(Duration.zero, () {
      FocusScope.of(context).unfocus();
    });
    super.initState();
    if (widget.email.contains("@")) {
      final parts = widget.email.split("@");
      _localPartController.text = parts[0];
      _selectedDomain = parts[1];
    }

    _localPartController.addListener(_validate);
  }

  void _validate() {
    final local = _localPartController.text;
    final domain = _selectedDomain;
    final fullEmail = "$local@$domain";

    final emailRegex = RegExp(r'^[^@]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    setState(() {
      _isValid = domain != null && emailRegex.hasMatch(fullEmail);
    });
  }

  void _handleComplete() {
    final email = "${_localPartController.text}@$_selectedDomain";
    widget.onComplete(email);
  }
  void _showDomainSelector() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // ✅ 여기
          shrinkWrap: true,
          children: _emailDomains.map((domain) {
            return ListTile(
              title: Text(domain),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedDomain = domain;
                  _validate();
                });
              },
            );
          }).toList(),
        );
      },
    );

  }


  @override
  Widget build(BuildContext context) {
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
            const Text("이메일", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _localPartController,
                    keyboardType: TextInputType.emailAddress,
                    cursorColor: AppColors.primaryBlue,
                    decoration: const InputDecoration(
                      hintText: "이메일 입력",
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),

                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text("@", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,),),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: InkWell(
                    onTap: _showDomainSelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_selectedDomain ?? "이메일 리스트", style: TextStyle(fontSize: 18),),
                          Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
                        ],
                      ),
                    ),
                  ),

                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 5 / 5,
                    backgroundColor: Colors.grey[300],
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 8),
                const Text("5 / 5"),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValid ? _handleComplete : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isValid ? AppColors.primaryBlue : Colors.grey[300],
                  foregroundColor: Colors.white,
                ),
                child: const Text("완료"),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
