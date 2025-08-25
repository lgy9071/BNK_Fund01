import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_front/core/services/qna_api.dart';
import 'package:mobile_front/models/qna_item.dart';
import 'package:mobile_front/screens/qna_compose_screen.dart';

const tossBlue = Color(0xFF0064FF);
const successGreen = Color(0xFF16A34A);
Color pastel(Color c, [double t = .16]) => Color.lerp(Colors.white, c, t)!;

class QnaListScreen extends StatefulWidget {
  final String baseUrl;
  final String accessToken;

  const QnaListScreen({
    super.key,
    required this.baseUrl,
    required this.accessToken,
  });

  @override
  State<QnaListScreen> createState() => _QnaListScreenState();
}

class _QnaListScreenState extends State<QnaListScreen> {
  final _q = TextEditingController();
  String _status = '전체'; // 전체 | 대기 | 완료

  static const _pageSize = 10;
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;

  late final QnaApi _api;
  final List<QnaItem> _items = [];
  final _fmt = DateFormat('yyyy.MM.dd');

  @override
  void initState() {
    super.initState();
    _api = QnaApi(baseUrl: widget.baseUrl, accessToken: widget.accessToken);
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      if (refresh) {
        _items.clear();
        _page = 0;
        _hasMore = true;
      }
      final r = await _api.myQnas(page: _page, size: _pageSize);
      _items.addAll(r.items);
      _hasMore = _page + 1 < r.totalPages;
      _page++;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('목록 조회 실패: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtDate(DateTime d) => _fmt.format(d);

  Future<void> _openCompose() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QnaComposeScreen(
          baseUrl: widget.baseUrl,
          accessToken: widget.accessToken,
        ),
      ),
    );
    if (created == true) await _load(refresh: true);
  }

  Future<void> _openDetailSheet(QnaItem item) async {
    final detail = await _api.detail(item.qnaId);
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4, width: 42,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Row(
                children: [
                  _StatusChip.small(
                    label: detail.status,
                    bg: detail.status == '완료'
                        ? pastel(successGreen, .22)
                        : pastel(tossBlue, .22),
                    text: Colors.black,
                    icon: detail.status == '완료'
                        ? Icons.task_alt_rounded
                        : Icons.schedule_rounded,
                  ),
                  const Spacer(),
                  Text(_fmtDate(detail.regDate),
                      style: const TextStyle(color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 10),
              Text(detail.title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827))),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(detail.content, style: const TextStyle(height: 1.45)),
              if (detail.answer != null && detail.answer!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: pastel(successGreen, .18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE6F4EA)),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.reply_rounded, color: successGreen),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('답변',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF065F46))),
                            const SizedBox(height: 6),
                            Text(detail.answer!, style: const TextStyle(height: 1.45)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim().toLowerCase();
    final filtered = _items.where((e) {
      final okStatus = _status == '전체' ? true : e.status == _status;
      final okQuery = q.isEmpty ? true : e.title.toLowerCase().contains(q);
      return okStatus && okQuery;
    }).toList();

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
        onPressed: _openCompose,
        backgroundColor: tossBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('새 문의'),
      ),

      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            // 검색 + 상태 칩
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _q,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: '제목으로 검색',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _q.text.isEmpty
                      ? null
                      : IconButton(
                    onPressed: () {
                      _q.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                    tooltip: '지우기',
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: tossBlue, width: 1.5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  _filterChip('전체'),
                  const SizedBox(width: 8),
                  _filterChip('대기'),
                  const SizedBox(width: 8),
                  _filterChip('완료'),
                  const Spacer(),
                  if (_loading)
                    const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
              child: Text('총 ${filtered.length}건',
                  style: TextStyle(color: Colors.black.withOpacity(.6), fontSize: 12.5)),
            ),

            // 리스트
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  color: Colors.grey[100],
                  elevation: 0,
                  child: const SizedBox(
                    height: 160,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 42, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('문의 내역이 없습니다.', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              ...[
                for (final e in filtered) _qnaCard(e),
                if (_hasMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: OutlinedButton(
                        onPressed: _loading ? null : _load,
                        child: _loading
                            ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('더보기'),
                      ),
                    ),
                  ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _qnaCard(QnaItem e) {
    final style = _statusStyle(e.status);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: InkWell(
        onTap: () => _openDetailSheet(e),
        borderRadius: BorderRadius.circular(16),
        child: Container
          (
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6E8EC)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusChip.tiny(
                    label: e.status,
                    bg: style.bg,
                    text: Colors.black,
                    icon: style.icon,
                  ),
                  const Spacer(),
                  Text(
                    _fmtDate(e.regDate),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withOpacity(.55),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right, color: Colors.black26),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                e.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1F23),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _status == label;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : Colors.black,
        ),
      ),
      selected: selected,
      onSelected: (_) => setState(() => _status = label),
      selectedColor: tossBlue,
      backgroundColor: const Color(0xFFF3F4F6),
      shape: StadiumBorder(
        side: BorderSide(color: selected ? tossBlue : const Color(0xFFE5E7EB)),
      ),
        showCheckmark: false
    );
  }

  _StatusStyle _statusStyle(String status) {
    if (status == '완료') {
      return _StatusStyle(
        bg: pastel(successGreen, .22),
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
