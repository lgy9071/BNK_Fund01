// lib/screens/fund_compare/compare_sheets.dart
import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart' show tossBlue;
import 'package:mobile_front/models/compare_fund_view.dart';
import 'package:mobile_front/screens/fund_detail_screen.dart';

/// ===== Public APIs ===========================================================
Future<void> showCompareModal(
    BuildContext context,
    List<CompareFundView> funds,
    ) async {
  if (funds.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('최소 2개 이상 담아야 비교할 수 있어요.')),
    );
    return;
  }
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'close',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => _RoundedDialogShell(
      child: _CompareSheetBody(funds: funds.take(2).toList()),
    ),
    transitionBuilder: (ctx, a, _, child) {
      final t = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: t,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(t),
          child: child,
        ),
      );
    },
  );
}

/// ===== Rounded Shell (공통 모달 컨테이너) ================================
class _RoundedDialogShell extends StatelessWidget {
  final Widget child;
  const _RoundedDialogShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxWidth: 860,
              maxHeight: size.height - 24, // 넘치면 내부 스크롤
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.08),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// ===== Compare Sheet Body ====================================================
class _CompareSheetBody extends StatelessWidget {
  final List<CompareFundView> funds; // length == 2
  const _CompareSheetBody({required this.funds});

  // A/B 컬러
  static const Color aColor = tossBlue;
  static const Color bColor = Color(0xFF6D28D9); // deep purple 계열

  String _fmtPct(double v) => '${v.toStringAsFixed(2)}%';
  String _safe(String? s) => (s == null || s.trim().isEmpty) ? '-' : s.trim();

  // 우위 텍스트 칩(배경/박스 없이 텍스트만)
  Widget _winChip(Color bgColor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(50), // pill 모양
    ),
    child: const Text(
      '우위',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 11,
      ),
    ),
  );

  // 수익률 셀: 값 + (우위 텍스트만)
  Widget _metricCell({
    required double value,
    required bool isWinner,
    required Color accent,
  }) {
    // 색상 조건
    Color valueColor;
    if (value > 0) {
      valueColor = Colors.redAccent; // 연한 빨강
    } else if (value < 0) {
      valueColor = Colors.blueAccent; // 연한 파랑
    } else {
      valueColor = Colors.black87; // 0은 기본색
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${value.toStringAsFixed(2)}%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
        if (isWinner) ...[
          const SizedBox(width: 6),
          _winChip(accent),
        ],
      ],
    );
  }

  // 헤더: 항목 / A / B (이름은 아래 레전드에서 표시)
  TableRow _headerRow() {
    return TableRow(
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAFF),
        border: const Border(bottom: BorderSide(color: Colors.black12, width: .6)),
      ),
      children: [
        _Cell.pad(Text('항목', style: TextStyle(fontWeight: FontWeight.w900))),
        _Cell.padCenter(child: Text('A', style: TextStyle(fontWeight: FontWeight.w900, color: aColor))),
        _Cell.padCenter(child: Text('B', style: TextStyle(fontWeight: FontWeight.w900, color: bColor))),
      ],
    );
  }

  TableRow _zebraRow(int i, String label, Widget a, Widget b) {
    final bg = (i % 2 == 0) ? Colors.white : const Color(0xFFFAFAFC);
    return TableRow(
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: Colors.black12.withOpacity(.06))),
      ),
      children: [
        _Cell.label(label),
        _Cell.body(a),
        _Cell.body(b),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = funds[0];
    final b = funds[1];

    // 승부 판정(동률이면 둘 다 false)
    bool win(double left, double right) => left > right;

    return Column(
      mainAxisSize: MainAxisSize.min, // ✅ 내용 높이에 맞춰 모달 높이 축소
      children: [
        // 헤더 바
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x11000000))),
          ),
          child: Row(
            children: [
              const Text('펀드 비교', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const Spacer(),
              IconButton(
                tooltip: '닫기',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // 본문(표 + 레전드)
        Flexible(
          fit: FlexFit.loose, // ✅ 남는 공간이 있어도 강제로 늘리지 않음
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A/B 레전드 (이름 표기)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12.withOpacity(.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _legendRow('A', a.name, aColor),
                      const SizedBox(height: 6),
                      _legendRow('B', b.name, bColor),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 표 컨테이너 (라운드 + 경계선, 잘림 방지)
                DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.black12.withOpacity(.10)),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Table(
                      columnWidths: const {
                        0: FixedColumnWidth(120), // 라벨
                        1: FlexColumnWidth(),
                        2: FlexColumnWidth(),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        _headerRow(),
                        _zebraRow(0, '펀드유형', Text(a.type), Text(b.type)),
                        _zebraRow(1, '위험등급', Text(a.riskText ?? '위험(-)'), Text(b.riskText ?? '위험(-)')),
                        _zebraRow(2, '운용사', Text(_safe(a.managementCompany)), Text(_safe(b.managementCompany))),
                        _zebraRow(
                          3,
                          '1개월 수익',
                          _metricCell(value: a.return1m, isWinner: win(a.return1m, b.return1m), accent: aColor),
                          _metricCell(value: b.return1m, isWinner: win(b.return1m, a.return1m), accent: bColor),
                        ),
                        _zebraRow(
                          4,
                          '3개월 수익',
                          _metricCell(value: a.return3m, isWinner: win(a.return3m, b.return3m), accent: aColor),
                          _metricCell(value: b.return3m, isWinner: win(b.return3m, a.return3m), accent: bColor),
                        ),
                        _zebraRow(
                          5,
                          '12개월 수익',
                          _metricCell(value: a.return12m, isWinner: win(a.return12m, b.return12m), accent: aColor),
                          _metricCell(value: b.return12m, isWinner: win(b.return12m, a.return12m), accent: bColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // 하단 액션 바: 상세보기 버튼 (모달 유지한 채 push)
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x11000000))),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FundDetailScreen(fundId: a.fundId, title: a.name),
                    ));
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('상세보기 A'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: aColor.withOpacity(.6)),
                    foregroundColor: aColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FundDetailScreen(fundId: b.fundId, title: b.name),
                    ));
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('상세보기 B'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: bColor),
                    foregroundColor: bColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendRow(String badge, String name, Color color) {
    return Row(
      children: [
        Text(
          badge,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            letterSpacing: .2,
            shadows: [
              Shadow(color: color, blurRadius: 0, offset: Offset(0, 0)), // 컬러 느낌 살짝
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// ===== Cell helpers ==========================================================
class _Cell {
  static Widget pad(Widget child) =>
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), child: child);

  static Widget padCenter({required Widget child}) =>
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), child: Center(child: child));

  static Widget label(String text) =>
      pad(Text(text, style: const TextStyle(fontWeight: FontWeight.w800)));

  static Widget body(Widget child) => pad(child);
}

