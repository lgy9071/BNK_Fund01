import 'dart:convert';
import 'package:http/http.dart' as http;

class ReviewItemDto {
  final int reviewId;
  final int userId;
  final String fundId;
  final String text;
  final DateTime createdAt;
  final int editCount;

  ReviewItemDto({
    required this.reviewId,
    required this.userId,
    required this.fundId,
    required this.text,
    required this.createdAt,
    required this.editCount,
  });

  factory ReviewItemDto.fromJson(Map<String, dynamic> j) => ReviewItemDto(
    reviewId: j['reviewId'],
    userId: j['userId'],
    fundId: j['fundId'],
    text: j['text'],
    createdAt: DateTime.parse(j['createdAt']),
    editCount: j['editCount'],
  );
}

class ReviewListResponseDto {
  final String fundId;
  final int page;
  final int size;
  final int total;
  final List<ReviewItemDto> items;

  ReviewListResponseDto({
    required this.fundId,
    required this.page,
    required this.size,
    required this.total,
    required this.items,
  });

  factory ReviewListResponseDto.fromJson(Map<String, dynamic> j) =>
      ReviewListResponseDto(
        fundId: j['fundId'],
        page: j['page'],
        size: j['size'],
        total: j['total'],
        items: (j['items'] as List).map((e) => ReviewItemDto.fromJson(e)).toList(),
      );
}

enum SummaryStatus { ok, insufficient }
SummaryStatus _statusOf(String s) =>
    s.toUpperCase() == 'OK' ? SummaryStatus.ok : SummaryStatus.insufficient;

class SummaryResponseDto {
  final SummaryStatus status;
  final String fundId;
  final String? summaryText;
  final DateTime? lastGeneratedAt;
  final int? reviewCountAtGen;
  final int activeReviewCount;

  SummaryResponseDto({
    required this.status,
    required this.fundId,
    required this.summaryText,
    required this.lastGeneratedAt,
    required this.reviewCountAtGen,
    required this.activeReviewCount,
  });

  factory SummaryResponseDto.fromJson(Map<String, dynamic> j) => SummaryResponseDto(
    status: _statusOf(j['status']),
    fundId: j['fundId'],
    summaryText: j['summaryText'],
    lastGeneratedAt: j['lastGeneratedAt'] == null ? null : DateTime.parse(j['lastGeneratedAt']),
    reviewCountAtGen: j['reviewCountAtGen'],
    activeReviewCount: j['activeReviewCount'] ?? 0,
  );
}

class EligibilityResponseDto {
  final bool canWrite;
  EligibilityResponseDto({required this.canWrite});
  factory EligibilityResponseDto.fromJson(Map<String, dynamic> j) =>
      EligibilityResponseDto(canWrite: j['canWrite'] == true);
}

/// 보유 펀드 간단 DTO (보유 API 응답 스키마에 맞춰 조정)
class HoldingFundDto {
  final String fundId;
  final String fundName;
  bool alreadyWritten; // UI 표시용
  int? editCount;      // 본인 리뷰의 editCount (수정버튼 제어)
  HoldingFundDto({
    required this.fundId,
    required this.fundName,
    this.alreadyWritten = false,
    this.editCount,
  });
}

class ReviewApi {
  final String baseUrl;
  final String accessToken;
  ReviewApi({required this.baseUrl, required this.accessToken});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };

  // (예시) 보유 펀드 목록 — 실제 엔드포인트에 맞춰 변경
  Future<List<HoldingFundDto>> getMyHoldingFunds() async {
    final url = Uri.parse('$baseUrl/api/funds/holdings');
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) throw Exception('보유펀드 조회 실패');
    final List list = jsonDecode(res.body);
    return list.map((e) => HoldingFundDto(
      fundId: e['fundId'],
      fundName: (e['fundName'] ?? e['fundId']).toString(),
    )).cast<HoldingFundDto>().toList();
  }

  Future<ReviewListResponseDto> getReviews(String fundId, {int page = 0, int size = 100}) async {
    final url = Uri.parse('$baseUrl/api/funds/$fundId/reviews?page=$page&size=$size');
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) throw Exception('리뷰 목록 실패');
    return ReviewListResponseDto.fromJson(jsonDecode(res.body));
  }

  Future<bool> canWrite(String fundId) async {
    final url = Uri.parse('$baseUrl/api/funds/$fundId/reviews/eligibility');
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) throw Exception('eligibility 실패');
    return EligibilityResponseDto.fromJson(jsonDecode(res.body)).canWrite;
  }

  Future<int> create(String fundId, String text) async {
    final url = Uri.parse('$baseUrl/api/funds/$fundId/reviews');
    final res = await http.post(url, headers: _headers, body: jsonEncode({'text': text}));
    if (res.statusCode != 200) throw Exception(utf8.decode(res.bodyBytes));
    return jsonDecode(res.body) as int;
  }

  Future<void> update(String fundId, int reviewId, String text) async {
    final url = Uri.parse('$baseUrl/api/funds/$fundId/reviews/$reviewId');
    final res = await http.put(url, headers: _headers, body: jsonEncode({'text': text}));
    if (res.statusCode != 204) throw Exception(utf8.decode(res.bodyBytes));
  }

  Future<void> delete(String fundId, int reviewId) async {
    final url = Uri.parse('$baseUrl/api/funds/$fundId/reviews/$reviewId');
    final res = await http.delete(url, headers: _headers);
    if (res.statusCode != 204) throw Exception(utf8.decode(res.bodyBytes));
  }

  Future<SummaryResponseDto> getSummary(String fundId) async {
    final url = Uri.parse('$baseUrl/api/funds/$fundId/review-summary');
    final res = await http.get(url, headers: _headers);
    if (res.statusCode != 200) throw Exception('요약 조회 실패');
    return SummaryResponseDto.fromJson(jsonDecode(res.body));
  }
}
