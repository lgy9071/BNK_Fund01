import 'package:flutter/material.dart';

class QnaComposeScreen extends StatefulWidget {
  const QnaComposeScreen({super.key});

  @override
  State<QnaComposeScreen> createState() => _QnaComposeScreenState();
}

class _QnaComposeScreenState extends State<QnaComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('문의하기')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: '제목'),
                validator: (v) => (v == null || v.isEmpty) ? '제목을 입력하세요' : null,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextFormField(
                  controller: _body,
                  decoration: const InputDecoration(labelText: '내용'),
                  maxLines: null,
                  expands: true,
                  validator: (v) => (v == null || v.isEmpty) ? '내용을 입력하세요' : null,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  // TODO: 서버 전송
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('문의가 접수되었습니다.')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('보내기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}