import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../screens/fund_join_screen.dart' show JoinFund;

/// ───────────────── colors
const tossBlue = Color(0xFF0064FF);
const tossBlueDark = Color(0xFF1133AA);
const violet = Color(0xFF6E3AFF);
const violetSoft = Color(0xFFEEE7FF);

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

/// ───────────────── data view models (요약) ※ 기존 구조 유지
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
      riskGrade: '매우 높은 위험(1)', // 예시 포맷
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
      stock: 55,
      bond: 25,
      cash: 5,
      etc: 15,
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

/// 차트 기간 선택 탭 (1개월/3개월/6개월/1년/3년)
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

class _FundDetailScreenState extends State<FundDetailScreen> {
  late final FundDetail data = FundDetail.demo(widget.fund.name);
  _TimeTab _tab = _TimeTab.m3;

  // 간편 적립식 카드 상태
  int _years = 1;
  int _monthly = 500000; // 50만원

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
            // ───── HERO : 라인 차트 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [tossBlue, tossBlueDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${data.basic.investmentRegion} · ${data.basic.fundType}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  const Text('수익률 그래프',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),

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

                  // 그래프 하단 핵심정보 2개만
                  _KeyFactsRow(
                    navPrice: data.daily.navPrice,
                    navChangeRate1d: data.daily.navChangeRate1d,
                    riskText: data.basic.riskGrade,
                    isUp: isUp,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 간편 적립식 참고 카드
            _SimpleDcaCard(
              years: _years,
              monthly: _monthly,
              onYears: (y) => setState(() => _years = y),
              onMonthly: (m) => setState(() => _monthly = m),
              assumedAnnualReturn: data.ret.r12m / 100.0, // 대략 1년 수익률 사용
            ),

            const SizedBox(height: 12),

            // 위험수준 — 도넛 + 표
            _RiskCard(riskText: data.basic.riskGrade),

            const SizedBox(height: 12),

            // 자산 구성 — 도넛 + 표
            _AssetCard(asset: data.asset),

            const SizedBox(height: 12),

            // 주식/채권 보유 비중 — 표
            _StockBondTable(stockPct: data.asset.stock, bondPct: data.asset.bond, baseDate: data.asset.baseDate),

            const SizedBox(height: 12),

            // 보수 및 수수료 — 카드형
            _FeeCards(fee: data.fee),

            const SizedBox(height: 12),

            // 상품정보 카드
            _InfoCard(
              title: '상품 정보',
              rows: [
                ('펀드 ID', data.basic.fundId),
                ('상품명', data.basic.fundName),
                ('상품분류', data.basic.fundType),
                ('구분', data.basic.fundDivision),
                ('투자지역', data.basic.investmentRegion),
                ('설정일', fmtDate(data.basic.issueDate)),
                ('운용사', data.basic.managementCompany),
                ('위험 등급', data.basic.riskGrade),
              ],
            ),

            // 매입/환매 프로세스 카드
            _ProcessCard(),

            //공시자료
            _DocsCard(docs: data.docs),

            const SizedBox(height: 12),

            // 확인사항(디스클레이머)
            const _NoticeCard(
              items: [
                '집합투자증권을 취득하시기 전에 투자대상, 보수, 수수료 및 환매방법 등에 관하여 (간이)투자설명서를 반드시 읽어보시기 바랍니다.',
                '원금손실이 발생할 수 있으며, 그 손실은 투자자에게 귀속됩니다.',
                '과거의 수익률이 미래의 수익률을 보장하지 않습니다.',
              ],
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

/// ───────────────── widgets

/// 그래프 아래 핵심 2카드
class _KeyFactsRow extends StatelessWidget {
  final double navPrice;
  final double navChangeRate1d;
  final String riskText;
  final bool isUp;
  const _KeyFactsRow({
    required this.navPrice,
    required this.navChangeRate1d,
    required this.riskText,
    required this.isUp,
  });

  int _riskLevelFromText(String s) {
    // “매우 높은 위험(1)” “낮은 위험(5)” 등 숫자 추출 (없으면 3)
    final m = RegExp(r'\((\d)\)').firstMatch(s);
    return m != null ? int.parse(m.group(1)!) : 3;
  }

  @override
  Widget build(BuildContext context) {
    final level = _riskLevelFromText(riskText).clamp(1, 5);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 92,
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('기준가(전일대비)', style: TextStyle(fontSize: 12, color: Colors.black54)),
                const Spacer(),
                Row(
                  children: [
                    Text((isUp ? '▲' : '▼') + ' ${navChangeRate1d.toStringAsFixed(2)} ',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isUp ? Colors.red : Colors.blue)),
                    const SizedBox(width: 6),
                    Flexible(child: Text('${_won.format(navPrice)} 원', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 92,
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('위험수준', style: TextStyle(fontSize: 12, color: Colors.black54)),
                const Spacer(),
                Text('레벨 $level', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 간편 적립식 참고 카드
class _SimpleDcaCard extends StatelessWidget {
  final int years;
  final int monthly; // 원
  final ValueChanged<int> onYears;
  final ValueChanged<int> onMonthly;
  final double assumedAnnualReturn; // 0.038 → 3.8%
  const _SimpleDcaCard({
    required this.years,
    required this.monthly,
    required this.onYears,
    required this.onMonthly,
    required this.assumedAnnualReturn,
  });

  @override
  Widget build(BuildContext context) {
    final months = years * 12;
    final r = assumedAnnualReturn <= -1 ? 0.0 : (math.pow(1 + assumedAnnualReturn, 1 / 12) - 1);
    final total = monthly * months;
    final fv = r == 0 ? total.toDouble() : monthly * ((math.pow(1 + r, months) - 1) / r);
    final rate = fv / total - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE9F1FF),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _DD<int>(
                  value: years,
                  items: const [1, 3, 5],
                  labelBuilder: (v) => '$v년',
                  onChanged: onYears,
                ),
                const Text('이 상품에'),
                _DD<int>(
                  value: monthly,
                  items: const [100000, 300000, 500000, 1000000],
                  labelBuilder: (v) => '${_won.format(v ~/ 10000)}만원',
                  onChanged: onMonthly,
                ),
                const Text('씩 투자했다면?'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(.6), borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _kv('총 투자금액', fmtWon(total)),
                  _kv('평가액(가정)', fmtWon(fv)),
                  _kv('수익률(적립식)', fmtPercent(rate * 100, digits: 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(k)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _DD<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;
  const _DD({required this.value, required this.items, required this.labelBuilder, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: DropdownButton<T>(
          value: value,
          underline: const SizedBox.shrink(),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(labelBuilder(e)))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

/// 위험수준 카드 (도넛 + 표)
class _RiskCard extends StatelessWidget {
  final String riskText;
  const _RiskCard({required this.riskText});

  int _riskLevelFromText(String s) {
    final m = RegExp(r'\((\d)\)').firstMatch(s);
    return m != null ? int.parse(m.group(1)!) : 3;
  }

  @override
  Widget build(BuildContext context) {
    final level = _riskLevelFromText(riskText).clamp(1, 5);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('위험수준', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 140, height: 140,
                    child: PieChart(PieChartData(
                      centerSpaceRadius: 46,
                      sectionsSpace: 2,
                      sections: [
                        PieChartSectionData(value: level.toDouble(), color: Colors.red, radius: 18, title: ''),
                        PieChartSectionData(value: (5 - level).toDouble(), color: Colors.grey[300], radius: 18, title: ''),
                      ],
                    )),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DataTable(
                      headingRowHeight: 28, dataRowMinHeight: 32, dataRowMaxHeight: 36,
                      columns: const [DataColumn(label: Text('항목')), DataColumn(label: Text('값'))],
                      rows: [
                        DataRow(cells: [const DataCell(Text('적용기간')), const DataCell(Text('1년'))]),
                        DataRow(cells: [const DataCell(Text('위험레벨(1~5)')), DataCell(Text('$level'))]),
                        DataRow(cells: [const DataCell(Text('설명')), DataCell(Text(riskText))]),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 자산 구성 — 도넛 + 표
class _AssetCard extends StatelessWidget {
  final FundAssetSummary asset;
  const _AssetCard({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: .6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('자산 구성 비율', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 40),
              LayoutBuilder(
                builder: (context, c) {
                  final size = math.min(c.maxWidth, 180.0);
                  return SizedBox(
                    height: size + 8,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(PieChartData(
                          centerSpaceRadius: size * 0.42,
                          sectionsSpace: 2,
                          sections: _pieSections(asset, size),
                        )),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('기준', style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.w600)),
                            Text(fmtDate(asset.baseDate),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 50),
              _AssetTable(
                rows: const [
                  ('주식', tossBlue500),
                  ('채권', tossBlue400),
                  ('유동성', tossBlue300),
                  ('기타', tossBlue200),
                ],
                values: const ['stock', 'bond', 'cash', 'etc'],
                asset: asset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      titlePositionPercentageOffset: .48,
      badgePositionPercentageOffset: 1.0,
    );
  });
}

class _AssetTable extends StatelessWidget {
  final List<(String, Color)> rows;
  final List<String> values;
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

/// 주식/채권 보유 비중 표
class _StockBondTable extends StatelessWidget {
  final double stockPct, bondPct;
  final DateTime baseDate;
  const _StockBondTable({required this.stockPct, required this.bondPct, required this.baseDate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('주식 및 채권 보유 비중', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              DataTable(
                headingRowHeight: 32,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 36,
                columns: const [DataColumn(label: Text('자산')), DataColumn(label: Text('비중')), DataColumn(label: Text('기준일'))],
                rows: [
                  DataRow(cells: [const DataCell(Text('주식')), DataCell(Text('${stockPct.toStringAsFixed(1)}%')), DataCell(Text(fmtDate(baseDate)))]),
                  DataRow(cells: [const DataCell(Text('채권')), DataCell(Text('${bondPct.toStringAsFixed(1)}%')), DataCell(Text(fmtDate(baseDate)))]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 보수 및 수수료 — 3블록 카드
class _FeeCards extends StatelessWidget {
  final FundFeeInfo fee;
  const _FeeCards({required this.fee});

  String _feeText(double v) => v == 0 ? '수수료없음' : fmtPercent(v, digits: 3);

  @override
  Widget build(BuildContext context) {
    Widget block(String title, List<(String, String)> rows) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: violetSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: violet.withOpacity(.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: violet)),
            const SizedBox(height: 8),
            ...rows.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(e.$1, style: const TextStyle(height: 1.2))), // 라벨
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.$2,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700, height: 1.2),
                    ),
                  ), // 값
                ],
              ),
            )),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: LayoutBuilder(
            builder: (context, c) {
              final isNarrow = c.maxWidth < 360; // 폭 좁으면 세로로
              final children = [
                block('매입할 때', [
                  ('선취판매수수료', _feeText(fee.frontLoadFee)),
                ]),
                block('투자기간동안', [
                  ('총 보수(연)', fmtPercent(fee.totalFee, digits: 3)),
                  ('총비용비율(TER)', fmtPercent(fee.ter, digits: 4)),
                  // 긴 항목들을 4줄로 분리해 깨짐 방지
                  ('운용보수', fmtPercent(fee.managementFee, digits: 3)),
                  ('판매보수', fmtPercent(fee.salesFee, digits: 3)),
                  ('일반사무관리보수', fmtPercent(fee.adminFee, digits: 3)),
                  ('수탁보수', fmtPercent(fee.trustFee, digits: 3)),
                ]),
                block('환매할 때', [
                  ('후취판매수수료', _feeText(fee.rearLoadFee)),
                  ('환매수수료', '수수료없음'),
                ]),
              ];

              if (isNarrow) {
                // 세로 스택
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('보수 및 수수료 · 기준 ${fmtDate(fee.baseDate)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    ...children.expand((w) => [w, const SizedBox(height: 8)]).toList()..removeLast(),
                  ],
                );
              } else {
                // 가로 + 간격
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('보수 및 수수료 · 기준 ${fmtDate(fee.baseDate)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: children[0]),
                        const SizedBox(width: 8),
                        Expanded(child: children[1]),
                        const SizedBox(width: 8),
                        Expanded(child: children[2]),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
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
                onTap: () { /* TODO: 파일 열기 */ },
              )),
            ],
          ),
        ),
      ),
    );
  }
}

/// 매입/환매 프로세스 카드(간단 버전)
class _ProcessCard extends StatelessWidget {
  const _ProcessCard();

  Widget _chip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFFE8F0FF), borderRadius: BorderRadius.circular(10)),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  Widget _col(String title, List<(String, List<String>)> groups) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFE9F1FF), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: tossBlue)),
            const SizedBox(height: 10),
            ...groups.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(g.$1.contains('이전') ? Icons.wb_sunny_outlined : Icons.nightlight_round, size: 18, color: tossBlue),
                    const SizedBox(width: 6),
                    Text(g.$1, style: const TextStyle(fontWeight: FontWeight.w700, color: tossBlue)),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: g.$2.map(_chip).toList()),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('매입/환매 프로세스', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _col('매입', [
                    ('17시 이전', ['매입 신청일', '기준가 적용일', '매입일']),
                    ('17시 경과후', ['매입 신청일', '기준가 적용일', '매입일']),
                  ]),
                  const SizedBox(width: 8),
                  _col('환매', [
                    ('17시 이전', ['환매 신청일', '기준가 적용일', '환매일']),
                    ('17시 경과후', ['환매 신청일', '기준가 적용일', '환매일']),
                  ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 확인사항 카드
class _NoticeCard extends StatelessWidget {
  final List<String> items;
  const _NoticeCard({required this.items});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: const Color(0xFFFFFAEE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('확인사항', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              ...items.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(s)),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}