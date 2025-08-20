//백엔드 상세와 1:1; 필드명은 백엔드 최종 DTO에 맞추기
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
    double? d(dynamic v) => (v as num?)?.toDouble();
    return FundDetailNet(
      fundId: j['fundId']?.toString() ?? '',
      fundName: j['fundName']?.toString() ?? '',
      fundType: j['fundType'],
      fundDivision: j['fundDivision'],
      investmentRegion: j['investmentRegion'],
      salesRegionType: j['salesRegionType'],
      managementCompany: j['managementCompany'],
      fundStatus: j['fundStatus'],
      riskLevel: j['riskLevel'],
      issueDate: j['issueDate'],
      minSubscriptionAmount: d(j['minSubscriptionAmount']),
      latestBaseDate: j['latestBaseDate'],
      navPrice: d(j['nav'] ?? j['navPrice']),
      navTotal: d(j['aum'] ?? j['navTotal']),
      originalPrincipal: d(j['originalPrincipal']),
      return1m: d(j['return1m']),
      return3m: d(j['return3m']),
      return6m: d(j['return6m']),
      return12m: d(j['return12m']),
      stockRatio: d(j['domesticStock'] ?? j['stockRatio']),
      bondRatio: d(j['domesticBond'] ?? j['bondRatio']),
      cashRatio: d(j['liquidity'] ?? j['cashRatio']),
      etcRatio: d(j['etcRatio']),
      totalFee: d(j['totalFee']),
      // TER 필드명 통합
      ter: d(j['ter'] ?? j['totalExpenseRatio']),
    );
  }
}
