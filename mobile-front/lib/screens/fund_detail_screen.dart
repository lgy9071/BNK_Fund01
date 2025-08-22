import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:mobile_front/core/services/fund_service.dart';
import 'package:mobile_front/models/fund_detail_net.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_front/core/constants/api.dart'; // ApiConfig.baseUrl 사용

/// ───────────────── colors
const tossBlue = Color(0xFF0064FF);
const tossBlue500 = Color(0xFF0064FF);
const tossBlue400 = Color(0xFF2D6BFF);
const tossBlue300 = Color(0xFF5A8CFF);
const tossBlue200 = Color(0xFF9CC1FF);
const tossBlue100 = Color(0xFFD7E6FF);
const blueSoft = Color(0xFFE9F1FF);

final _manInt = NumberFormat('#,##0', 'ko_KR'); // 만원 단위 정수 표기
String fmtMan(num won) => '${_manInt.format((won / 10000).round())} 만원';

final _won = NumberFormat('#,##0.##', 'ko_KR');
String fmtWon(num v) => '${_won.format(v)} 원';
String fmtPercent(num v, {int digits = 1}) => '${v.toStringAsFixed(digits)}%';
String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// ────────────── 문서 열기 URL 조합(세그먼트 단위 인코딩)
Uri _buildDocUri(String base, String raw) {
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return Uri.parse(raw);
  }
  final alreadyEncoded = RegExp(r'%[0-9A-Fa-f]{2}').hasMatch(raw);
  final withSlash = raw.startsWith('/') ? raw : '/$raw';
  if (alreadyEncoded) return Uri.parse('${ApiConfig.baseUrl}$withSlash');

  final b = Uri.parse(base);
  final trimmed = withSlash.substring(1);
  final segs = trimmed.split('/').where((s) => s.isNotEmpty).toList();
  return Uri(
    scheme: b.scheme,
    host: b.host,
    port: b.hasPort ? b.port : null,
    pathSegments: [...b.pathSegments.where((s) => s.isNotEmpty), ...segs],
  );
}

/// ───────────────── 리스트 화면에서 넘어오는 최소 정보
class JoinFund {
  final int id;
  final String fundId;
  final String name;
  JoinFund({required this.id, required this.fundId, required this.name});
}

/// ───────────────── 네트워크 → UI용 상세 모델
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
}

/// FundDetailNet → FundDetail 변환(날짜 보정 포함)
FundDetail toUiDetail(FundDetailNet d) {
  DateTime _parse(String? s) {
    if (s == null || s.isEmpty) return DateTime.now();
    final p = s.split('-').map(int.parse).toList();
    final dt = DateTime(p[0], p[1], p[2]);
    return dt.year < 2000 ? DateTime.now() : dt; // 1907 같은 과거값 보정
  }

  final latestDate = _parse(d.latestBaseDate ?? d.issueDate);
  final riskText = d.riskLevel == null ? '위험 미정' : '위험(${d.riskLevel}등급)';

  return FundDetail(
    basic: FundBasic(
      fundId: d.fundId,
      fundName: d.fundName,
      fundType: d.fundType ?? '-',
      fundDivision: d.fundDivision ?? '-',
      investmentRegion: d.investmentRegion ?? '-',
      salesRegionType: d.salesRegionType ?? '-',
      groupCode: '',
      shortCode: '',
      issueDate: _parse(d.issueDate),
      initialNavPrice: 1000,
      trustTerm: 0,
      accountingPeriod: 0,
      fundClass: '-',
      publicType: '-',
      addUnitType: '-',
      fundStatus: d.fundStatus ?? '-',
      riskGrade: riskText,
      performanceDisclosure: '-',
      managementCompany: d.managementCompany ?? '-',
    ),
    fee: FundFeeInfo(
      baseDate: latestDate,
      managementFee: 0,
      salesFee: 0,
      adminFee: 0,
      trustFee: 0,
      totalFee: d.totalFee ?? 0,
      ter: d.ter ?? 0,
      frontLoadFee: 0,
      rearLoadFee: 0,
    ),
    daily: FundStatusDaily(
      baseDate: latestDate,
      navTotalMm: d.navTotal ?? 0,
      originalPrincipalMm: d.originalPrincipal ?? 0,
      navPrice: d.navPrice ?? 0,
      navChange1d: 0,
      navChangeRate1d: 0,
      navChange1w: 0,
      navChangeRate1w: 0,
    ),
    ret: FundReturn(
      baseDate: latestDate,
      r1m: d.return1m ?? 0,
      r3m: d.return3m ?? 0,
      r6m: d.return6m ?? 0,
      r12m: d.return12m ?? 0,
    ),
    asset: FundAssetSummary(
      baseDate: latestDate,
      stock: d.stockRatio ?? 0,
      bond: d.bondRatio ?? 0,
      cash: d.cashRatio ?? 0,
      etc: d.etcRatio ?? 0,
    ),
    docs: d.docs
        .map((x) => FundDocument(
      type: x.type,
      fileName: x.fileName ?? '',
      path: x.path ?? '',
      uploadedAt: latestDate,
    ))
        .toList(),
  );
}

