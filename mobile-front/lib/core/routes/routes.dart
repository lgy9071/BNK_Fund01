import 'package:flutter/material.dart';
import 'package:mobile_front/screens/login_screen.dart';
import 'package:mobile_front/screens/splash_screen.dart';
import 'package:mobile_front/screens/main_scaffold.dart';
import 'package:mobile_front/screens/qna_compose_screen.dart';
import 'package:mobile_front/screens/qna_list_screen.dart';
import 'package:mobile_front/screens/faq_screen.dart';
import 'package:mobile_front/screens/fund_guide_screen.dart';
import 'package:mobile_front/screens/invest_type_result_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String splash = '/splash';
  static const String qnaCompose = '/qna/compose';
  static const String qnaList = '/qna/list';
  static const String faq = '/faq';
  static const String guide = '/guide';
  static const String investType = '/invest-type';
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

      case AppRoutes.qnaCompose:
        return _page(const QnaComposeScreen());

      case AppRoutes.qnaList:
        return _page(const QnaListScreen());

      case AppRoutes.faq:
        return _page(const FaqScreen());

      case AppRoutes.guide:
        return _page(const FundGuideScreen());

      case AppRoutes.investType:
        return _page(const InvestTypeResultScreen());

      default:
        return _page(const Scaffold(
          body: Center(child: Text('404 Not Found')),
        ));
    }
  }

  static MaterialPageRoute _page(Widget w) =>
      MaterialPageRoute(builder: (_) => w);
}