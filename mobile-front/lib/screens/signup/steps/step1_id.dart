import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Step1IdScreen extends StatefulWidget {
  final String userId;
  final Function(String) onNext;

  const Step1IdScreen({
    Key? key,
    required this.userId,
    required this.onNext,
  }) : super(key: key);

  @override
  State<Step1IdScreen> createState() => _Step1IdScreenState();
}

class _Step1IdScreenState extends State<Step1IdScreen> {
  late TextEditingController _usernameController;
  final RegExp _idRegex = RegExp(r'^[a-z][a-zA-Z0-9]{5,14}$');

  bool _isValid = false;
  bool _isDuplicate = false;
  bool _isChecking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.userId);
    _usernameController.addListener(_validateInput);

    // 초기값에 대해 바로 검사 수행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateInput();
    });
  }

  void _validateInput() async {
    final username = _usernameController.text;

    setState(() {
      _isValid = _idRegex.hasMatch(username);
      _errorMessage = null;
      _isDuplicate = false;
    });

    if (_isValid) {
      await _checkDuplicate(username);
    }
  }

  Future<void> _checkDuplicate(String username) async {
    setState(() {
      _isChecking = true;
    });

    try {
      final res = await http.get(
        Uri.parse("http://192.168.100.245:8090/api/check-id?username=$username"),
      );
      print(res.body);
      final data = jsonDecode(res.body);
      setState(() {
        _isDuplicate = data['duplicate'] == true;
        _errorMessage = _isDuplicate ? '이미 사용중인 아이디입니다' : null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '중복 확인 실패';
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _handleNext() {
    if (_isValid && !_isDuplicate) {
      widget.onNext(_usernameController.text); // 부모에게 값 전달
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool nextEnabled = _isValid && !_isDuplicate;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: BackButton(color: Colors.black),
        title: Center(
          child: Text("로고", style: TextStyle(color: Colors.black)),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text("아이디", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextField(
              controller: _usernameController,
              cursorColor: Colors.blue,
              decoration: InputDecoration(
                hintText: "아이디를 입력하세요",
                suffixIcon: _isChecking
                    ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                    : _isValid
                    ? (_isDuplicate
                    ? Icon(Icons.close, color: Colors.red)
                    : Icon(Icons.check, color: Colors.green))
                    : null,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: _isDuplicate
                        ? Colors.red
                        : _isValid
                        ? Colors.blue
                        : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text("※ 6~15자 영문/숫자 조합으로 입력", style: TextStyle(fontSize: 12)),
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
                    value: 1 / 5,
                    backgroundColor: Colors.grey[300],
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                const Text("1 / 5"),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: nextEnabled ? _handleNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: nextEnabled ? Color(0xFF0064FF) : Colors.grey[300],
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
