import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../screens/fund_join_screen.dart' show JoinFund;

/// ───────────────── colors
const tossBlue = Color(0xFF0064FF);
const tossBlueDark = Color(0xFF1133AA);
// 토스 블루 계열 팔레트(도넛용)
const tossBlue500 = Color(0xFF0064FF);
const tossBlue400 = Color(0xFF2D6BFF);
const tossBlue300 = Color(0xFF5A8CFF);
const tossBlue200 = Color(0xFF9CC1FF);
const tossBlue100 = Color(0xFFD7E6FF);

final _won = NumberFormat('#,##0.##', 'ko_KR');
String fmtWon(num v) => '${_won.format(v)} 원';
String fmtPercent(num v, {int digits = 1}) => '${v.toStringAsFixed(digits)}%';
String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String fmtAumFromMm(double mm) => '${_won.format(mm / 100)} 억원';

/// ───────────────── data view models (요약)
class FundBasic {
  final String fundId, fundName, fundType, fundDivision, investmentRegion,
      salesRegionType, groupCode, shortCode, fundClass, publicType,
      addUnitType, fundStatus, riskGrade, performanceDisclosure,
      managementCompany;
  final DateTime issueDate;
  final double initialNavPrice;
  final int trustTerm, accountingPeriod;
  FundBasic({
    required this.fundId,
    required this.fundName,
    required this.fundType,
    required this.fundDivision,
    required this.investmentRegion,
    required this.salesRegionType,
    required this.groupCode,
    required this.shortCode,
    required this.issueDate,
    required this.initialNavPrice,
    required this.trustTerm,
    required this.accountingPeriod,
    required this.fundClass,
    required this.publicType,
    required this.addUnitType,
    required this.fundStatus,
    required this.riskGrade,
    required this.performanceDisclosure,
    required this.managementCompany,
  });
}

class FundFeeInfo {
  final DateTime baseDate;
  final double managementFee, salesFee, adminFee, trustFee, totalFee, ter,
      frontLoadFee, rearLoadFee;
  FundFeeInfo({
    required this.baseDate,
    required this.managementFee,
    required this.salesFee,
    required this.adminFee,
    required this.trustFee,
    required this.totalFee,
    required this.ter,
    required this.frontLoadFee,
    required this.rearLoadFee,
  });
}

class FundStatusDaily {
  final DateTime baseDate;
  final double navTotalMm, originalPrincipalMm, navPrice,
      navChange1d, navChangeRate1d, navChange1w, navChangeRate1w;
  FundStatusDaily({
    required this.baseDate,
    required this.navTotalMm,
    required this.originalPrincipalMm,
    required this.navPrice,
    required this.navChange1d,
    required this.navChangeRate1d,
    required this.navChange1w,
    required this.navChangeRate1w,
  });
}

class FundReturn {
  final DateTime baseDate;
  final double r1m, r3m, r6m, r12m;
  FundReturn({
    required this.baseDate,
    required this.r1m,
    required this.r3m,
    required this.r6m,
    required this.r12m,
  });
}

class FundAssetSummary {
  final DateTime baseDate;
  final double stock, bond, cash, etc;
  FundAssetSummary({
    required this.baseDate,
    required this.stock,
    required this.bond,
    required this.cash,
    required this.etc,
  });
}

class FundDetail {
  final FundBasic basic;
  final FundFeeInfo fee;
  final FundStatusDaily daily;
  final FundReturn ret;
  final FundAssetSummary asset;
  FundDetail({
    required this.basic,
    required this.fee,
    required this.daily,
    required this.ret,
    required this.asset,
  });

  factory FundDetail.demo(String name) => FundDetail(
    basic: FundBasic(
      fundId: 'K55207BU7140',
      fundName: name,
      fundType: '주식형',
      fundDivision: '투자신탁',
      investmentRegion: '국내',
      salesRegionType: '국내위탁',
      groupCode: '12111712301011111ZZ2',
      shortCode: 'BU714',
      issueDate: DateTime(2005, 8, 10),
      initialNavPrice: 1000,
      trustTerm: 0,
      accountingPeriod: 0,
      fundClass: '종류형 CLASS',
      publicType: '공모',
      addUnitType: '추가형',
      fundStatus: '운용중',
      riskGrade: '높은위험(UH)',
      performanceDisclosure: '(주식고)일반',
      managementCompany: '교보악사자산운용',
    ),
    fee: FundFeeInfo(
      baseDate: DateTime(2025, 6, 30),
      managementFee: 0.26,
      salesFee: 0.02,
      adminFee: 0.01,
      trustFee: 0.03,
      totalFee: 0.32,
      ter: 0.3228,
      frontLoadFee: 0,
      rearLoadFee: 0,
    ),
    daily: FundStatusDaily(
      baseDate: DateTime(2025, 8, 1),
      navTotalMm: 146653,
      originalPrincipalMm: 12975,
      navPrice: 831.93,
      navChange1d: 13.7717,
      navChangeRate1d: 1.02,
      navChange1w: -20.5464,
      navChangeRate1w: -1.48,
    ),
    ret: FundReturn(
      baseDate: DateTime(2025, 8, 1),
      r1m: 0.85,
      r3m: 1.02,
      r6m: 1.95,
      r12m: 3.80,
    ),
    asset: FundAssetSummary(
      baseDate: DateTime(2025, 8, 1),
      stock: 20,
      bond: 10,
      cash: 5,
      etc: 65,
    ),
  );
}

