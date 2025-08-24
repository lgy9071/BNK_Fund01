import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_front/core/services/review_api.dart';
import 'package:mobile_front/core/constants/colors.dart';

class ReviewSummaryModal extends StatefulWidget {
  final ReviewApi api;
  final String fundId;
  const ReviewSummaryModal({super.key, required this.api, required this.fundId});

  @override
  State<ReviewSummaryModal> createState() => _ReviewSummaryModalState();
}

class _ReviewSummaryModalState extends State<ReviewSummaryModal> {
  Future<(SummaryResponseDto, ReviewListResponseDto)>? _future;
  final _dt = DateFormat('yyyy-MM-dd HH:mm:ss'); // ⬅️ 소수점 없는 포맷

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(SummaryResponseDto, ReviewListResponseDto)> _load() async {
    final sum = await widget.api.getSummary(widget.fundId);
    final list = await widget.api.getReviews(widget.fundId, page: 0, size: 200);
    return (sum, list);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (_, ctrl) => FutureBuilder<(SummaryResponseDto, ReviewListResponseDto)>(
        future: _future,
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (sum, list) = snap.data!;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: ListView(
              controller: ctrl,
              children: [
                Row(
                  children: [
                    const Text(
                      '펀드 리뷰',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.fontColor),
                    ),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 6),

                // ───────────── AI 요약 카드
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.primaryBlue.withOpacity(.6), width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 18, color: AppColors.primaryBlue),
                          const SizedBox(width: 6),
                          const Text(
                            'AI 요약',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (sum.status == SummaryStatus.insufficient)
                        Text('아직 요약할 리뷰가 부족합니다 (${sum.activeReviewCount} / 5)',
                            style: const TextStyle(color: Colors.grey))
                      else
                        Text(sum.summaryText ?? '',
                            style: const TextStyle(color: AppColors.fontColor, height: 1.35)),
                      if (sum.lastGeneratedAt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '갱신: ${_dt.format(sum.lastGeneratedAt!)}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ───────────── 전체 리뷰 헤더
                Row(
                  children: [
                    const Text('전체 리뷰', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F3FA),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${list.items.length}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.fontColor, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ───────────── 전체 리뷰 리스트(카드형 타일)
                if (list.items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.rate_review_outlined, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('아직 등록된 리뷰가 없습니다.', style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  )
                else
                  ...list.items.map((r) => _ReviewTile(
                    text: r.text,
                    createdAt: _dt.format(r.createdAt), // ⬅️ 소수점 제거
                  )),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 개별 리뷰 타일 — 라운드 + 연한 테두리 + 여백, 작성일은 우측 하단
class _ReviewTile extends StatelessWidget {
  final String text;
  final String createdAt;
  const _ReviewTile({required this.text, required this.createdAt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Spacer(),
              Text('작성일: $createdAt', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
