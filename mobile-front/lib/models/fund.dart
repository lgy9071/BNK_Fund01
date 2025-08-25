class Fund {
  final int id;
  final String name;
  final double rate;
  final int balance;
  final DateTime? joinedDate;  // 🆕 가입일 추가
  final String? fundCode;      // 🆕 펀드 코드 추가
  bool featured;

  Fund({
    required this.id,
    required this.name,
    required this.rate,
    required this.balance,
    this.joinedDate,
    this.fundCode,
    this.featured = true,  // 기본값: 노출
  });

  // 🆕 JSON 파싱 메서드 추가
  factory Fund.fromJson(Map<String, dynamic> json) {
    return Fund(
      id: json['fundId'] ?? 0,
      name: json['fundName'] ?? '',
      rate: (json['currentRate'] ?? 0.0).toDouble(),
      balance: json['currentBalance'] ?? 0,
      joinedDate: json['joinedDate'] != null
          ? DateTime.tryParse(json['joinedDate'])
          : null,
      fundCode: json['fundCode'],
      featured: json['featured'] ?? true,
    );
  }
}

/*

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

*/