/// ───────────────── screen
enum _TimeTab { m1, m3, m6, y1, y3 }

class FundDetailScreen extends StatefulWidget {
  final JoinFund fund;
  const FundDetailScreen({super.key, required this.fund});

  @override
  State<FundDetailScreen> createState() => _FundDetailScreenState();
}

class _FundDetailScreenState extends State<FundDetailScreen> {
  late final FundDetail data = FundDetail.demo(widget.fund.name);
  _TimeTab _tab = _TimeTab.m3;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUp = data.daily.navChangeRate1d >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          data.basic.fundName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {},
            child: const Text('가입하기', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ───── hero (라인차트가 "수익률 그래프" 카드 안)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [tossBlue, tossBlueDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${data.basic.investmentRegion} · ${data.basic.fundType}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  const Text('상품명',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),

                  // 수익률 그래프 카드 (라인 + 영역)
                  Card(
                    elevation: .8,
                    color: isDark ? const Color(0xFFEFF4FF) : Colors.white,
                    surfaceTintColor: isDark ? const Color(0xFFEFF4FF) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                      child: SizedBox(
                        height: 180,
                        child: Stack(
                          children: [
                            LineChart(_lineDataFor(_tab)),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6, bottom: 2),
                                child: Text('*${_tabLabel(_tab)} 수익률',
                                    style: const TextStyle(fontSize: 10, color: Colors.black45)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _PeriodTabs(tab: _tab, onChanged: (t) => setState(() => _tab = t)),
                  const SizedBox(height: 12),

                  _SummaryRow(
                    navPrice: data.daily.navPrice,
                    navChangeRate1d: data.daily.navChangeRate1d,
                    totalFee: data.fee.totalFee,
                    aumEok: fmtAumFromMm(data.daily.navTotalMm),
                    isDark: isDark,
                    isUp: isUp,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ───── 도넛 (더 큼 + 섹션 라벨 + 토스 블루 팔레트)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: .6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                color: isDark ? const Color(0xFFF7F8FA) : Colors.white,
                surfaceTintColor: isDark ? const Color(0xFFF7F8FA) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('자산 구성 비율', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, c) {
                          final size = math.min(c.maxWidth, 320.0); // 카드에 맞춰 크게
                          return SizedBox(
                            height: size,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(PieChartData(
                                  centerSpaceRadius: size * 0.28,
                                  sectionsSpace: 2,
                                  sections: _pieSections(data.asset, size),
                                )),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('기준', style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600)),
                                    Text(fmtDate(data.asset.baseDate),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _Legend(items: [
                        LegendItem('주식', tossBlue500, data.asset.stock),
                        LegendItem('채권', tossBlue400, data.asset.bond),
                        LegendItem('유동성', tossBlue300, data.asset.cash),
                        LegendItem('기타', tossBlue200, data.asset.etc),
                      ]),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  /// 라인 차트 데이터(기간 탭별)
  LineChartData _lineDataFor(_TimeTab tab) {
    final spots = _spotsForRange(tab);
    final ys = spots.map((e) => e.y);
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);

    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            getTitlesWidget: (v, _) {
              // 0 ~ N 에서 0, 중간, 끝 라벨
              if (v == 0) return const Text('초', style: TextStyle(fontSize: 10));
              if (v == spots.last.x) return const Text('지금', style: TextStyle(fontSize: 10));
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      minX: 0,
      maxX: spots.last.x,
      minY: minY * 0.995, // 여백
      maxY: maxY * 1.005,
      borderData: FlBorderData(show: false),
      lineTouchData: const LineTouchData(handleBuiltInTouches: true),
      lineBarsData: [
        LineChartBarData(
          isCurved: true,
          barWidth: 2.5,
          spots: spots,
          color: Colors.red,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [Colors.red.withOpacity(.35), Colors.red.withOpacity(0.03)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  /// 기간별 라인 샘플 데이터 (수익률을 바탕으로 완만하게 증가/변동 형태로 생성)
  List<FlSpot> _spotsForRange(_TimeTab t) {
    final n = switch (t) { _TimeTab.m1 => 30, _TimeTab.m3 => 90, _TimeTab.m6 => 180, _TimeTab.y1 => 365, _TimeTab.y3 => 365 * 3 };
    final targetPct = switch (t) {
      _TimeTab.m1 => data.ret.r1m,
      _TimeTab.m3 => data.ret.r3m,
      _TimeTab.m6 => data.ret.r6m,
      _TimeTab.y1 => data.ret.r12m,
      _TimeTab.y3 => data.ret.r12m * 3, // 임시
    } / 100.0;

    final start = 1.0;
    final end = 1.0 + targetPct;
    final List<FlSpot> out = [];
    for (int i = 0; i <= n; i++) {
      final t01 = i / n;
      // 부드러운 곡선 + 약간의 등락(시뮬레이션)
      final base = start + (end - start) * (3 * t01 * t01 - 2 * t01 * t01 * t01);
      final wiggle = 0.005 * math.sin(i / 8.0) + 0.003 * math.cos(i / 5.0);
      final y = (base + wiggle).clamp(0.9, 1.5);
      out.add(FlSpot(i.toDouble(), y));
    }
    return out;
  }

  String _tabLabel(_TimeTab t) =>
      switch (t) { _TimeTab.m1 => '1개월', _TimeTab.m3 => '3개월', _TimeTab.m6 => '6개월', _TimeTab.y1 => '1년', _TimeTab.y3 => '3년' };
}

/// ───────────────── small widgets
class _PeriodTabs extends StatelessWidget {
  final _TimeTab tab;
  final ValueChanged<_TimeTab> onChanged;
  const _PeriodTabs({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const items = [
      (_TimeTab.m1, '1개월'),
      (_TimeTab.m3, '3개월'),
      (_TimeTab.m6, '6개월'),
      (_TimeTab.y1, '1년'),
      (_TimeTab.y3, '3년'),
    ];

    return Row(
      children: items.map((e) {
        final selected = tab == e.$1;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: BorderSide(color: selected ? Colors.white : Colors.white30),
                backgroundColor: selected ? Colors.white : const Color(0xFF2C5DE6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => onChanged(e.$1),
              child: Text(
                e.$2,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: selected ? tossBlue : Colors.white,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 상단 요약 3카드(더 큼 + 넘침 방지)
class _SummaryRow extends StatelessWidget {
  final double navPrice;
  final double navChangeRate1d;
  final double totalFee;
  final String aumEok;
  final bool isDark, isUp;

  const _SummaryRow({
    required this.navPrice,
    required this.navChangeRate1d,
    required this.totalFee,
    required this.aumEok,
    required this.isDark,
    required this.isUp,
  });

  @override
  Widget build(BuildContext context) {
    Widget box(String title, Widget value) {
      return Expanded(
        child: Container(
          height: 96, // ↑ 더 키움
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFFF7F8FA) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(' ', style: TextStyle(fontSize: 3)), // 위 여백용 미세 트릭
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
              const Spacer(),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: value),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        box(
          '기준가(전일대비)',
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text((isUp ? '▲' : '▼') + ' ${navChangeRate1d.toStringAsFixed(2)} ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isUp ? Colors.red : Colors.blue)),
              Text('${_won.format(navPrice)} 원', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        box(
          '총 보수(연)',
          Text(fmtPercent(totalFee, digits: 3), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        ),
        box(
          '순자산(운용펀드 기준)',
          Text(aumEok, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

/// 도넛 섹션 라벨 포함
List<PieChartSectionData> _pieSections(FundAssetSummary a, double size) {
  final items = [
    ('주식', a.stock, tossBlue500),
    ('채권', a.bond, tossBlue400),
    ('유동성', a.cash, tossBlue300),
    ('기타', a.etc, tossBlue200),
  ].where((e) => e.$2 > 0).toList();

  if (items.isEmpty) items.add(('기타', 100.0, tossBlue100));
  final maxVal = items.map((e) => e.$2).reduce(math.max);

  return List.generate(items.length, (i) {
    final it = items[i];
    final isMax = it.$2 == maxVal;
    return PieChartSectionData(
      value: it.$2,
      color: it.$3,
      radius: (size * 0.28) + (isMax ? 10 : 0),
      title: '${it.$1}\n${it.$2.toStringAsFixed(1)}%',
      titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      titlePositionPercentageOffset: .6, // 도넛 링 안쪽에 라벨
      badgePositionPercentageOffset: 1.0,
    );
  });
}

/// 범례
class _Legend extends StatelessWidget {
  final List<LegendItem> items;
  const _Legend({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items
          .map((e) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: e.color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('${e.label} ${fmtPercent(e.value)}', style: const TextStyle(fontWeight: FontWeight.w600)),
      ]))
          .toList(),
    );
  }
}

class LegendItem {
  final String label;
  final Color color;
  final double value;
  LegendItem(this.label, this.color, this.value);
}