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

/// ───────────────── data view models (요약)  ※ 스키마를 화면용으로 매핑
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

class FundDocument {
  final String type, fileName, path;
  final DateTime uploadedAt;
  FundDocument({required this.type, required this.fileName, required this.path, required this.uploadedAt});
}

class FundDetail {
  final FundBasic basic;
  final FundFeeInfo fee;
  final FundStatusDaily daily;
  final FundReturn ret;
  final FundAssetSummary asset;
  final List<FundDocument> docs;
  FundDetail({
    required this.basic,
    required this.fee,
    required this.daily,
    required this.ret,
    required this.asset,
    required this.docs,
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
    docs: [
      FundDocument(
        type: '간이투자설명서',
        fileName: 'P_20250715_v1.pdf',
        path: '/docs/K55207BU7140/',
        uploadedAt: DateTime(2025, 7, 15, 10, 32, 54),
      ),
      FundDocument(
        type: '투자설명서',
        fileName: 'T_20250715_v1.pdf',
        path: '/docs/K55207BU7140/',
        uploadedAt: DateTime(2025, 7, 15, 10, 33, 10),
      ),
    ],
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

            // ───── 도넛 (축소 + 섹션 라벨을 링 안쪽에)
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
                          final size = math.min(c.maxWidth, 240.0); // ← 축소
                          return SizedBox(
                            height: size + 8,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(PieChartData(
                                  centerSpaceRadius: size * 0.38, // ← 가운데 공간을 넓혀 라벨이 링 위로
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

                      // 표 방식(텍스트)으로도 제공
                      _AssetTable(
                        rows: const [
                          ('주식', tossBlue500),
                          ('채권', tossBlue400),
                          ('유동성', tossBlue300),
                          ('기타', tossBlue200),
                        ],
                        values: [ 'stock', 'bond', 'cash', 'etc' ],
                        asset: data.asset,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ───── 기본 정보
            _InfoCard(
              title: '펀드 기본 정보',
              rows: [
                ('펀드 ID', data.basic.fundId),
                ('펀드명', data.basic.fundName),
                ('상품분류', data.basic.fundType),
                ('구분', data.basic.fundDivision),
                ('투자지역', data.basic.investmentRegion),
                ('판매지역구분', data.basic.salesRegionType),
                ('분류코드', data.basic.groupCode),
                ('단축코드', data.basic.shortCode),
                ('설정일', fmtDate(data.basic.issueDate)),
                ('최초설정기준가격', '${data.basic.initialNavPrice.toStringAsFixed(2)}'),
                ('신탁기간(월)', '${data.basic.trustTerm}'),
                ('신탁회계기간(월)', '${data.basic.accountingPeriod}'),
                ('특성 분류', data.basic.fundClass),
                ('공모/사모', data.basic.publicType),
                ('추가/단위형', data.basic.addUnitType),
                ('운용상태', data.basic.fundStatus),
                ('위험 등급', data.basic.riskGrade),
                ('운용실적공시', data.basic.performanceDisclosure),
                ('운용사', data.basic.managementCompany),
              ],
            ),

            // ───── 보수 및 수수료
            _InfoCard(
              title: '보수 및 수수료 (기준: ${fmtDate(data.fee.baseDate)})',
              rows: [
                ('운용보수', '${fmtPercent(data.fee.managementFee, digits: 3)}'),
                ('판매보수', '${fmtPercent(data.fee.salesFee, digits: 3)}'),
                ('일반사무관리보수', '${fmtPercent(data.fee.adminFee, digits: 3)}'),
                ('수탁보수', '${fmtPercent(data.fee.trustFee, digits: 3)}'),
                ('총보수', '${fmtPercent(data.fee.totalFee, digits: 3)}'),
                ('총비용비율(TER)', '${fmtPercent(data.fee.ter, digits: 4)}'),
                ('선취수수료', '${fmtPercent(data.fee.frontLoadFee, digits: 2)}'),
                ('후취수수료', '${fmtPercent(data.fee.rearLoadFee, digits: 2)}'),
              ],
            ),

            // ───── 일일 운용 상태
            _InfoCard(
              title: '일일 운용 상태 (기준: ${fmtDate(data.daily.baseDate)})',
              rows: [
                ('순자산총액(백만원)', _won.format(data.daily.navTotalMm)),
                ('설정원본(백만원)', _won.format(data.daily.originalPrincipalMm)),
                ('순자산 기준가(NAV)', data.daily.navPrice.toStringAsFixed(2)),
                ('전일 대비 등락(절대)', data.daily.navChange1d.toStringAsFixed(4)),
                ('전일 대비 등락률', '${fmtPercent(data.daily.navChangeRate1d, digits: 2)}'),
                ('전주 대비 등락(절대)', data.daily.navChange1w.toStringAsFixed(4)),
                ('전주 대비 등락률', '${fmtPercent(data.daily.navChangeRate1w, digits: 2)}'),
              ],
            ),

            // ───── 기간별 수익률
            _InfoCard(
              title: '기간별 수익률 (기준: ${fmtDate(data.ret.baseDate)})',
              rows: [
                ('1개월', '${fmtPercent(data.ret.r1m, digits: 2)}'),
                ('3개월', '${fmtPercent(data.ret.r3m, digits: 2)}'),
                ('6개월', '${fmtPercent(data.ret.r6m, digits: 2)}'),
                ('12개월', '${fmtPercent(data.ret.r12m, digits: 2)}'),
              ],
            ),

            // ───── 공시자료
            _DocsCard(docs: data.docs),

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
              if (v == 0) return const Text('초', style: TextStyle(fontSize: 10));
              if (v == spots.last.x) return const Text('지금', style: TextStyle(fontSize: 10));
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      minX: 0,
      maxX: spots.last.x,
      minY: minY * 0.995,
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

  /// 기간별 라인 샘플 데이터
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

/// 상단 요약 3카드
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
          height: 96,
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
              const Text(' ', style: TextStyle(fontSize: 3)),
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

/// 도넛 섹션: 라벨을 링 **안쪽**에 보이도록 (titlePositionPercentageOffset ↓)
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
      radius: (size * 0.26) + (isMax ? 8 : 0),
      title: '${it.$1}\n${it.$2.toStringAsFixed(1)}%',
      titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      titlePositionPercentageOffset: .48, // ← 링 내부로
      badgePositionPercentageOffset: 1.0,
    );
  });
}

/// 도넛 하단 텍스트 표
class _AssetTable extends StatelessWidget {
  final List<(String, Color)> rows;
  final List<String> values; // 'stock' | 'bond' | 'cash' | 'etc'
  final FundAssetSummary asset;
  const _AssetTable({required this.rows, required this.values, required this.asset});

  double _valByKey(String k) => switch (k) {
    'stock' => asset.stock,
    'bond'  => asset.bond,
    'cash'  => asset.cash,
    _       => asset.etc,
  };

  @override
  Widget build(BuildContext context) {
    return DataTable(
      headingRowHeight: 32,
      dataRowMinHeight: 32,
      dataRowMaxHeight: 36,
      columns: const [
        DataColumn(label: Text('자산')),
        DataColumn(label: Text('비중')),
        DataColumn(label: Text('기준일')),
      ],
      rows: List.generate(rows.length, (i) {
        final label = rows[i].$1;
        final color = rows[i].$2;
        final v = _valByKey(values[i]);
        return DataRow(cells: [
          DataCell(Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label),
          ])),
          DataCell(Text('${v.toStringAsFixed(1)}%')),
          DataCell(Text(fmtDate(asset.baseDate))),
        ]);
      }),
    );
  }
}

/// 공통 정보 카드
class _InfoCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...rows.map((e) => _kv(e.$1, e.$2)).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 130, child: Text(k, style: const TextStyle(color: Colors.black54))),
        const SizedBox(width: 10),
        Expanded(child: Text(v, maxLines: 3, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}

/// 공시자료 카드
class _DocsCard extends StatelessWidget {
  final List<FundDocument> docs;
  const _DocsCard({required this.docs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('공시자료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...docs.map((d) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(d.type),
                subtitle: Text('${d.fileName} · 업로드 ${fmtDate(d.uploadedAt)}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: 파일 뷰/다운로드 라우팅 연결
                },
              )),
            ],
          ),
        ),
      ),
    );
  }
}