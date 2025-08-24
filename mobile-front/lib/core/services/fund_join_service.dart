import 'package:dio/dio.dart';
import 'package:mobile_front/utils/api_client.dart';
import 'package:mobile_front/core/constants/api.dart';

enum JoinNextAction { ok, openDeposit, doProfile }

JoinNextAction _parseNextAction(dynamic v) {
  final s = (v ?? '').toString().toUpperCase();
  if (s == 'OPEN_DEPOSIT') return JoinNextAction.openDeposit;
  if (s == 'DO_PROFILE') return JoinNextAction.doProfile;
  return JoinNextAction.ok;
}

class FundJoinService {
  final ApiClient _client;

  /// ─────────────────────────────────────────────────────────────
  /// 토큰 주입 방식 2가지 중 하나 사용:
  /// 1) staticToken: 화면에서 받은 accessToken을 바로 넣기
  /// 2) tokenProvider: 필요 시 비동기로 읽어오는 콜백(예: SecureStorage)
  /// ─────────────────────────────────────────────────────────────
  String? _staticToken;
  final Future<String?> Function()? _tokenProvider;

  FundJoinService(
      this._client, {
        String? staticToken,
        Future<String?> Function()? tokenProvider,
      })  : _staticToken = staticToken,
        _tokenProvider = tokenProvider;

  /// 외부에서 토큰 갱신이 필요할 때 호출
  void setStaticToken(String? token) {
    _staticToken = token;
  }

  Future<Options> _authOptions({Options? base, ResponseType rt = ResponseType.json}) async {
    // 1) 우선순위: staticToken → tokenProvider()
    String? token = _staticToken;
    token ??= await _tokenProvider?.call();

    final headers = <String, dynamic>{};
    if (base?.headers != null) headers.addAll(base!.headers!);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return (base ?? Options()).copyWith(
      responseType: rt,
      headers: headers,
    );
  }

  /// 1) 가입 조건 확인
  Future<JoinNextAction> checkJoin() async {
    try {
      final opts = await _authOptions(rt: ResponseType.json);
      final resp = await _client.dio.post(
        ApiConfig.checkJoin,
        options: opts,
      );

      if (resp.statusCode != 200 || resp.data == null) {
        throw DioException(
          requestOptions: resp.requestOptions,
          response: resp,
          error: '가입 조건 응답이 올바르지 않습니다.',
          type: DioExceptionType.badResponse,
        );
      }

      final data = resp.data;
      final nextAction = _parseNextAction((data as Map<String, dynamic>)['nextAction']);
      return nextAction;
    } on DioException {
      rethrow; // UI단에서 처리
    } catch (e, st) {
      throw DioException(
        requestOptions: RequestOptions(path: ApiConfig.checkJoin),
        error: e,
        stackTrace: st,
        type: DioExceptionType.unknown,
      );
    }
  }

  /// 2) 실제 펀드 가입 요청
  Future<void> joinFund(
      String fundId, {
        required int orderAmount,
        required String pin,
      }) async {
    try {
      final opts = await _authOptions(rt: ResponseType.json);
      final resp = await _client.dio.post(
        '${ApiConfig.funds}/$fundId/join',
        data: <String, dynamic>{
          'orderAmount': orderAmount,
          'pin': pin,
        },
        options: opts,
      );

      if (resp.statusCode != 200 && resp.statusCode != 201) {
        throw DioException(
          requestOptions: resp.requestOptions,
          response: resp,
          error: '가입 요청 실패',
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException {
      rethrow;
    } catch (e, st) {
      throw DioException(
        requestOptions: RequestOptions(path: '${ApiConfig.funds}/$fundId/join'),
        error: e,
        stackTrace: st,
        type: DioExceptionType.unknown,
      );
    }
  }

  /// 3) 내 펀드 계좌/가입 내역 조회
  Future<List<dynamic>> getMyFundAccounts() async {
    try {
      final opts = await _authOptions(rt: ResponseType.json);
      final resp = await _client.dio.get(
        '${ApiConfig.funds}/accounts',
        options: opts,
      );

      if (resp.statusCode != 200 || resp.data == null) {
        throw DioException(
          requestOptions: resp.requestOptions,
          response: resp,
          error: '계좌 목록 조회 실패',
          type: DioExceptionType.badResponse,
        );
      }

      final data = resp.data;
      if (data is List) return data;
      if (data is Map && data['items'] is List) return data['items'] as List;
      return const <dynamic>[];
    } on DioException {
      rethrow;
    } catch (e, st) {
      throw DioException(
        requestOptions: RequestOptions(path: '${ApiConfig.funds}/accounts'),
        error: e,
        stackTrace: st,
        type: DioExceptionType.unknown,
      );
    }
  }
}
