// 백엔드 FundListResponseDTO와 1:1
class FundListItem {
  final String fundId;
  final String fundName;
  final String? fundType;
  final String? fundDivision;
  final int? riskLevel;
  final String? managementCompany;
  final String? issueDate;       // yyyy-MM-dd
  final double? return1m;
  final double? return3m;
  final double? return12m;

  FundListItem({
    required this.fundId,
    required this.fundName,
    this.fundType,
    this.fundDivision,
    this.riskLevel,
    this.managementCompany,
    this.issueDate,
    this.return1m,
    this.return3m,
    this.return12m,
  });

  factory FundListItem.fromJson(Map<String, dynamic> j) => FundListItem(
    fundId: j['fundId'],
    fundName: j['fundName'],
    fundType: j['fundType'],
    fundDivision: j['fundDivision'],
    riskLevel: j['riskLevel'],
    managementCompany: j['managementCompany'],
    issueDate: j['issueDate'],
    return1m: (j['return1m'] as num?)?.toDouble(),
    return3m: (j['return3m'] as num?)?.toDouble(),
    return12m: (j['return12m'] as num?)?.toDouble(),
  );
}