/// ───────────────── 화면 본체 ─────────────────
class FundDetailScreen extends StatefulWidget {
  final String fundId;
  final String? title;
  const FundDetailScreen({super.key, required this.fundId, this.title});

  @override
  State<FundDetailScreen> createState() => _FundDetailScreenState();
}

class _FundDetailScreenState extends State<FundDetailScreen> {
  final _svc = FundService();
  final _scrollCtl = ScrollController();

  FundDetail? data;
  int _years = 1;
  int _monthly = 500000; // 50만원

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _svc.getFundDetail(widget.fundId);
      final net = res.data;
      if (net == null) throw Exception('상세 데이터가 없습니다.');
      setState(() => data = toUiDetail(net));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상세 로드 실패: $e')),
      );
    }
  }

  @override
  void dispose() {
    _scrollCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: tossBlue,)),
      );
    }
    final isUp = data!.daily.navChangeRate1d >= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9), // 아주 연한 회색
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: const Text('상품 정보', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: tossBlue, // 토스 블루
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {},
            child: const Text('가입하기', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollCtl,
        child: Column(
          children: [
            // ───── 상단: 펀드명 + 꺾은선 그래프
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data!.basic.fundName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${data!.basic.investmentRegion} · ${data!.basic.fundType}',
                    style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: .8,
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(10, 14, 10, 12),
                      child: SizedBox(height: 220, child: _ReturnLineChart()),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 기준가 & 위험수준 요약
                  _KeyFactsRow(
                    navPrice: data!.daily.navPrice,
                    navChangeRate1d: data!.daily.navChangeRate1d,
                    riskText: data!.basic.riskGrade,
                    isUp: isUp,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 이하 순차 리빌 애니메이션
            RevealOnScroll(
              controller: _scrollCtl,
              child: _SimpleDcaCard(
                years: _years,
                monthly: _monthly,
                onYears: (y) => setState(() => _years = y),
                onMonthly: (m) => setState(() => _monthly = m),
                assumedAnnualReturn: data!.ret.r12m / 100.0,
              ),
            ),

            const SizedBox(height: 12),

            // 위험 게이지: reveal 시 애니메이션
            RevealOnScroll(
              controller: _scrollCtl,
              delay: const Duration(milliseconds: 60),
              builder: (revealed) => _RiskCard(
                riskText: data!.basic.riskGrade,
                start: revealed,
              ),
            ),

            const SizedBox(height: 12),

            // 자산 도넛: reveal 시 애니메이션
            RevealOnScroll(
              controller: _scrollCtl,
              delay: const Duration(milliseconds: 120),
              builder: (revealed) => _AssetCard(
                asset: data!.asset,
                start: revealed,
              ),
            ),

            const SizedBox(height: 12),

            RevealOnScroll(
              controller: _scrollCtl,
              delay: const Duration(milliseconds: 180),
              child: _StockBondTable(
                stockPct: data!.asset.stock,
                bondPct: data!.asset.bond,
                baseDate: data!.asset.baseDate,
              ),
            ),

            const SizedBox(height: 12),

            RevealOnScroll(
              controller: _scrollCtl,
              delay: const Duration(milliseconds: 240),
              child: _FeeCards(
                fee: FundFeeInfo(
                  baseDate: data!.fee.baseDate,
                  managementFee: data!.fee.managementFee,
                  salesFee: data!.fee.salesFee,
                  adminFee: data!.fee.adminFee,
                  trustFee: data!.fee.trustFee,
                  totalFee: data!.fee.totalFee,
                  ter: data!.fee.ter,
                  frontLoadFee: data!.fee.frontLoadFee,
                  rearLoadFee: data!.fee.rearLoadFee,
                ),
              ),
            ),

            const SizedBox(height: 12),

            RevealOnScroll(
              controller: _scrollCtl,
              delay: const Duration(milliseconds: 300),
              child: _InfoCard(
                title: '상품 정보',
                rows: [
                  ('펀드 ID', data!.basic.fundId),
                  ('상품명', data!.basic.fundName),
                  ('상품분류', data!.basic.fundType),
                  ('구분', data!.basic.fundDivision),
                  ('투자지역', data!.basic.investmentRegion),
                  ('설정일', fmtDate(data!.basic.issueDate)),
                  ('운용사', data!.basic.managementCompany),
                  ('위험 등급', data!.basic.riskGrade),
                ],
              ),
            ),

            RevealOnScroll(
              controller: _scrollCtl,
              delay: const Duration(milliseconds: 360),
              child: _DocsCard(docs: data!.docs),
            ),

            const SizedBox(height: 12),

            RevealOnScroll(
              controller: _scrollCtl,
              delay: const Duration(milliseconds: 420),
              child: const _NoticeCard(
                items: [
                  '집합투자증권을 취득하시기 전에 투자대상, 보수, 수수료 및 환매방법 등에 관하여 (간이)투자설명서를 반드시 읽어보시기 바랍니다.',
                  '원금손실이 발생할 수 있으며, 그 손실은 투자자에게 귀속됩니다.',
                  '과거의 수익률이 미래의 수익률을 보장하지 않습니다.',
                ],
              ),
            ),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }
}

/// ──────────────── 꺾은선 그래프 (입장 애니메이션 + X축 균등)
class _ReturnLineChart extends StatefulWidget {
  const _ReturnLineChart();

  @override
  State<_ReturnLineChart> createState() => _ReturnLineChartState();
}

class _ReturnLineChartState extends State<_ReturnLineChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _curve =
  CurvedAnimation(parent: _ctl, curve: Curves.easeOutCubic);

  List<double> _fetchReturns() {
    final parent = context.findAncestorStateOfType<_FundDetailScreenState>();
    if (parent?.data == null) return [0, 0, 0, 0];
    final r = parent!.data!.ret;
    return [r.r1m, r.r3m, r.r6m, r.r12m];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctl.forward());
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vals = _fetchReturns(); // [%]
    double minVal = vals.reduce(math.min);
    double maxVal = vals.reduce(math.max);
    if (minVal == maxVal) {
      minVal -= 5;
      maxVal += 5;
    }
    final span = (maxVal - minVal).abs();
    final pad = span * 0.20 + 1;
    final double minY = math.min(0.0, minVal - pad);
    final double maxY = math.max(0.0, maxVal + pad);

    // 균등 간격: 0=1개월, 1=3개월, 2=6개월, 3=1년
    List<FlSpot> _spots(double t) =>
        List<FlSpot>.generate(4, (i) => FlSpot(i.toDouble(), vals[i] * t));

    String _label(int i) =>
        switch (i) { 0 => '1개월', 1 => '3개월', 2 => '6개월', _ => '1년' };

    double _intervalY() {
      final s = (maxY - minY).abs();
      if (s <= 10) return 2;
      if (s <= 20) return 5;
      if (s <= 40) return 10;
      return 20;
    }

    return AnimatedBuilder(
      animation: _curve,
      builder: (_, __) {
        final t = _curve.value;
        return LineChart(
          LineChartData(
            minX: 0,
            maxX: 3,
            minY: minY,
            maxY: maxY,
            backgroundColor: Colors.white,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              drawHorizontalLine: true,
              horizontalInterval: _intervalY(),
              getDrawingHorizontalLine: (v) => FlLine(
                color: v == 0 ? Colors.black38 : Colors.black12,
                strokeWidth: v == 0 ? 1.4 : 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v, _) => Text('${v.toStringAsFixed(0)}%'),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  interval: 1, // 0,1,2,3만
                  getTitlesWidget: (v, _) {
                    final i = v.round();
                    if (i < 0 || i > 3 || v != i.toDouble()) {
                      return const SizedBox.shrink();
                    }
                    return Text(_label(i), style: const TextStyle(fontWeight: FontWeight.w700));
                  },
                ),
              ),
            ),
            extraLinesData: ExtraLinesData(horizontalLines: [
              HorizontalLine(y: 0, color: Colors.black38, strokeWidth: 1.2),
            ]),
            lineTouchData: const LineTouchData(handleBuiltInTouches: true),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                barWidth: 3,
                spots: _spots(t),
                gradient: const LinearGradient(colors: [tossBlue300, tossBlue]),
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [tossBlue.withOpacity(.22), tossBlue.withOpacity(0.0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 그래프 아래 핵심 2카드
class _KeyBoxStyle {
  final bool shadow;
  const _KeyBoxStyle({this.shadow = true});
}

class _KeyFactsRow extends StatelessWidget {
  final double navPrice;
  final double navChangeRate1d;
  final String riskText;
  final bool isUp;
  final _KeyBoxStyle boxedStyle;
  const _KeyFactsRow({
    required this.navPrice,
    required this.navChangeRate1d,
    required this.riskText,
    required this.isUp,
    this.boxedStyle = const _KeyBoxStyle(),
  });

  int _riskLevelFromText(String s) {
    final m = RegExp(r'\((\d)\)').firstMatch(s);
    return m != null ? int.parse(m.group(1)!) : 3;
  }

  @override
  Widget build(BuildContext context) {
    final level = _riskLevelFromText(riskText).clamp(1, 5);
    const maxLevel = 5;
    final boxDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: boxedStyle.shadow
          ? [
        BoxShadow(
          color: Colors.black.withOpacity(.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        )
      ]
          : null,
    );

    return Row(
      children: [
        // 기준가
        Expanded(
          child: Container(
            height: 100,
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: boxDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '기준가 (전일대비)',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      (isUp ? '▲' : '▼') + ' ${navChangeRate1d.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isUp ? Colors.red : Colors.blue,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 28,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_won.format(navPrice)} 원',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // 위험수준 (Level N / 5)
        Expanded(
          child: Container(
            height: 100,
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: boxDecoration,
            child: Column(
              children: [
                const Text(
                  '위험수준',
                  style: TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Level', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Text('$level', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 간편 적립식 카드 — 문구: “n년간 이 상품에 매월 n만원씩 투자했다면?”
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('이 상품에'),
                _DD<int>(
                  value: years,
                  items: const [1, 3, 5],
                  labelBuilder: (v) => '$v년간',
                  onChanged: onYears,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 2줄: 매월 n만원씩 투자했다면?
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('매월'),
                _DD<int>(
                  value: monthly,
                  items: const [100000, 300000, 500000, 1000000],
                  labelBuilder: (v) => '${(v / 10000).round()}만원',
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
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

/// ───────────────────────────
/// 게이지: degree → radian
double _toRad(num deg) => deg.toDouble() * math.pi / 180.0;

/// 위험수준 카드 — 큰 게이지 + 활성 구간 라벨 칩(흰색 글자) + reveal 애니메이션
class _RiskCard extends StatelessWidget {
  final String riskText;
  final bool start; // reveal 시 true
  const _RiskCard({required this.riskText, this.start = false});

  int _riskLevelFromText(String s) {
    final m = RegExp(r'\((\d)\)').firstMatch(s);
    return m != null ? int.parse(m.group(1)!) : 3;
  }

  String _riskDescription(int level) {
    switch (level) {
      case 1:
        return '위험이 매우 낮은 단계(보수적)';
      case 2:
        return '위험이 낮은 단계';
      case 3:
        return '보통 수준의 위험';
      case 4:
        return '위험이 높은 단계(공격적)';
      default:
        return '위험이 매우 높은 단계(매우 공격적)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = _riskLevelFromText(riskText).clamp(1, 5);
    const maxLevel = 5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: .6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('위험수준', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200, // 게이지 크기
                width: double.infinity,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: start ? 1 : 0),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, t, __) => CustomPaint(
                    painter: _SegmentGaugePainter(
                      level: level,
                      maxLevel: maxLevel,

                      // 형태(내부 텍스트 공간 넉넉)
                      coverage: 0.96,
                      stroke: 28,
                      gap: _toRad(3),   // ⬅️ 세그먼트 간격(더 촘촘하게)
                      padding: 6,

                      // 색상 — 🔴 빨간색
                      inactiveColor: const Color(0xFFE7E9EE),
                      activeColor: const Color(0xFFEF4444),

                      // 배경이 어두워도 가독성 유지
                      drawUnderlay: true,
                      underlayColor: Colors.white70,

                      // 라벨(활성 구간 칩 + 흰색 텍스트)
                      showLabelChip: true,
                      labelChipColor: const Color(0xB3000000),
                      labelTextColor: Colors.white,
                      labelFontSize: 16,
                      labelRadialFactor: .50,
                      labels: const ['매우 낮음', '낮음', '보통', '높음', '매우 높음'],

                      // 애니메이션 진행도
                      progress: t,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text('Level $level / $maxLevel',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              // 등급 텍스트 + 설명
              Text(
                '위험 등급: ${level}등급 · 1(낮음) ~ $maxLevel(높음)\n${_riskDescription(level)}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 반원 세그먼트 게이지 (세그먼트/라벨/언더레이 지원, 🔴 빨강 적용, progress로 스윕 애니메이션)
class _SegmentGaugePainter extends CustomPainter {
  final int level, maxLevel;

  // 형태
  final double stroke;      // 링 두께
  final double gap;         // 세그먼트 간격(라디안)
  final double coverage;    // 반원 사용 비율(0~1)
  final double padding;     // 캔버스 가장자리와의 여백(아크 외곽 기준)

  // 색
  final Color activeColor, inactiveColor;

  // 언더레이
  final bool drawUnderlay;
  final Color underlayColor;

  // 라벨
  final List<String> labels;
  final bool showLabelChip;
  final Color labelChipColor;
  final Color labelTextColor;
  final EdgeInsets labelChipPadding;
  final double labelFontSize;
  final double labelRadialFactor; // 0(중심)~1(바깥)

  // 진행도(0~1): 활성 세그먼트 스윕/라벨 페이드
  final double progress;

  _SegmentGaugePainter({
    required this.level,
    this.maxLevel = 5,
    this.stroke = 28,
    this.gap = 0.12,
    this.coverage = 0.96,
    this.padding = 6,
    this.activeColor = const Color(0xFFEF4444), // 🔴
    this.inactiveColor = const Color(0xFFE7E9EE),
    this.drawUnderlay = true,
    this.underlayColor = Colors.white70,
    this.labels = const ['매우 낮음', '낮음', '보통', '높음', '매우 높음'],
    this.showLabelChip = true,
    this.labelChipColor = const Color(0x99000000),
    this.labelTextColor = Colors.white,
    this.labelChipPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.labelFontSize = 16,
    this.labelRadialFactor = .50,
    this.progress = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    // 반지름을 최대화(하단 기준) — 내부 텍스트 공간 확보
    final double maxRByWidth = size.width / 2 - padding;
    final double maxRByHeight = size.height - padding;
    final double r = math.min(maxRByWidth, maxRByHeight);

    final Offset c = Offset(size.width / 2, size.height - padding);
    final Rect arc = Rect.fromCircle(center: c, radius: r);

    final totalSweep = math.pi * coverage;
    final start = math.pi + (math.pi - totalSweep) / 2; // 중앙 정렬
    final sweepPer = totalSweep / maxLevel;
    final int activeIdx = ((level - 1).clamp(0, maxLevel - 1)).toInt();

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // 언더레이 — 배경색과 분리
    if (drawUnderlay) {
      final u = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 8
        ..strokeCap = StrokeCap.butt
        ..color = underlayColor.withOpacity(0.3 + 0.7 * p);
      canvas.drawArc(arc, start, totalSweep, false, u);
    }

    // 비활성 세그먼트 (페이드 인)
    for (int i = 0; i < maxLevel; i++) {
      final s = start + i * sweepPer + gap / 2;
      final sw = sweepPer - gap;
      canvas.drawArc(arc, s, sw, false, base..color = inactiveColor.withOpacity(0.25 + 0.75 * p));
    }

    // 활성 세그먼트 (스윕 0→목표)
    final aStart = start + activeIdx * sweepPer + gap / 2;
    final aSweep = (sweepPer - gap) * p;
    canvas.drawArc(arc, aStart, aSweep, false, base..color = activeColor);

    // 라벨 (진행도에 따라 페이드/칩 노출)
    for (int i = 0; i < maxLevel; i++) {
      final mid = start + i * sweepPer + sweepPer / 2;
      final rMid = r - stroke * labelRadialFactor;
      final pos = Offset(c.dx + rMid * math.cos(mid), c.dy + rMid * math.sin(mid));

      final isActive = i == activeIdx;
      final text = (i < labels.length) ? labels[i] : 'L${i + 1}';

      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: (isActive ? labelTextColor : const Color(0xFF9AA1AE))
                .withOpacity(isActive ? p : 0.6 * p),
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
            fontSize: isActive ? labelFontSize : (labelFontSize - 2),
            shadows: isActive && p > .7 ? const [Shadow(blurRadius: 2, color: Colors.black38)] : null,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      if (isActive && showLabelChip && p > .7) {
        final bg = Rect.fromCenter(
          center: pos,
          width: tp.width + labelChipPadding.horizontal,
          height: tp.height + labelChipPadding.vertical,
        );
        final rr = RRect.fromRectAndRadius(bg, Radius.circular(bg.height / 2));
        final chip = Paint()..color = labelChipColor.withOpacity(p);
        canvas.drawRRect(rr, chip);
        // 테두리 살짝
        canvas.drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = Colors.white.withOpacity(.55 * p),
        );
      }

      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentGaugePainter o) =>
      o.level != level ||
          o.maxLevel != maxLevel ||
          o.stroke != stroke ||
          o.gap != gap ||
          o.coverage != coverage ||
          o.padding != padding ||
          o.activeColor != activeColor ||
          o.inactiveColor != inactiveColor ||
          o.drawUnderlay != drawUnderlay ||
          o.underlayColor != underlayColor ||
          o.labels != labels ||
          o.showLabelChip != showLabelChip ||
          o.labelChipColor != labelChipColor ||
          o.labelTextColor != labelTextColor ||
          o.labelFontSize != labelFontSize ||
          o.labelRadialFactor != labelRadialFactor ||
          o.progress != progress;
}

/// 자산 구성 — 도넛 + 표 (주식은 토스블루) + reveal 애니메이션
class _AssetCard extends StatelessWidget {
  final FundAssetSummary asset;
  final bool start; // reveal 시 true
  const _AssetCard({required this.asset, this.start = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: .6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('자산 구성 비율', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 55),
              LayoutBuilder(
                builder: (context, c) {
                  final size = math.min(c.maxWidth, 180.0);
                  return SizedBox(
                    height: size + 8,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: start ? 1 : 0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (_, t, __) => Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              centerSpaceRadius: size * 0.42,
                              sectionsSpace: 2,
                              sections: _pieSectionsAnimated(asset, size, t),
                            ),
                          ),
                          Opacity(
                            opacity: t,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(fmtDate(asset.baseDate),
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                                const Text('기준',
                                    style:
                                    TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 50),
              _AssetTable(
                rows: const [
                  ('주식', tossBlue), // 주식 토스블루
                  ('채권', Color(0xFF16A34A)), // green
                  ('유동성', Color(0xFFF59E0B)), // amber
                  ('기타', Color(0xFF6B7280)), // gray
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

List<PieChartSectionData> _pieSectionsAnimated(FundAssetSummary a, double size, double t) {
  final colorMap = <String, Color>{
    '주식': tossBlue,
    '채권': const Color(0xFF16A34A),
    '유동성': const Color(0xFFF59E0B),
    '기타': const Color(0xFF6B7280),
  };

  final items = [
    ('주식', a.stock),
    ('채권', a.bond),
    ('유동성', a.cash),
    ('기타', a.etc),
  ].where((e) => e.$2 > 0).toList();

  if (items.isEmpty) items.add(('기타', 100.0));
  final maxVal = items.map((e) => e.$2).reduce(math.max);

  return List.generate(items.length, (i) {
    final it = items[i];
    final isMax = it.$2 == maxVal;
    final baseR = (size * 0.26) + (isMax ? 8 : 0);
    return PieChartSectionData(
      value: it.$2,
      color: colorMap[it.$1]!,
      radius: baseR * t, // 반지름 0→목표
      title: '${it.$1}\n${it.$2.toStringAsFixed(1)}%',
      titleStyle: TextStyle(color: Colors.white.withOpacity(t), fontSize: 13, fontWeight: FontWeight.w700),
      titlePositionPercentageOffset: .48,
      badgePositionPercentageOffset: 1.0,
    );
  });
}

/// (기존 정적 섹션이 필요하면 사용)
List<PieChartSectionData> _pieSections(FundAssetSummary a, double size) {
  final colorMap = <String, Color>{
    '주식': tossBlue,
    '채권': const Color(0xFF16A34A),
    '유동성': const Color(0xFFF59E0B),
    '기타': const Color(0xFF6B7280),
  };

  final items = [
    ('주식', a.stock),
    ('채권', a.bond),
    ('유동성', a.cash),
    ('기타', a.etc),
  ].where((e) => e.$2 > 0).toList();

  if (items.isEmpty) items.add(('기타', 100.0));
  final maxVal = items.map((e) => e.$2).reduce(math.max);

  return List.generate(items.length, (i) {
    final it = items[i];
    final isMax = it.$2 == maxVal;
    return PieChartSectionData(
      value: it.$2,
      color: colorMap[it.$1]!,
      radius: (size * 0.26) + (isMax ? 8 : 0),
      title: '${it.$1}\n${it.$2.toStringAsFixed(1)}%',
      titleStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
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
    'bond' => asset.bond,
    'cash' => asset.cash,
    _ => asset.etc,
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
      child: SizedBox(
        width: double.infinity,
        child: Card(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: .6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('주식 및 채권 보유 비중', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowHeight: 35,
                    dataRowMinHeight: 32,
                    dataRowMaxHeight: 36,
                    columns: const [
                      DataColumn(label: Text('자산')),
                      DataColumn(label: Text('비중')),
                      DataColumn(label: Text('기준일'))
                    ],
                    rows: [
                      DataRow(cells: [
                        const DataCell(Text('주식')),
                        DataCell(Text('${stockPct.toStringAsFixed(1)}%')),
                        DataCell(Text(fmtDate(baseDate)))
                      ]),
                      DataRow(cells: [
                        const DataCell(Text('채권')),
                        DataCell(Text('${bondPct.toStringAsFixed(1)}%')),
                        DataCell(Text(fmtDate(baseDate)))
                      ]),
                    ],
                  ),
                ),
              ],
            ),
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
    Widget block(
        String title,
        List<(String, String)> rows, {
          Color bg = Colors.white,
          Color borderColor = Colors.black12,
        }) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: tossBlue)),
            const SizedBox(height: 8),
            ...rows.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(e.$1, style: const TextStyle(height: 1.2))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.$2,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700, height: 1.2),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: .6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: LayoutBuilder(
              builder: (context, c) {
                final isNarrow = c.maxWidth < 360;
                final children = [
                  block('매입할 때', [
                    ('선취판매수수료', _feeText(fee.frontLoadFee)),
                  ], bg: blueSoft, borderColor: tossBlue.withOpacity(.25)),
                  block('투자기간동안', [
                    ('총 보수(연)', fmtPercent(fee.totalFee, digits: 3)),
                    ('총비용비율(TER)', fmtPercent(fee.ter, digits: 4)),
                    ('운용보수', fmtPercent(fee.managementFee, digits: 3)),
                    ('판매보수', fmtPercent(fee.salesFee, digits: 3)),
                    ('일반사무관리보수', fmtPercent(fee.adminFee, digits: 3)),
                    ('수탁보수', fmtPercent(fee.trustFee, digits: 3)),
                  ], bg: blueSoft, borderColor: tossBlue.withOpacity(.25)),
                  block('환매할 때', [
                    ('후취판매수수료', _feeText(fee.rearLoadFee)),
                    ('환매수수료', '수수료없음'),
                  ], bg: blueSoft, borderColor: tossBlue.withOpacity(.25)),
                ];

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('보수 및 수수료 · 기준 ${fmtDate(fee.baseDate)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      ...children.expand((w) => [w, const SizedBox(height: 8)]).toList()..removeLast(),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('보수 및 수수료 · 기준 ${fmtDate(fee.baseDate)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
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
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: .6,
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

/// 공시자료 카드 (타입 한글화 + PNG 아이콘) — 파일명 아래 줄에 업로드일자
class FundDocumentUI {
  final String type, fileName, path;
  final DateTime uploadedAt;
  FundDocumentUI({required this.type, required this.fileName, required this.path, required this.uploadedAt});
}

String _localizeDocType(String type) {
  final t = type.toLowerCase();
  if (t.contains('summary')) return '간이투자설명서';
  if (t.contains('terms')) return '이용약관';
  if (t.contains('prospectus') || t.contains('설명서')) return '투자설명서';
  if (t.contains('report')) return '보고서';
  return type; // 기본 그대로
}

class _DocsCard extends StatelessWidget {
  final List<FundDocument> docs;
  const _DocsCard({required this.docs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: .6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('공시자료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('등록된 공시자료가 없습니다.', style: TextStyle(color: Colors.black54)),
                ),
              ...docs.map((d) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Image.asset(
                  'assets/icons/ic_pdf.png', // PNG 아이콘
                  width: 22,
                  height: 22,
                  filterQuality: FilterQuality.medium,
                ),
                title: Text(_localizeDocType(d.type)),
                isThreeLine: true,
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      d.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '업로드 ${fmtDate(d.uploadedAt)}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final raw = d.path;
                  if (raw.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('파일 경로가 없습니다.')),
                      );
                    }
                    return;
                  }
                  final base = ApiConfig.baseUrl;
                  final uri = _buildDocUri(base, raw);
                  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('파일을 열 수 없습니다.')),
                    );
                  }
                },
              )),
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

/// 스크롤 시 뷰포트에 들어오면 슬라이드+페이드로 나타나는 위젯
/// + builder(revealed)를 통해 자식에게 "보임" 신호 전달
class RevealOnScroll extends StatefulWidget {
  final Widget? child;
  final Widget Function(bool revealed)? builder;
  final ScrollController controller;
  final Duration duration;
  final Duration? delay;
  final double triggerOffset;

  const RevealOnScroll({
    super.key,
    required this.controller,
    this.child,
    this.builder,
    this.duration = const Duration(milliseconds: 380),
    this.delay,
    this.triggerOffset = 60,
  }) : assert(child != null || builder != null);

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac =
  AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve =
  CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);

  bool _revealed = false;

  void _tryReveal() {
    if (_revealed) return;
    final render = context.findRenderObject();
    if (render is! RenderBox || !render.attached) return;

    final pos = render.localToGlobal(Offset.zero);
    final h = MediaQuery.of(context).size.height;
    final visible = pos.dy < h - widget.triggerOffset;
    if (visible) {
      _revealed = true;
      if (widget.delay != null) {
        Future.delayed(widget.delay!, () => _ac.forward());
      } else {
        _ac.forward();
      }
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryReveal());
    widget.controller.addListener(_tryReveal);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_tryReveal);
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.builder != null ? widget.builder!(_revealed) : widget.child!;
    final slide = Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(_curve);
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(position: slide, child: content),
    );
  }
}
