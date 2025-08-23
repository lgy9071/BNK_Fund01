// lib/core/services/compare_ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:mobile_front/models/compare_ai_models.dart';

class CompareAiService {
  final String baseUrl;
  final http.Client _client;
  CompareAiService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  /// fundIds 2개 이상과 accessToken(Authorization)만 필요
  Future<CompareAiResponse> fetchCompare({
    required List<String> fundIds,
    required String accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/api/compare-ai/compare');
    debugPrint('[POST] $uri  funds=${fundIds.join(",")}');

    final res = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'funds': fundIds}),
    );

    debugPrint('↳ status: ${res.statusCode}');
    if (res.statusCode != 200) {
      throw Exception('AI 비교 실패: ${res.statusCode} ${res.body}');
    }
    return CompareAiResponse.parse(res.body);
  }
}
