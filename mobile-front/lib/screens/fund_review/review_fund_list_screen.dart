import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/core/services/review_api.dart';
import 'package:mobile_front/screens/fund_review/review_view_modal.dart';
import 'package:mobile_front/screens/fund_review/review_write_modal.dart';
import 'package:mobile_front/widgets/show_custom_confirm_dialog.dart';


class ReviewFundListScreen extends StatefulWidget {
  final ReviewApi api;
  final List<HoldingFundDto> funds;
  const ReviewFundListScreen({super.key, required this.api, required this.funds});

  @override
  State<ReviewFundListScreen> createState() => _ReviewFundListScreenState();
}

class _ReviewFundListScreenState extends State<ReviewFundListScreen> {
  Future<void> _refreshFlags() async {
    // 서버 eligibility로 미작성/작성 플래그 갱신
    for (final f in widget.funds) {
      final can = await widget.api.canWrite(f.fundId);
      if (can) {
        f.alreadyWritten = false;
        f.editCount = null;
      } else {
        // 본인 리뷰 editCount 추출
        final list = await widget.api.getReviews(f.fundId);
        if (list.items.isNotEmpty) {
          final my = list.items.first; // 서버가 본인 리뷰 포함
          f.alreadyWritten = true;
          f.editCount = my.editCount;
        }
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // 첫 진입 시 플래그 동기화
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshFlags());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('리뷰 작성/관리', style: TextStyle(color: AppColors.fontColor),),
          centerTitle: true,
          backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshFlags,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: widget.funds.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final f = widget.funds[i];
            return Card(
              color: Colors.white, // ✅ 카드 배경 흰색 고정
              surfaceTintColor: Colors.white, // ✅ Material3 틴트 제거
              elevation: 0.6, // ✅ 살짝 그림자 (더 깔끔)
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.primaryBlue.withOpacity(0.6), width: 1), // ✅ 연한 테두리
              ),
              child: ListTile(
                title: Text(f.fundName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('\n${f.fundId}'),
                onTap: () async {
                  // 내 리뷰 보기 모달
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                    builder: (_) => ReviewViewModal(api: widget.api, fundId: f.fundId),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!f.alreadyWritten)
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                        onPressed: () async {
                          final ok = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                            builder: (_) => ReviewWriteModal(api: widget.api, fundId: f.fundId),
                          );
                          if (ok == true) await _refreshFlags();
                        },
                        child: const Text('리뷰작성', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),),
                      ),
                    if (f.alreadyWritten) ...[
                      IconButton(
                        tooltip: (f.editCount ?? 0) >= 1 ? '수정 불가(1회 사용됨)' : '수정',
                        onPressed: (f.editCount ?? 0) >= 1 ? null : () async {
                          final ok = await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                            builder: (_) => ReviewWriteModal(
                                api: widget.api, fundId: f.fundId, isEdit: true),
                          );
                          if (ok == true) await _refreshFlags();
                        },
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        tooltip: '삭제',
                        onPressed: () async {
                          final confirm = await showAppConfirmDialog(
                            context: context,
                            title: '삭제',
                            message: '정말 이 리뷰를 삭제하시겠어요?',
                            confirmText: '삭제',
                          );
                          if (confirm == true) {
                            // 본인 리뷰 id 찾아 삭제
                            final list = await widget.api.getReviews(f.fundId);
                            if (list.items.isNotEmpty) {
                              final my = list.items.first;
                              await widget.api.delete(f.fundId, my.reviewId);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('삭제 완료')));
                                await _refreshFlags();
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
