import 'dart:convert';

/// 공시자료(네트워크 모델)
class FundDocNet {
  final String type;      // "SUMMARY" | "PROSPECTUS" | "TERMS"
  final String? fileName; // 원본 파일명
  final String? path;     // "/fund_document/..." 또는 절대 URL

  FundDocNet({required this.type, this.fileName, this.path});

  factory FundDocNet.fromJson(Map<String, dynamic> j) => FundDocNet(
    type: j['type']?.toString() ?? '',
    fileName: j['fileName']?.toString(),
    path: j['path']?.toString(),
  );
}

/// 상세(네트워크 모델) — 백엔드 DTO와 1:1
class FundDetailNet {
  final int? productId;
  final String fundId;
  final String fundName;
  final String? fundType, fundDivision, investmentRegion, salesRegionType,
      managementCompany, fundStatus;
  final int? riskLevel;
  final String? issueDate;
  final double? minSubscriptionAmount;

  final String? latestBaseDate;
  final double? navPrice, navTotal, originalPrincipal;

  final double? return1m, return3m, return6m, return12m;

  final double? stockRatio, bondRatio, cashRatio, etcRatio;

  final double? totalFee, ter;

  /// product.docs 를 평탄화해서 넣는다
  final List<FundDocNet> docs;

  FundDetailNet({
    required this.fundId,
    required this.fundName,
    this.productId,
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

  /// ---- 안전한 docs 파서 (제네릭 불일치/문자열 JSON까지 처리)
  static List<FundDocNet> _parseDocs(dynamic v) {
    if (v is List) {
      return v.map((e) {
        if (e is Map) {
          return FundDocNet.fromJson(Map<String, dynamic>.from(e));
        }
        if (e is String) {
          try {
            final dec = json.decode(e);
            if (dec is Map) {
              return FundDocNet.fromJson(Map<String, dynamic>.from(dec));
            }
          } catch (_) {}
        }
        return null;
      }).whereType<FundDocNet>().toList();
    }
    return const <FundDocNet>[];
  }

  factory FundDetailNet.fromJson(Map<String, dynamic> j) {
    double? dnum(dynamic v) => (v as num?)?.toDouble();

    // product.docs 파싱
    final product = j['product'];
    final docs = (product is Map) ? _parseDocs(product['docs']) : const <FundDocNet>[];

    // ✅ productId는 응답 최상위 or product 블록 어느 쪽이든 받도록 방어적으로 처리
    final pid = _i(j['productId']) ?? (product is Map ? _i(product['productId']) : null);

    return FundDetailNet(
      productId: pid,
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
      docs: docs,
    );
  }
}
