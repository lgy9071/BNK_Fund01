import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/core/routes/routes.dart';
import 'package:mobile_front/core/constants/api.dart';
import 'package:mobile_front/utils/session_manager.dart';

// 전역 키/세션
final navigatorKey = GlobalKey<NavigatorState>();
final sessionManager = SessionManager(
  extendUrl: ApiConfig.extend,
  navigatorKey: navigatorKey,
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp()); // ✅ 여기서는 MyApp만
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
    // ✅ ScreenUtilInit를 MaterialApp "바깥"에 둔다.
    return ScreenUtilInit(
      designSize: const Size(411.4, 891.4), // 너 폰에서 찍힌 dp
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        // 이 시점에서 ScreenUtil 초기화 완료
        return MaterialApp(
          title: 'Splash Demo',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          themeMode: _mode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
            scaffoldBackgroundColor: AppColors.bg,
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
            textTheme: ThemeData.light().textTheme.apply(
              bodyColor: AppColors.fontColor,
              displayColor: AppColors.fontColor,
            ),
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: AppColors.primaryBlue,
              selectionHandleColor: Color(0xFF00067D),
            ),
          ),
          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: AppRoutes.splash,
        );
      },
    );
  }
}
