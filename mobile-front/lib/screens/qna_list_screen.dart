import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:mobile_front/core/routes/routes.dart';

const tossBlue = Color(0xFF0064FF);
Color pastel(Color c, [double t = .16]) => Color.lerp(Colors.white, c, t)!;

class QnaListScreen extends StatefulWidget {
  const QnaListScreen({super.key});

  @override
  State<QnaListScreen> createState() => _QnaListScreenState();
}

class _QnaListScreenState extends State<QnaListScreen> {
  final _q = TextEditingController();
  String _status = '전체'; // '전체' | '대기' | '완료'

  static const _pageSize = 5;
  int _page = 1;

  // demo data
  final List<({String title, String status, DateTime date})> _all = List.generate(
    20,
        (i) => (
    title: '문의 제목 ${i + 1}',
    status: i.isEven ? '대기' : '완료',
    date: DateTime.now().subtract(Duration(days: i)),
    ),
  );

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    // sort (desc)
    final sorted = [..._all]..sort((a, b) => b.date.compareTo(a.date));

    // filter
    final q = _q.text.trim().toLowerCase();
    final filtered = sorted.where((e) {
      final okStatus = _status == '전체' ? true : e.status == _status;
      final okQuery = q.isEmpty ? true : e.title.toLowerCase().contains(q);
      return okStatus && okQuery;
    }).toList();

    // paging: 5 per page
    final showCount = (_page * _pageSize).clamp(0, filtered.length);
    final visible = filtered.take(showCount).toList();
    final hasMore = showCount < filtered.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 문의', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: .5,
      ),
      backgroundColor: Colors.white,

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.qnaCompose),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shape: StadiumBorder(
          side: BorderSide(color: Colors.black87), // 연한 테두리
        ),
        icon: const Icon(Icons.edit),
        label: const Text('문의하기'),
      ),

      body: Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _q,
              onChanged: (_) => setState(() => _page = 1),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '제목으로 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _q.text.isEmpty
                    ? null
                    : IconButton(
                  onPressed: () {
                    _q.clear();
                    setState(() => _page = 1);
                  },
                  icon: const Icon(Icons.close_rounded),
                  tooltip: '지우기',
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: tossBlue, width: 1.5),
                ),
              ),
            ),
          ),

          // 상태 토글 (풀폭)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '전체', label: Text('전체')),
                  ButtonSegment(value: '대기', label: Text('대기')),
                  ButtonSegment(value: '완료', label: Text('완료')),
                ],
                selected: {_status},
                onSelectionChanged: (s) => setState(() {
                  _status = s.first;
                  _page = 1;
                }),
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10)),
                ),
              ),
            ),
          ),

          // 결과 개수
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
            child: Row(
              children: [
                Text('총 ${filtered.length}건',
                    style: TextStyle(color: Colors.black.withOpacity(.6), fontSize: 12.5)),
              ],
            ),
          ),

          // 리스트 / 빈 상태
          Expanded(
            child: visible.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Colors.grey[100],
                elevation: 0,
                child: const SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          '문의 내역이 없습니다.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: visible.length + (hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                if (hasMore && i == visible.length) {
                  return Center(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _page += 1),
                      child: const Text('더보기'),
                    ),
                  );
                }

                final e = visible[i];
                final style = _statusStyle(e.status);

                return InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    constraints: const BoxConstraints(minHeight: 96), // 세로 여유 조금 더
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Spacer 없이 하단 배치
                      children: [
                        // 헤더: 아이콘 + (제목 | 날짜 | 화살표)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      e.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        height: 1.2,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1E1F23),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 96,
                                    child: Text(
                                      _fmtDate(e.date),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.black.withOpacity(.55),
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.chevron_right, color: Colors.black38),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // 상태칩: 왼쪽 하단, 아주 작게
                        UnconstrainedBox(
                          alignment: Alignment.centerLeft,
                          child: _StatusChip.tiny(
                            label: e.status,
                            bg: style.bg,
                            text: Colors.black,
                            icon: style.icon,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _StatusStyle _statusStyle(String status) {
    if (status == '완료') {
      return _StatusStyle(
        bg: pastel(const Color(0xFF22C55E), .22),
        icon: Icons.task_alt_rounded,
      );
    }
    return _StatusStyle(
      bg: pastel(tossBlue, .18),
      icon: Icons.schedule_rounded,
    );
  }
}

/* components */

class _StatusChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color text;
  final IconData icon;
  final EdgeInsets padding;
  final double height;
  final double fontSize;

  const _StatusChip({
    required this.label,
    required this.bg,
    required this.text,
    required this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    this.height = 26,
    this.fontSize = 12.5,
    super.key,
  });

  const _StatusChip.small({
    required String label,
    required Color bg,
    required Color text,
    required IconData icon,
    Key? key,
  }) : this(
    key: key,
    label: label,
    bg: bg,
    text: text,
    icon: icon,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    height: 22,
    fontSize: 11.5,
  );

  // tiny 추가
  const _StatusChip.tiny({
    required String label,
    required Color bg,
    required Color text,
    required IconData icon,
    Key? key,
  }) : this(
    key: key,
    label: label,
    bg: bg,
    text: text,
    icon: icon,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    height: 20,
    fontSize: 10.5,
  );

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 18),
      child: Container(
        height: height,
        padding: padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: fontSize, color: text),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: text,
                fontWeight: FontWeight.w800,
                fontSize: fontSize,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* models */
class _StatusStyle {
  final Color bg;
  final IconData icon;
  _StatusStyle({required this.bg, required this.icon});
}
