import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_front/core/constants/api.dart';

/// /api/risk-test/result/latest 의 응답 모델
class InvestResultModel {
  final int resultId;
  final int totalScore;
  final String typeName;       // 서버의 grade를 매핑
  final String description;    // description 그대로 사용
  final DateTime analysisDate; // 서버의 createdAt/analysisDate를 매핑

  const InvestResultModel({
    required this.resultId,
    required this.totalScore,
    required this.typeName,
    required this.description,
    required this.analysisDate,
  });

  /// 유연 파싱: 평면/중첩/대체 키 모두 지원
  factory InvestResultModel.fromJson(Map<String, dynamic> j) {
    final resultId = _readInt(j, ['resultId', 'id']) ?? 0;
    final totalScore = _readInt(j, ['totalScore', 'score']) ?? 0;

    // ✅ typeName 후보: typeName, type.name, type.typeName, grade
    final typeName =
        _readString(j, ['typeName']) ??
            _readStringIn(j, ['type', 'name']) ??
            _readStringIn(j, ['type', 'typeName']) ??
            _readString(j, ['grade']) ??                           // ← 여기 추가
            '알 수 없음';

    // 설명: description 또는 type.description
    final description =
        _readString(j, ['description']) ??
            _readStringIn(j, ['type', 'description']) ??
            '';

    // ✅ 날짜 후보: analysisDate, createdAt
    final analysisAtStr =
        _readString(j, ['analysisDate']) ??
            _readString(j, ['createdAt']);                         // ← 여기 추가
    final analysisAt = analysisAtStr != null
        ? DateTime.tryParse(analysisAtStr)
        : null;

    return InvestResultModel(
      resultId: resultId,
      totalScore: totalScore,
      typeName: typeName,
      description: description,
      analysisDate: analysisAt ?? DateTime.now(),
    );
  }

  // -------- helpers --------
  static int? _readInt(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static String? _readString(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  static String? _readStringIn(Map<String, dynamic> j, List<String> path) {
    dynamic cur = j;
    for (final seg in path) {
      if (cur is Map<String, dynamic> && cur.containsKey(seg)) {
        cur = cur[seg];
      } else {
        return null;
      }
    }
    return cur is String && cur.isNotEmpty ? cur : null;
  }
}

/// /api/risk-test/eligibility 의 응답 모델
class InvestEligibilityResponse {
  final bool canReanalyze;
  final String? message;

  const InvestEligibilityResponse({
    required this.canReanalyze,
    required this.message,
  });

  factory InvestEligibilityResponse.fromJson(Map<String, dynamic> j) {
    return InvestEligibilityResponse(
      canReanalyze: j['canReanalyze'] as bool? ?? false,
      message: j['message'] as String?,
    );
  }
}

/// SecureStorage 액세스 토큰 조회
class TokenStore {
  static const _key = 'accessToken';
  static const _storage = FlutterSecureStorage();

  static Future<String?> readAccessToken() => _storage.read(key: _key);
}

/// 서버 통신 서비스
class InvestResultService {
  final String baseUrl;
  InvestResultService({String? baseUrl})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  static const String _latestPath = '/api/risk-test/result/latest';
  static const String _eligibilityPath = '/api/risk-test/eligibility';

  Future<Map<String, String>> _headers() async {
    final token = await TokenStore.readAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('액세스 토큰이 없습니다. 로그인 후 다시 시도해주세요.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // @CurrentUid 주입용
    };
  }

  /// 최근 결과 조회: 200 → 모델, 204/404 → null
  Future<InvestResultModel?> fetchLatest() async {
    final uri = Uri.parse('$baseUrl$_latestPath');
    final res = await http.get(uri, headers: await _headers());

    if (res.statusCode == 200) {
      final map = json.decode(res.body) as Map<String, dynamic>;
      return InvestResultModel.fromJson(map);
    }
    if (res.statusCode == 204 || res.statusCode == 404) {
      return null; // 최근 결과 없음(또는 유효기간 만료)
    }
    throw Exception('GET $uri -> ${res.statusCode} ${res.body}');
  }

  /// 재분석 가능 여부
  Future<InvestEligibilityResponse> fetchEligibility() async {
    final uri = Uri.parse('$baseUrl$_eligibilityPath');
    final res = await http.get(uri, headers: await _headers());

    if (res.statusCode == 200) {
      final map = json.decode(res.body) as Map<String, dynamic>;
      return InvestEligibilityResponse.fromJson(map);
    }
    throw Exception('GET $uri -> ${res.statusCode} ${res.body}');
  }
}
