import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/screens/login_screen.dart';
import 'package:mobile_front/screens/splash_screen.dart';
import 'package:mobile_front/core/routes/routes.dart';

// ✅ 추가: 전역 세션 매니저/키 & API 경로
import 'package:mobile_front/core/constants/api.dart';
import 'package:mobile_front/utils/session_manager.dart';

// 전역 내비게이터 키 (다이얼로그/스낵바, 라우팅에 사용)
final navigatorKey = GlobalKey<NavigatorState>();

// 전역 세션 매니저 (10분 무동작 타이머 + 30초 경고/연장 + 자동복구)
final sessionManager = SessionManager(
  extendUrl: ApiConfig.extend,
  refreshUrl: ApiConfig.refresh,
  navigatorKey: navigatorKey,
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splash Demo',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.primaryBlue,
          selectionHandleColor: Color(0xFF00067D),
        ),
      ),
      // ✅ 전역 navigatorKey 연결 (SessionManager가 다이얼로그/네비게이션에 사용)
      navigatorKey: navigatorKey,

      // ✅ 모든 화면 위에 전역 터치 리스너를 깔아 "무동작 타이머" 리셋
      builder: (context, child) {
        return Listener(
          onPointerDown: (_) => sessionManager.resetOnUserInteraction(),
          onPointerMove: (_) => sessionManager.resetOnUserInteraction(),
          onPointerSignal: (_) => sessionManager.resetOnUserInteraction(),
          child: child!,
        );
      },

      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.splash: (_) => const SplashScreen(),
      },
      initialRoute: AppRoutes.splash,
    );
  }
}
