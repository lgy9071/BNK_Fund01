import 'dart:convert';

/// 백엔드 상세 DTO와 1:1 매핑 모델 (네트워크 전용)
class FundDocNet {
  final String type;         // "SUMMARY" | "PROSPECTUS" | "TERMS"
  final String? fileName;    // 서버에서 내려준 원본 파일명(옵션)
  final String? path;        // "/fund_document/....pdf" 또는 절대 URL

  FundDocNet({required this.type, this.fileName, this.path});

  factory FundDocNet.fromJson(Map<String, dynamic> j) => FundDocNet(
    type: j['type']?.toString() ?? '',
    fileName: j['fileName']?.toString(),
    path: j['path']?.toString(),
  );
}

class FundDetailNet {
  final String fundId;
  final String fundName;
  final String? fundType, fundDivision, investmentRegion, salesRegionType, managementCompany, fundStatus;
  final int? riskLevel;
  final String? issueDate;
  final double? minSubscriptionAmount;

  final String? latestBaseDate;
  final double? navPrice, navTotal, originalPrincipal;

  final double? return1m, return3m, return6m, return12m;

  final double? stockRatio, bondRatio, cashRatio, etcRatio;

  final double? totalFee, ter;

  // product.docs
  final List<FundDocNet> docs;

  FundDetailNet({
    required this.fundId,
    required this.fundName,
    this.fundType,
    this.fundDivision,
    this.investmentRegion,
    this.salesRegionType,
    this.managementCompany,
    this.fundStatus,
    this.riskLevel,
    this.issueDate,
    this.minSubscriptionAmount,
    this.latestBaseDate,
    this.navPrice,
    this.navTotal,
    this.originalPrincipal,
    this.return1m,
    this.return3m,
    this.return6m,
    this.return12m,
    this.stockRatio,
    this.bondRatio,
    this.cashRatio,
    this.etcRatio,
    this.totalFee,
    this.ter,
    this.docs = const [],
  });

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _i(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory FundDetailNet.fromJson(Map<String, dynamic> j) {
    double? dnum(dynamic v) => (v as num?)?.toDouble();

    // product.docs 파싱
    final product = j['product'] as Map<String, dynamic>?;
    final docsJson = (product?['docs'] as List?) ?? const [];
    final docs = docsJson
        .whereType<Map<String, dynamic>>()
        .map((e) => FundDocNet.fromJson(e))
        .toList();

    return FundDetailNet(
      fundId: j['fundId']?.toString() ?? '',
      fundName: j['fundName']?.toString() ?? '',
      fundType: j['fundType']?.toString(),
      fundDivision: j['fundDivision']?.toString(),
      investmentRegion: j['investmentRegion']?.toString(),
      salesRegionType: j['salesRegionType']?.toString(),
      managementCompany: j['managementCompany']?.toString(),
      fundStatus: j['fundStatus']?.toString(),
      riskLevel: _i(j['riskLevel']),
      issueDate: j['issueDate']?.toString(),
      minSubscriptionAmount: dnum(j['minSubscriptionAmount']),
      latestBaseDate: j['latestBaseDate']?.toString(),
      navPrice: dnum(j['nav'] ?? j['navPrice']),
      navTotal: dnum(j['aum'] ?? j['navTotal']),
      originalPrincipal: dnum(j['originalPrincipal']),
      return1m: dnum(j['return1m']),
      return3m: dnum(j['return3m']),
      return6m: dnum(j['return6m']),
      return12m: dnum(j['return12m']),
      stockRatio: dnum(j['domesticStock'] ?? j['stockRatio']),
      bondRatio: dnum(j['domesticBond'] ?? j['bondRatio']),
      cashRatio: dnum(j['liquidity'] ?? j['cashRatio']),
      etcRatio: dnum(j['etcRatio']),
      totalFee: dnum(j['totalFee']),
      ter: dnum(j['ter'] ?? j['totalExpenseRatio']),
      docs: docs, // 여기 담김
    );
  }
}
