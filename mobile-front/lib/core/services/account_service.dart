// lib/core/services/account_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_front/core/constants/api.dart';
import 'package:mobile_front/models/bank_account_net.dart';

class AccountService {
  final http.Client _client;
  static const _secure = FlutterSecureStorage();
  AccountService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, String>> _authHeaders({bool json = false}) async {
    final at = await _secure.read(key: 'accessToken');
    debugPrint('[AUTH] hasBearer=${at != null && at.isNotEmpty}');
    return {
      if (json) 'Content-Type': 'application/json',
      if (at != null && at.isNotEmpty) 'Authorization': 'Bearer $at',
    };
  }

  Future<http.Response> _get(Uri uri) async {
    debugPrint('[GET] $uri');
    final res = await _client.get(uri, headers: await _authHeaders());
    debugPrint('[RES] ${res.statusCode} ${res.body}');
    return res;
  }

  List<BankAccountNet> _parseAccounts(String body) {
    final root = jsonDecode(body);
    final list = root is Map<String, dynamic>
        ? (root['data'] as List? ?? const [])
        : (root as List? ?? const []);
    return list.map((e) => BankAccountNet.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 서버에 맞춘 목록 조회: GET /api/deposit?userId=123
  Future<List<BankAccountNet>> getDepositAccountsByUser(String userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/deposit')
        .replace(queryParameters: {'userId': userId});
    final res = await _get(uri);
    if (res.statusCode == 200) {
      return _parseAccounts(res.body);
    }
    // 계좌가 없을 때 404를 주는 구현이라면 ‘빈 리스트’로 처리 (오류 아님)
    if (res.statusCode == 404) return const [];
    throw Exception('계좌 조회 실패: ${res.statusCode} ${res.body}');
  }
}
