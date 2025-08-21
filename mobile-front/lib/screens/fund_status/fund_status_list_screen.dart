// screens/fund_status_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/screens/fund_status/fund_status.dart';
import 'package:mobile_front/screens/fund_status/fund_status_detail_screen.dart';
import 'package:mobile_front/screens/fund_status/fund_status_service.dart';
import 'package:mobile_front/widgets/category_chip.dart';

class FundStatusListScreen extends StatefulWidget {
  const FundStatusListScreen({super.key});

  @override
  State<FundStatusListScreen> createState() => _FundStatusListScreenState();
}

class _FundStatusListScreenState extends State<FundStatusListScreen> {
  final _api = FundStatusApi();
  final _format = DateFormat('yyyy.MM.dd');
  final _searchCtrl = TextEditingController();
  String _category = '전체'; // 전체 | 국내 | 해외
  Timer? _debounce;

  List<FundStatusListItem> items = [];
  int page = 0;
  bool last = false;
  bool loading = false;
  String q = '';

  @override
  void initState() {
    super.initState();
    _fetch(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool reset = false}) async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final cateParam = (_category == '전체') ? null : _category;
      final res = await _api.list(q: q, category: cateParam, page: reset ? 0 : page, size: 10);
      setState(() {
        if (reset) {
          items = res.content;
          page = 1;
        } else {
          items.addAll(res.content);
          page += 1;
        }
        last = res.last;
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }


  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => q = v.trim());
      _fetch(reset: true);
    });
  }


  Future<void> _onRefresh() => _fetch(reset: true);

  void _openDetail(FundStatusListItem it) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FundStatusDetailScreen(id: it.id)),
    );
    // 상세에서 조회수 증가가 일어났으니 리스트 갱신
    _fetch(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('펀드 시황', style: TextStyle(color: AppColors.fontColor)),
        backgroundColor: Colors.white,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.fontColor),
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // 검색창
            TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: '제목/내용 검색',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                filled: true,
                fillColor: const Color(0xFFF7F9FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE7ECF7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE7ECF7)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            _CategoryTabs(
              current: _category,
              onChanged: (v) {
                setState(() => _category = v);
                _fetch(reset: true); // 선택 바뀌면 재조회
              },
            ),

            const SizedBox(height: 12),

            // 목록
            ...items.map((it) => _FundStatusTile(
              title: it.title,
              preview: it.preview,
              regDate: it.regdate, // ✅ DateTime 그대로 전달 (NEW 계산용)
              dateText: _format.format(it.regdate), // 표시는 그대로
              views: it.viewCount,
              category: it.category,
              onTap: () => _openDetail(it),
            )),

            // 더 불러오기
            if (!last)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: loading ? null : () => _fetch(reset: false),
                  icon: const Icon(Icons.expand_more),
                  label: Text(loading ? '불러오는 중...' : '더 보기'),
                ),
              ),
            if (items.isEmpty && !loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('검색 결과가 없습니다.')),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  final String current; // 전체 | 국내 | 해외
  final ValueChanged<String> onChanged;
  const _CategoryTabs({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, {required bool selected, required Color bg, required Color border, required Color text}) {
      return ChoiceChip(
        label: Text(label, style: TextStyle(
          color: selected ? Colors.white : text,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        )),
        selected: selected,
        onSelected: (_) => onChanged(label),
        selectedColor: text,              // 선택 시 진한 포인트색 바탕
        backgroundColor: bg,              // 비선택 배경
        shape: StadiumBorder(side: BorderSide(color: selected ? text : border)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(vertical: -2, horizontal: -2),
        labelPadding: const EdgeInsets.symmetric(horizontal: 10),
        checkmarkColor: Colors.white,
      );
    }

    final isAll   = current == '전체';
    final isKr    = current == '국내';
    final isOver  = current == '해외';

    // 팔레트 (리스트 칩과 톤 통일)
    const bgBlue   = Color(0xFFEFF4FF);
    const bdBlue   = Color(0xFFCCE0FF);
    const txBlue   = AppColors.primaryBlue;

    const bgGreen  = Color(0xFFEFF7F1);
    const bdGreen  = Color(0xFFBFE6CF);
    const txGreen  = Color(0xFF1A7F37);

    const bgGray   = Color(0xFFF3F5F8);
    const bdGray   = Color(0xFFE1E6EE);
    const txGray   = AppColors.fontColor;

    return Row(
      children: [
        chip('전체', selected: isAll,  bg: bgGray,  border: bdGray,  text: txGray),
        const SizedBox(width: 8),
        chip('국내', selected: isKr,   bg: bgBlue,  border: bdBlue,  text: txBlue),
        const SizedBox(width: 8),
        chip('해외', selected: isOver, bg: bgGreen, border: bdGreen, text: txGreen),
      ],
    );
  }
}



class _FundStatusTile extends StatelessWidget {
  final String title;
  final String preview;
  final DateTime regDate;   // ✅ NEW 계산용
  final String dateText;    // 표시는 문자열
  final int views;
  final String category;
  final VoidCallback onTap;

  const _FundStatusTile({
    required this.title,
    required this.preview,
    required this.regDate,
    required this.dateText,
    required this.views,
    required this.category,
    required this.onTap,
  });

  bool get isNew {
    // 48시간 이내면 NEW (시간 단위로 더 정확)
    final hours = DateTime.now().difference(regDate).inHours;
    return hours < 48;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE7ECF7)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 제목 + NEW 배지
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.fontColor,
                  ),
                ),
              ),
              if (isNew)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // 미리보기
          Text(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(height: 1.45, color: AppColors.fontColor),
          ),
          const SizedBox(height: 10),
          // 메타(카테고리, 날짜, 조회수)
          Row(children: [
            CategoryChip(category: category),
            const Spacer(),
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primaryBlue),
              const SizedBox(width: 4),
              Text(dateText, style: const TextStyle(fontSize: 12, color: AppColors.fontColor)),
              const SizedBox(width: 10),
              const Icon(Icons.remove_red_eye_outlined, size: 14, color: AppColors.primaryBlue),
              const SizedBox(width: 4),
              Text('$views', style: const TextStyle(fontSize: 12, color: AppColors.fontColor)),
            ])
          ])
        ]),
      ),
    );
  }
}
