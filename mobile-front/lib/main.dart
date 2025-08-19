import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/core/routes/routes.dart';
import 'package:mobile_front/core/constants/api.dart';

// 추가: 전역 세션 매니저/키 & API 경로
import 'package:mobile_front/utils/session_manager.dart';

// 전역 내비게이터 키 (다이얼로그/스낵바, 라우팅에 사용)
final navigatorKey = GlobalKey<NavigatorState>();

// 전역 세션 매니저 (10분 무동작 타이머 + 30초 경고/연장 + 자동복구)
final sessionManager = SessionManager(
  extendUrl: ApiConfig.extend,
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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),

        scaffoldBackgroundColor: AppColors.bg,           // 전체 배경
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          foregroundColor: AppColors.fontColor,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: AppColors.bg,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),

        // 기본 텍스트 색을 0xFF383E56로 통일
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: AppColors.fontColor,
          displayColor: AppColors.fontColor,
        ),

        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.primaryBlue,
          selectionHandleColor: Color(0xFF00067D),
        ),
      ),

      navigatorKey: navigatorKey,

      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRoutes.splash,
    );
  }
}
