import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_front/models/fund.dart';

class FundService {
  static const _baseUrl = 'http://10.0.2.2:8090/api';  // 서버 호스트

  Future<List<Fund>> fetchFunds() async {
    final resp = await http.get(Uri.parse('$_baseUrl/funds'));
    if (resp.statusCode != 200) {
      throw Exception('펀드 목록 조회 실패: ${resp.statusCode}');
    }
    final List data = json.decode(resp.body);
    return data.map((e) => Fund.fromJson(e)).toList();
  }
}