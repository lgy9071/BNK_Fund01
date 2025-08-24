import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.storage,
    required this.extendPath,                 // 예: '/api/auth/extend'
    this.expBuffer = const Duration(seconds: 60),
    this.clockSkew = const Duration(seconds: 30),
  }) : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequestAttachAndMaybeExtend,
      onError: _onErrorMaybeExtendAndRetry,
    ));
  }

  final String baseUrl;
  final Dio dio;
  final FlutterSecureStorage storage;
  final String extendPath;
  final Duration expBuffer; // 만료 60초 전 선제 연장
  final Duration clockSkew; // 서버-클라 시계 오차 여유

  // 동시에 여러 요청이 들어올 때 extend를 한 번만 수행
  Future<void>? _extendInFlight;

  // ───────────────────────────────────────────────────────────────
  // 요청 전: 액세스 토큰 부착 + 만료 임박이면 선제 연장
  Future<void> _onRequestAttachAndMaybeExtend(
      RequestOptions options, RequestInterceptorHandler handler) async {
    var access = _clean(await storage.read(key: 'accessToken'));
    if (access.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $access';
    }

    final exp = _jwtExp(access);
    if (exp != null) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final remain = Duration(seconds: exp - now) - clockSkew;
      if (remain <= expBuffer) {
        final ok = await _extendOnce();
        if (ok) {
          access = _clean(await storage.read(key: 'accessToken'));
          if (access.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $access';
          }
        }
      }
    }

    handler.next(options);
  }

  // 401이면 1회 extend 후 원요청 재시도
  Future<void> _onErrorMaybeExtendAndRetry(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    try {
      final ok = await _extendOnce();
      if (!ok) return handler.next(err);

      final req = err.requestOptions;
      final newAccess = _clean(await storage.read(key: 'accessToken'));
      if (newAccess.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer $newAccess';
      }
      final cloned = await dio.fetch(req);
      return handler.resolve(cloned);
    } catch (_) {
      return handler.next(err);
    }
  }

  // ───────────────────────────────────────────────────────────────
  // extend 동시성 제어: 한 번만 수행
  Future<bool> _extendOnce() async {
    if (_extendInFlight != null) {
      try {
        await _extendInFlight; return true;
      } catch (_) {
        return false;
      }
    }

    final c = Completer<void>();
    _extendInFlight = c.future;

    try {
      final ok = await _callExtendWithAccess();
      if (!ok) throw Exception('extend failed');
      c.complete();
      return true;
    } catch (e) {
      c.completeError(e);
      return false;
    } finally {
      _extendInFlight = null;
    }
  }

  /// /api/auth/extend : Authorization: Bearer <access>
  /// 응답: { "accessToken": "..." }
  Future<bool> _callExtendWithAccess() async {
    final access = _clean(await storage.read(key: 'accessToken'));
    if (access.isEmpty) return false;

    try {
      final resp = await dio.post(
        extendPath,
        options: Options(headers: {'Authorization': 'Bearer $access'}),
      );
      if (resp.statusCode == 200) {
        final at = _clean(resp.data['accessToken'] as String?);
        if (at.isNotEmpty) {
          await storage.write(key: 'accessToken', value: at);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  // ───────────────────────────────────────────────────────────────
  // 유틸

  String _clean(String? s) {
    if (s == null) return '';
    return s
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF\u00A0]'), '')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
  }

  int? _jwtExp(String token) {
    try {
      final p = token.split('.');
      if (p.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(p[1])));
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is int) return exp;
      if (exp is num) return exp.toInt();
      return null;
    } catch (_) {
      return null;
    }
  }


  /// 보안 저장소에서 현재 액세스 토큰만 꺼냄 (없으면 null)
  Future<String?> get currentToken async {
    final raw = await storage.read(key: 'accessToken');
    final cleaned = _clean(raw);
    return cleaned.isEmpty ? null : cleaned;
  }

  /// 만료 임박하면 extend까지 해준 뒤 최신 토큰 반환 (없으면 null)
  Future<String?> ensureFreshAccessToken() async {
    var access = _clean(await storage.read(key: 'accessToken'));
    if (access.isEmpty) return null;

    final exp = _jwtExp(access);
    if (exp != null) {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final remain = Duration(seconds: exp - nowSec) - clockSkew;
      if (remain <= expBuffer) {
        final ok = await _extendOnce();
        if (ok) {
          access = _clean(await storage.read(key: 'accessToken'));
        }
      }
    }
    return access.isEmpty ? null : access;
  }
}