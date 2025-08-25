// lib/core/services/fund_service.dart
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_front/core/constants/api.dart';
import 'package:mobile_front/models/api_response.dart';
import 'package:mobile_front/models/fund_detail_net.dart';
import 'package:mobile_front/models/fund_list_item.dart';

import '../../models/fund.dart';

class FundService {
  final http.Client _client;
  static const _secure = FlutterSecureStorage();

  FundService({http.Client? client}) : _client = client ?? http.Client();

  // ① 공통 헤더 (Authorization 포함)
  Future<Map<String, String>> _authHeaders({bool json = false}) async {
    final at = await _secure.read(key: 'accessToken');
    return {
      if (json) 'Content-Type': 'application/json',
      if (at != null && at.isNotEmpty) 'Authorization': 'Bearer $at',
    };
  }

  // ② 401 나오면 refresh 후 1회 재시도
  Future<bool> _refreshTokens() async {
    final rt = await _secure.read(key: 'refreshToken');
    if (rt == null || rt.isEmpty) return false;

    final res = await _client.post(
      Uri.parse(ApiConfig.refresh),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': rt}),
    );
    if (res.statusCode != 200) return false;

    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final newAccess = (j['accessToken'] ?? j['access_token']) as String?;
    final newRefresh = (j['refreshToken'] ?? j['refresh_token']) as String?;

    if (newAccess == null || newAccess.isEmpty) return false;

    await _secure.write(key: 'accessToken', value: newAccess);
    if (newRefresh != null && newRefresh.isNotEmpty) {
      await _secure.write(key: 'refreshToken', value: newRefresh);
    }
    return true;
  }

  // 공통 GET (401 시 refresh → 재시도)
  Future<http.Response> _get(Uri uri) async {
    var res = await _client.get(uri, headers: await _authHeaders());
    if (res.statusCode != 401) return res;

    final ok = await _refreshTokens();
    if (!ok) return res;
    return await _client.get(uri, headers: await _authHeaders());
  }

  // 공통 POST (401 시 refresh → 재시도)
  Future<http.Response> _post(Uri uri, {Object? body, bool json = false}) async {
    var res = await _client.post(uri, headers: await _authHeaders(json: json), body: body);
    if (res.statusCode != 401) return res;

    final ok = await _refreshTokens();
    if (!ok) return res;
    return await _client.post(uri, headers: await _authHeaders(json: json), body: body);
  }

  // ③ 실제 API들
  Future<ApiResponse<List<FundListItem>>> getFunds({
    String? keyword,
    int page = 0,
    int size = 10,
    String? fundType,
    int? riskLevel,
    String? company,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'size': '$size',
      if (keyword?.isNotEmpty == true) 'keyword': keyword!,
      if (fundType?.isNotEmpty == true) 'fundType': fundType!,
      if (riskLevel != null) 'riskLevel': '$riskLevel',
      if (company?.isNotEmpty == true) 'company': company!,
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/funds')
        .replace(queryParameters: query);

    final res = await _get(uri);
    if (res.statusCode != 200) {
      throw Exception('목록 조회 실패: ${res.statusCode} ${res.body}');
    }

    final map = json.decode(res.body) as Map<String, dynamic>;
    final list = ((map['data'] as List?) ?? [])
        .map((e) => FundListItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return ApiResponse<List<FundListItem>>(
      success: map['success'] == true,
      message: map['message']?.toString(),
      data: list,
      pagination: map['pagination'] == null
          ? null
          : PaginationInfo.fromJson(map['pagination'] as Map<String, dynamic>),
    );
  }

  // 상세
  Future<ApiResponse<FundDetailNet>> getFundDetail(String fundId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/funds/$fundId');

    final res = await _get(uri);
    if (res.statusCode != 200) {
      throw Exception('상세 조회 실패: ${res.statusCode} ${res.body}');
    }

    final map = json.decode(res.body) as Map<String, dynamic>;
    final data = (map['data'] ?? {}) as Map<String, dynamic>;

    return ApiResponse<FundDetailNet>(
      success: map['success'] == true,
      message: map['message']?.toString(),
      data: FundDetailNet.fromJson(data),
    );
  }

  // 관리자 조회수 로그 저장 (서버가 토큰으로 사용자 식별/쿨다운 처리)
  Future<bool> logFundClick({required String fundId}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/fund-click-log');
    final body = jsonEncode({'fund_id': int.tryParse(fundId) ?? fundId});

    try {
      final res = await _post(uri, body: body, json: true);
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // ====================================

  /// 사용자 가입 펀드 목록 조회
  Future<List<Fund>> getMyFunds(String userId) async {
    final uri = Uri.parse('${ApiConfig.myFunds}/$userId');  // URL에 userId 포함
    debugPrint('[GET] $uri');

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('↳ status: ${response.statusCode}');
      debugPrint('↳ body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to load my funds: ${response.statusCode}');
      }

      final apiResponse = ApiResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
            (data) => (data as List<dynamic>)
            .map((item) => Fund.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? 'Failed to load funds');
      }

      return apiResponse.data ?? [];
    } catch (e) {
      debugPrint('getMyFunds error: $e');
      rethrow;
    }
  }
}
