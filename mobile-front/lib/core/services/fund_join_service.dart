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
  FundJoinService(this._client);

  /// 1) 가입 조건 확인
  Future<JoinNextAction> checkJoin() async {
    try {
      final resp = await _client.dio.post(
        ApiConfig.checkJoin,
        options: Options(responseType: ResponseType.json),
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
      // 서버가 { nextAction: "OPEN_DEPOSIT" | "DO_PROFILE" | "OK" } 형태라고 가정
      final nextAction = _parseNextAction((data as Map<String, dynamic>)['nextAction']);
      return nextAction;
    } on DioException {
      rethrow; // 상위(UI)에서 에러 스낵바/다이얼로그 처리
    } catch (e, st) {
      // 예상 밖의 형태 방어
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
      final resp = await _client.dio.post(
        '${ApiConfig.funds}/$fundId/join', // ✅ 상수 조합
        data: <String, dynamic>{
          'orderAmount': orderAmount,
          'pin': pin,
        },
        options: Options(responseType: ResponseType.json),
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

  /// 3) 내 펀드 계좌/가입 내역 조회 (옵션)
  Future<List<dynamic>> getMyFundAccounts() async {
    try {
      final resp = await _client.dio.get(
        '${ApiConfig.funds}/accounts', // ✅ 상수 조합
        options: Options(responseType: ResponseType.json),
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
      // 예상 외 구조 방어
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
