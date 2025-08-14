import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 색상 유틸(필요 시 공용 constants로 이동해도 OK)
const tossBlue = Color(0xFF0064FF);
Color pastel(Color c, [double t = 0.12]) => Color.lerp(Colors.white, c, t)!;

class QnaComposeScreen extends StatefulWidget {
  const QnaComposeScreen({super.key});

  @override
  State<QnaComposeScreen> createState() => _QnaComposeScreenState();
}

class _QnaComposeScreenState extends State<QnaComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();

  static const int _titleMax = 50;
  static const int _bodyMax = 1000;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
          _title.text.trim().isNotEmpty &&
          _body.text.trim().isNotEmpty &&
          _title.text.trim().length <= _titleMax &&
          _body.text.trim().length <= _bodyMax;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    // TODO: 서버 전송
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('문의가 접수되었습니다.')),
    );
    Navigator.pop(context);
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: pastel(tossBlue, .08), // 파스텔 블루 배경
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: tossBlue, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: tossBlue, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: tossBlue, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('문의하기', style: TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: .5,
        ),
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
              children: [
                const Text(
                  '어떤 점이 궁금하세요?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1F23),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '문의 제목과 내용을 자세히 적어주세요. 캡처나 오류 메시지가 있다면 함께 남겨주시면 더 빨라요.',
                  style: TextStyle(color: Colors.black.withOpacity(.65), height: 1.4),
                ),
                const SizedBox(height: 18),

                // 제목
                TextFormField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  maxLength: _titleMax,
                  decoration: _fieldDecoration('제목', hint: '예) 펀드 가입 오류 문의'),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return '제목을 입력하세요';
                    if (t.length > _titleMax) return '제목은 $_titleMax자 이내로 작성해주세요';
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_title.text.trim().length}/$_titleMax',
                    style: TextStyle(color: Colors.black.withOpacity(.45)),
                  ),
                ),
                const SizedBox(height: 12),

                // 내용
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 220),
                  child: TextFormField(
                    controller: _body,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    maxLines: null,
                    maxLength: _bodyMax,
                    inputFormatters: [LengthLimitingTextInputFormatter(_bodyMax)],
                    decoration: _fieldDecoration(
                      '내용',
                      hint: '상세한 상황, 재현 방법, 오류 메시지 등을 적어주세요.',
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return '내용을 입력하세요';
                      if (t.length > _bodyMax) return '내용은 $_bodyMax자 이내로 작성해주세요';
                      return null;
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_body.text.trim().length}/$_bodyMax',
                    style: TextStyle(color: Colors.black.withOpacity(.45)),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 하단 전송 바
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              height: 48,
              child: FilledButton.icon(
                icon: _submitting
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.send_rounded),
                onPressed: _canSubmit ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: tossBlue,
                  disabledBackgroundColor: const Color(0xFFBFD6FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: Text(
                  _submitting ? '보내는 중...' : '보내기',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
