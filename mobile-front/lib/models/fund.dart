class Fund {
  final int id;
  final String name;
  final double rate;
  final int balance;

  bool featured;          // 홈 화면에 노출할 펀드

  Fund({
    required this.id,
    required this.name,
    required this.rate,
    required this.balance,
    this.featured = true,  // 기본값: 노출
  });

  factory Fund.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;

    int parseInt(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    return Fund(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      rate: parseDouble(json['rate']),
      balance: parseInt(json['balance']),
      featured: json['featured'] ?? true,
    );
  }
}