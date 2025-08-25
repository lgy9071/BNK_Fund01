class BankAccountNet {
  final int accountId;
  final String accountName;
  final String accountNumber;
  final int balance;
  final DateTime? createdAt; // 서버 포맷에 따라 null 허용
  final String status;
  final int userId;

  BankAccountNet({
    required this.accountId,
    required this.accountName,
    required this.accountNumber,
    required this.balance,
    required this.createdAt,
    required this.status,
    required this.userId,
  });

  factory BankAccountNet.fromJson(Map<String, dynamic> j) {
    int _toInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return BankAccountNet(
      accountId: _toInt(j['account_id'] ?? j['accountId'] ?? j['ACCOUNT_ID']),
      accountName:
      (j['account_name'] ?? j['accountName'] ?? j['ACCOUNT_NAME'] ?? '') as String,
      accountNumber:
      (j['account_number'] ?? j['accountNumber'] ?? j['ACCOUNT_NUMBER'] ?? '') as String,
      balance: _toInt(j['balance'] ?? j['BALANCE']),
      createdAt: _toDate(j['created_at'] ?? j['createdAt'] ?? j['CREATED_AT']),
      status: (j['status'] ?? j['STATUS'] ?? '') as String,
      userId: _toInt(j['user_id'] ?? j['userId'] ?? j['USER_ID']),
    );
  }
}