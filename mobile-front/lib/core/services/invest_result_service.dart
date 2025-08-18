import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_front/core/constants/api.dart';
import 'package:mobile_front/screens/invest_type_result_screen.dart'; // InvestResultModel

class InvestResultService {
  final String baseUrl;
  InvestResultService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  Future<InvestResultModel?> fetchLatest(int userId) async {
    final uri = Uri.parse('$baseUrl/invest-profile/result/latest?userId=$userId');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      final map = json.decode(res.body) as Map<String, dynamic>;
      return InvestResultModel.fromJson(map);
    }
    if (res.statusCode == 204 || res.statusCode == 404) {
      return null; // 결과 없음
    }
    throw Exception('GET $uri -> ${res.statusCode} ${res.body}');
  }
}
