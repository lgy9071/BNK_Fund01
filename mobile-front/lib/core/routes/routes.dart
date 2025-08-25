import 'package:flutter/material.dart';
import 'package:mobile_front/screens/create_account/cdd_screen.dart';
import 'package:mobile_front/screens/create_account/create_deposit_account_screen.dart';
import 'package:mobile_front/screens/create_account/opt_screen.dart';
import 'package:mobile_front/screens/fund_status/fund_status_list_screen.dart';
import 'package:mobile_front/screens/investprofile_test/consent_step_page.dart';
import 'package:mobile_front/screens/investprofile_test/invest_result_screen.dart';
import 'package:mobile_front/screens/investprofile_test/questionnaire_screen.dart';
import 'package:mobile_front/screens/login_screen.dart';
import 'package:mobile_front/screens/splash_screen.dart';
import 'package:mobile_front/screens/main_scaffold.dart';
import 'package:mobile_front/screens/qna_compose_screen.dart';
import 'package:mobile_front/screens/qna_list_screen.dart';
import 'package:mobile_front/screens/faq_screen.dart';
import 'package:mobile_front/screens/fund_guide_screen.dart';
import 'package:mobile_front/screens/invest_type_result_loader.dart';
import 'package:mobile_front/core/services/invest_result_service.dart';
import 'package:mobile_front/core/constants/api.dart';
import 'package:mobile_front/screens/fund_mbti_flow.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String splash = '/splash';
  static const String qnaCompose = '/qna/compose';
  static const String qnaList = '/qna/list';
  static const String faq = '/faq';
  static const String guide = '/guide';
  static const String investType = '/invest-type'; // 도입부(결과/재분석 시작)
  static const String fundMbti = '/fund-mbti';
  static const String questionnaire = '/questionnaire'; // 설문 화면
  static const String investTest = '/invest-test'; // 동의 -> 설문 진입
  static const String investResult = '/invest-result'; // 결과 화면
  static const String otp = '/otp';
  static const String cdd = '/cdd';
  static const String createDepositAccount = '/create-deposit-account' ;
  static const String fundStatus = '/fund-status'; // 펀드 시황
}

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings s) {
    switch (s.name) {
      case AppRoutes.splash:
        return _page(const SplashScreen());

      case AppRoutes.login:
        return _page(const LoginScreen());

      case AppRoutes.home:
        return _page(const MainScaffold());

      case AppRoutes.qnaCompose: {
        final args = s.arguments as Map<String, dynamic>?;
        final baseUrl = (args?['baseUrl'] as String?) ?? ApiConfig.baseUrl;
        final accessToken = (args?['accessToken'] as String?) ?? '';
        // ✅ bool? 반환을 기대하는 Route로 생성
        return _page<bool?>(QnaComposeScreen(baseUrl: baseUrl, accessToken: accessToken));
      }

      case AppRoutes.qnaList: {
        final args = s.arguments as Map<String, dynamic>?;
        final baseUrl = (args?['baseUrl'] as String?) ?? ApiConfig.baseUrl;
        final accessToken = (args?['accessToken'] as String?) ?? '';
        // 반환값 안쓸거면 void나 dynamic로 충분
        return _page<void>(QnaListScreen(baseUrl: baseUrl, accessToken: accessToken));
      }

      case AppRoutes.faq:
        return _page(const FaqScreen());

      case AppRoutes.guide:
        return _page(const FundGuideScreen());

      // ✅ 도입부(최신 결과 로더). 완료 시 pop(true) 전파해야 하므로 bool?로 반환
      case AppRoutes.investType:
        {
          final uid = (s.arguments as int?) ?? 1;
          return _page<bool?>(
            InvestTypeResultLoader(
              userId: uid,
              service: InvestResultService(baseUrl: ApiConfig.baseUrl),
              lastRetestAt: null,
            ),
            settings: s,
          );
        }

      case AppRoutes.fundMbti:
        return _page(const FundMbtiFlowScreen());

      // ✅ 설문 화면도 최종 true 전파 가능해야 하므로 bool?
      case AppRoutes.questionnaire:
        return _page<bool?>(const QuestionnaireScreen(), settings: s);

      // ✅ 동의 -> 설문 진입(동의 화면). onNext가 설문을 await하고 bool? 반환
      case AppRoutes.investTest:
        return MaterialPageRoute<bool?>(
          builder: (ctx) => ConsentStepPage(
            onSubmit: (agreed) async {
              // 서버 전송 필요 시 추가
            },
            onNext: () async {
              final bool? res = await Navigator.pushNamed<bool?>(
                ctx,
                AppRoutes.questionnaire,
              );
              return res; // true면 Consent에서도 pop(true) 전파
            },
          ),
          settings: s,
        );

      // ✅ 결과 화면: 완료 시 pop(true) 전파 → bool?
      case AppRoutes.investResult:
        return _page<bool?>(
          InvestResultScreen(
            result: (s.arguments as Map<String, dynamic>?) ?? const {},
          ),
          settings: s, // arguments 유지
        );

      case AppRoutes.otp:
        final args = s.arguments as Map<String, dynamic>? ?? {};
        return _page(
          OptScreen(
            accessToken: args['accessToken'],
            userService: args['userService'],
          ),
        );

      case AppRoutes.cdd:
        final args = s.arguments as Map<String, dynamic>? ?? {};
        return _page(
          CddScreen(
            accessToken: args['accessToken'],
            userService: args['userService'],
          ),
        );

      case AppRoutes.createDepositAccount:
        final args = s.arguments as Map<String, dynamic>?;
        return _page(
          CreateDepositAccountScreen(
            accessToken: args?['accessToken'],
            userService: args?['userService'],
          ),
        );

      case AppRoutes.fundStatus:
        return _page(const FundStatusListScreen());

      default:
        return _page(
          const Scaffold(body: Center(child: Text('404 Not Found'))),
        );
    }
  }

  // ✅ 제네릭 헬퍼: 필요하면 반환 타입을 지정할 수 있음 (settings도 전달 가능)
  static MaterialPageRoute<T> _page<T>(Widget w, {RouteSettings? settings}) =>
      MaterialPageRoute<T>(builder: (_) => w, settings: settings);
}
