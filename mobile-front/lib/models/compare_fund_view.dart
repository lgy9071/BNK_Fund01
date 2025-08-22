class CompareFundView {
  final String fundId;
  final String name;
  final String type;                 // 펀드유형
  final String? managementCompany;   // 운용사
  final String? riskText;            // "위험(2등급)" 같은 텍스트 (없으면 null)
  final double return1m;
  final double return3m;
  final double return12m;

  const CompareFundView({
    required this.fundId,
    required this.name,
    required this.type,
    required this.managementCompany,
    required this.riskText,
    required this.return1m,
    required this.return3m,
    required this.return12m,
  });
}
