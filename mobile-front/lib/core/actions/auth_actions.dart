import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:mobile_front/core/constants/api.dart';     // ApiConfig.logout 사용
import 'package:mobile_front/core/routes/routes.dart';  // AppRoutes.login 사용
import 'package:mobile_front/main.dart';                  // sessionManager 사용(전역)

class AuthActions {
  static final _secure = const FlutterSecureStorage();

  /// 서버에 로그아웃 알리고(옵션), 로컬 토큰 삭제, 세션정지, 로그인으로 이동
  static Future<void> logout(BuildContext context, {bool callServer = true}) async {
    // 1) 서버에 refresh 로그아웃 알리기 (선택)
    if (callServer) {
      final rt = await _secure.read(key: 'refreshToken');
      if (rt != null) {
        try {
          await http.post(
            Uri.parse(ApiConfig.logout),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': rt}),
          );
        } catch (_) {
          // 네트워크 실패해도 로컬 정리는 계속 진행
        }
      }
    }

    // 2) 로컬 토큰 삭제
    await _secure.delete(key: 'accessToken');
    await _secure.delete(key: 'refreshToken');

    // 3) 전역 세션 타이머 정지
    sessionManager.stop();

    // 4) 로그인 화면으로 이동 (스택 전체 초기화)
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    }
  }
}
