import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:mobile_front/core/constants/api.dart';
import 'package:mobile_front/models/user_profile.dart';
import 'package:flutter/foundation.dart';

// class UserService {
//   final http.Client _client;
//   UserService({http.Client? client}) : _client = client ?? http.Client();
//
//   Future<UserProfile> getMe(String accessToken) async {
//     final res = await _client.get(
//       Uri.parse(ApiConfig.userMe),
//       headers: {'Authorization': 'Bearer $accessToken'},
//     );
//     if (res.statusCode != 200) {
//       throw Exception('Failed to load profile: ${res.statusCode}');
//     }
//     return UserProfile.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
//   }
// }

class UserService {
  final http.Client _client;
  UserService({http.Client? client}) : _client = client ?? http.Client();

  Future<UserProfile> getMe(String accessToken) async {
    final uri = Uri.parse(ApiConfig.userMe);
    debugPrint('[GET] $uri');                        // 요청 로그
    debugPrint('Authorization: Bearer ${accessToken.substring(0, math.min(12, accessToken.length))}...');

    final res = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    debugPrint('↳ status: ${res.statusCode}');       // 응답 로그
    debugPrint('↳ body: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('Failed to load profile: ${res.statusCode}');
    }
    return UserProfile.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}