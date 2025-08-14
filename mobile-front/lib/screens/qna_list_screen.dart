import 'package:flutter/material.dart';

const tossBlue = Color(0xFF0064FF);
Color pastel(Color c, [double t = 0.12]) => Color.lerp(Colors.white, c, t)!;

class QnaListScreen extends StatelessWidget {
  const QnaListScreen({super.key});

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    // 실제 데이터로 교체 시 status는 "대기" | "완료"
    final items = List.generate(
      6,
          (i) => (
      '문의 제목 ${i + 1}',
      i.isEven ? '대기' : '완료',
      DateTime.now().subtract(Duration(days: i)),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 문의', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: .5,
      ),
      backgroundColor: const Color(0xFFF7F8FA),

      floatingActionButton: FloatingActionButton.extended(
        // ⚠️ 라우터와의 순환 참조 피하려고 문자열 경로 사용
        onPressed: () => Navigator.pushNamed(context, '/qna/compose'),
        backgroundColor: tossBlue,
        icon: const Icon(Icons.edit),
        label: const Text('문의하기'),
      ),

      body: items.isEmpty
          ? _EmptyState(onTapCompose: () => Navigator.pushNamed(context, '/qna/compose'))
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final e = items[i];
          final status = e.$2; // "대기" | "완료"

          final style = _statusStyle(status);
          return InkWell(
            onTap: () {
              // TODO: 상세 페이지 이동
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 왼쪽 아이콘 (파스텔 블루 통일)
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: pastel(tossBlue, .14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      status == '완료' ? Icons.task_alt_rounded : Icons.forum_rounded,
                      color: tossBlue,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 본문
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.$1,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E1F23),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _StatusChip(
                              label: status,
                              bg: style.bg,
                              text: style.text,
                              icon: style.icon,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _fmtDate(e.$3),
                              style: TextStyle(
                                color: Colors.black.withOpacity(.55),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  _StatusStyle _statusStyle(String status) {
    if (status == '완료') {
      // 완료: 옅은 파스텔
      return _StatusStyle(
        bg: pastel(tossBlue, .08),
        text: tossBlue.withOpacity(.90),
        icon: Icons.task_alt_rounded,
      );
    }
    // 대기: 조금 더 진한 파스텔
    return _StatusStyle(
      bg: pastel(tossBlue, .16),
      text: tossBlue,
      icon: Icons.schedule_rounded,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color bg, text;
  final IconData icon;
  const _StatusChip({
    required this.label,
    required this.bg,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTapCompose;
  const _EmptyState({required this.onTapCompose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum_outlined, size: 64, color: Colors.black26),
            const SizedBox(height: 12),
            const Text(
              '아직 등록된 문의가 없어요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '궁금한 점을 보내주시면 빠르게 도와드릴게요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black.withOpacity(.6)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onTapCompose,
              icon: const Icon(Icons.edit),
              label: const Text('문의 작성'),
            )
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  final Color bg, text;
  final IconData icon;
  _StatusStyle({
    required this.bg,
    required this.text,
    required this.icon,
  });
}
