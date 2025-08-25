import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_front/core/services/qna_api.dart';

const tossBlue = Color(0xFF0064FF);
const successGreen = Color(0xFF16A34A);
Color pastel(Color c, [double t = .12]) => Color.lerp(Colors.white, c, t)!;

// 입력창 배경: 흐린 하얀색(배경과 은은하게 구분)
const inputBg = Color(0xFFF7F9FC);

class QnaComposeScreen extends StatefulWidget {
  final String baseUrl;
  final String accessToken;

  const QnaComposeScreen({
    super.key,
    required this.baseUrl,
    required this.accessToken,
  });

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

  late final QnaApi _api;

  @override
  void initState() {
    super.initState();
    _api = QnaApi(baseUrl: widget.baseUrl, accessToken: widget.accessToken);
  }

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
    try {
      await _api.create(title: _title.text.trim(), content: _body.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문의가 접수되었습니다.'), behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('전송 실패: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // 아이콘 제거 & 배경만 흐린 하얀색으로 변경
  InputDecoration _dec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey), // 👈 여전히 가능
      // prefixIcon 제거
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: tossBlue, width: 1.6),
      ),
    );
  }

  Widget _headlineCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E8EC)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFDBEAFE),
            child: Icon(Icons.support_agent, color: tossBlue),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '빠르게 도와드릴게요!\n상황/재현방법/오류 메시지를 적어주시면 더 빨라요.',
              style: TextStyle(fontWeight: FontWeight.w700, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainTitle = (_titleMax - _title.text.trim().length).clamp(0, _titleMax);
    final remainBody = (_bodyMax - _body.text.trim().length).clamp(0, _bodyMax);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('새 문의', style: TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: .5,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              _headlineCard(),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                onChanged: () => setState(() {}),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('제목', style: TextStyle(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text('$remainTitle / $_titleMax',
                            style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _title,
                      textInputAction: TextInputAction.next,
                      maxLength: _titleMax,
                      decoration: _dec('제목을 입력하세요'),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return '제목을 입력하세요';
                        if (t.length > _titleMax) return '제목은 $_titleMax자 이내로 작성해주세요';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text('내용', style: TextStyle(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text('$remainBody / $_bodyMax',
                            style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _body,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      maxLines: null,
                      minLines: 8,
                      maxLength: _bodyMax,
                      inputFormatters: [LengthLimitingTextInputFormatter(_bodyMax)],
                      decoration: _dec('상세한 상황을 적어주세요'),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return '내용을 입력하세요';
                        if (t.length > _bodyMax) return '내용은 $_bodyMax자 이내로 작성해주세요';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
              height: 52,
              // 아이콘 없는 순수 텍스트 버튼
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tossBlue,
                  disabledBackgroundColor: const Color(0xFFBFD6FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _submitting ? '보내는 중...' : '보내기',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 19),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
