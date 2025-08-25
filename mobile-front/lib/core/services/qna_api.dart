// lib/core/services/qna_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_front/models/qna_item.dart';

// Dart 3 레코드 타입 (목록 응답)
typedef QnaListRec = ({
List<QnaItem> items,
int totalPages,
int totalElements,
});

class QnaApi {
  final String baseUrl;
  final String accessToken;

  QnaApi({required this.baseUrl, required this.accessToken});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };

  /// 내 문의 목록 (페이징)
  Future<QnaListRec> myQnas({int page = 0, int size = 15}) async {
    final uri = Uri.parse('$baseUrl/api/qna?page=$page&size=$size');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('문의 목록 조회 실패: ${res.statusCode}');
    }

    final j = json.decode(res.body) as Map<String, dynamic>;
    final items =
    (j['content'] as List).map((e) => QnaItem.fromJson(e)).toList();

    final totalPages = (j['totalPages'] as num).toInt();
    final totalElements = (j['totalElements'] as num).toInt();

    return (items: items, totalPages: totalPages, totalElements: totalElements);
  }

  /// 문의 등록 (composeScreen에서 사용)
  Future<QnaItem> create({required String title, required String content}) async {
    final uri = Uri.parse('$baseUrl/api/qna');
    final body = json.encode({'title': title, 'content': content});

    final res = await http.post(uri, headers: _headers, body: body);
    if (res.statusCode != 200) {
      throw Exception('문의 등록 실패: ${res.statusCode}');
    }
    final j = json.decode(res.body) as Map<String, dynamic>;
    return QnaItem.fromJson(j);
  }

  /// 문의 상세 (qna_list_screen의 _openDetail에서 사용)
  Future<QnaItem> detail(int qnaId) async {
    final uri = Uri.parse('$baseUrl/api/qna/$qnaId');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('문의 상세 조회 실패: ${res.statusCode}');
    }
    final j = json.decode(res.body) as Map<String, dynamic>;
    return QnaItem.fromJson(j);
  }

  /// (옵션) 대기 상태일 때만 수정 – 필요 시 사용
  Future<QnaItem> update(int qnaId, {required String title, required String content}) async {
    final uri = Uri.parse('$baseUrl/api/qna/$qnaId');
    final body = json.encode({'title': title, 'content': content});
    final res = await http.put(uri, headers: _headers, body: body);
    if (res.statusCode != 200) {
      throw Exception('문의 수정 실패(대기 상태만): ${res.statusCode}');
    }
    final j = json.decode(res.body) as Map<String, dynamic>;
    return QnaItem.fromJson(j);
  }
}
