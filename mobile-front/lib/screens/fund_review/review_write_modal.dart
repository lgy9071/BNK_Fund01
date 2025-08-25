import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/core/services/review_api.dart';
import 'package:mobile_front/widgets/show_custom_confirm_dialog.dart';

class ReviewWriteModal extends StatefulWidget {
  final ReviewApi api;
  final String fundId;
  final bool isEdit;

  const ReviewWriteModal({
    super.key,
    required this.api,
    required this.fundId,
    this.isEdit = false,
  });

  @override
  State<ReviewWriteModal> createState() => _ReviewWriteModalState();
}

class _ReviewWriteModalState extends State<ReviewWriteModal> {
  final _ctl = TextEditingController();
  int _charCount = 0;
  int _byteCount = 0;

  @override
  void initState() {
    super.initState();
    _ctl.addListener(_onChange);
    if (widget.isEdit) _prefill();
  }

  void _onChange() {
    final s = _ctl.text;
    setState(() {
      _charCount = s.characters.length;
      _byteCount = utf8.encode(s).length;
    });
  }

  Future<void> _prefill() async {
    final list = await widget.api.getReviews(widget.fundId);
    if (list.items.isNotEmpty) {
      _ctl.text = list.items.first.text;
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final trimmed = _ctl.text.trim();
    if (trimmed.isEmpty) {
      await showAppConfirmDialog(
        context: context,
        title: '안내',
        message: '리뷰를 입력해주세요.',
        showCancel: false,
      );
      return;
    }
    if (_charCount > 100) {
      await showAppConfirmDialog(
        context: context,
        title: '안내',
        message: '리뷰는 최대 100자까지 가능합니다.',
        showCancel: false,
      );
      return;
    }

    final ok = await showAppConfirmDialog(
      context: context,
      title: widget.isEdit ? '수정' : '작성',
      message: widget.isEdit ? '이 내용으로 수정할까요?' : '이 내용으로 작성할까요?',
      confirmText: widget.isEdit ? '수정' : '작성',
    );
    if (ok != true) return;

    if (widget.isEdit) {
      final list = await widget.api.getReviews(widget.fundId);
      if (list.items.isEmpty) return;
      final my = list.items.first;
      await widget.api.update(widget.fundId, my.reviewId, trimmed);
    } else {
      await widget.api.create(widget.fundId, trimmed);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit ? '리뷰 수정' : '리뷰 작성';

    return Padding(
      // 키보드 높이만큼 올림
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: ListView(
            controller: ctrl,
            children: [
              // 상단 헤더
              Row(
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 4),

              // 글자/바이트 카운트
              Text('최대 100자 • 현재: $_charCount자 / $_byteCount bytes',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),

              // 입력창
              TextField(
                controller: _ctl,
                minLines: 4,
                maxLines: 6,
                maxLength: 100, // UI 차단
                decoration: InputDecoration(
                  hintText: '한줄평을 입력하세요',
                  border: const OutlineInputBorder(), // 기본 테두리
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                    BorderSide(color: Colors.grey.shade400, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: AppColors.primaryBlue, width: 1.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  counterText: '', // 아래 카운터 숨김
                ),
              ),
              const SizedBox(height: 12),

              // 작성/수정 버튼
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submit,
                child: Text(
                  widget.isEdit ? '수정 완료' : '작성 완료',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
