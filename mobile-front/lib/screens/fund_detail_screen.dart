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
      backgroundColor: Colors.white,
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

                  // 파란 테두리 없이, 기존 2카드로 분리
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

            RevealOnScroll(
              controller: _scrollCtl,
              delay: const Duration(milliseconds: 60),
              child: _RiskCard(riskText: data!.basic.riskGrade),
            ),

            const SizedBox(height: 12),

            RevealOnScroll(
              controller: _scrollCtl,
              delay: const Duration(milliseconds: 120),
              child: _AssetCard(asset: data!.asset),
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

    // 균등 간격: 0=1M, 1=3M, 2=6M, 3=1Y
    List<FlSpot> _spots(double t) =>
        List<FlSpot>.generate(4, (i) => FlSpot(i.toDouble(), vals[i] * t));

    String _label(int i) => switch (i) { 0 => '1M', 1 => '3M', 2 => '6M', _ => '1Y' };

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
            minX: 0, maxX: 3,
            minY: minY, maxY: maxY,
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
                    if (i < 0 || i > 3 || v != i.toDouble()) return const SizedBox.shrink();
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
        // 위험수준
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
                    const Text('레벨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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

/// 간편 적립식 카드
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
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
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
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: .6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('위험수준', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 140,
                    height: 170,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 46,
                        sectionsSpace: 2,
                        sections: [
                          PieChartSectionData(value: level.toDouble(), color: Colors.red, radius: 18, title: ''),
                          PieChartSectionData(value: (5 - level).toDouble(), color: Colors.grey[300], radius: 18, title: ''),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DataTable(
                      columnSpacing: 24, // 줄바꿈 방지 여유
                      headingRowHeight: 28,
                      dataRowMinHeight: 32,
                      dataRowMaxHeight: 36,
                      columns: const [
                        DataColumn(label: Text('항목')),
                        DataColumn(label: Text('값')),
                      ],
                      rows: [
                        DataRow(cells: [
                          const DataCell(Text('적용기간')),
                          const DataCell(Text('1년', maxLines: 1, softWrap: false)), // "1 년" 줄바꿈 방지
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('위험레벨(1~5)')),
                          DataCell(Text('$level')),
                        ]),
                        DataRow(cells: [
                          const DataCell(Text('설명')),
                          DataCell(Text(riskText)),
                        ]),
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
              const SizedBox(height: 40),
              LayoutBuilder(
                builder: (context, c) {
                  final size = math.min(c.maxWidth, 180.0);
                  return SizedBox(
                    height: size + 8,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            centerSpaceRadius: size * 0.42,
                            sectionsSpace: 2,
                            sections: _pieSections(asset, size),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(fmtDate(asset.baseDate),
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                            const Text('기준',
                                style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600)),
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

/// 보수 및 수수료 — 3블록 카드 (가운데 블록 기존 색 유지)
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

/// 공시자료 카드
class FundDocumentUI {
  final String type, fileName, path;
  final DateTime uploadedAt;
  FundDocumentUI({required this.type, required this.fileName, required this.path, required this.uploadedAt});
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
                leading: const Icon(Icons.description_outlined),
                title: Text(d.type),
                subtitle: Text('${d.fileName} · 업로드 ${fmtDate(d.uploadedAt)}'),
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
class RevealOnScroll extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final Duration duration;
  final Duration? delay;
  final double triggerOffset;

  const RevealOnScroll({
    super.key,
    required this.child,
    required this.controller,
    this.duration = const Duration(milliseconds: 380),
    this.delay,
    this.triggerOffset = 60,
  });

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
    final slide = Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(_curve);
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(position: slide, child: widget.child),
    );
  }
}
