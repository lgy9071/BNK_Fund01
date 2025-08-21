// core/services/fund_status_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_front/core/constants/api.dart';
import 'package:mobile_front/screens/fund_status/fund_status.dart';

class FundStatusApi {
  final http.Client _client;
  FundStatusApi({http.Client? client}) : _client = client ?? http.Client();

  Future<PageResponse<FundStatusListItem>> list({
    String? q,
    String? category,
    int page = 0,
    int size = 10,
    String? bearerToken, // 필요시 JWT
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/fund-status').replace(queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (category != null && category.isNotEmpty) 'category': category,
      'page': '$page',
      'size': '$size',
    });
    final res = await _client.get(uri, headers: {
      'Content-Type': 'application/json',
      if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
    });
    if (res.statusCode != 200) {
      throw Exception('Failed to load list: ${res.statusCode}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (map['content'] as List).map((e) => FundStatusListItem.fromJson(e)).toList();
    return PageResponse(
      content: items,
      page: map['page'] ?? 0,
      size: map['size'] ?? items.length,
      totalElements: (map['totalElements'] as num).toInt(),
      last: map['last'] ?? true,
    );
  }

  Future<FundStatusDetail> detail(int id, {String? bearerToken}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/fund-status/$id');
    final res = await _client.get(uri, headers: {
      'Content-Type': 'application/json',
      if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
    });
    if (res.statusCode != 200) {
      throw Exception('Failed to load detail: ${res.statusCode}');
    }
    return FundStatusDetail.fromJson(jsonDecode(res.body));
  }
}
