import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_front/core/routes/routes.dart';
import 'package:mobile_front/utils/exit_guard.dart';
import 'package:mobile_front/widgets/show_custom_confirm_dialog.dart';

import '../core/constants/colors.dart';
import '../models/fund.dart';
import '../screens/home_screen.dart';
import '../screens/my_finance_screen.dart';
import '../screens/fund_list_screen.dart';
import '../widgets/full_menu_overlay.dart';
import '../widgets/circle_nav_bar.dart';
import '../main.dart' show navigatorKey;
import 'package:mobile_front/core/services/user_service.dart';

class MainScaffold extends StatefulWidget {
  final String? initialAccessToken;

  const MainScaffold({super.key, this.initialAccessToken});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;
  String? _initialAccessToken; // 라우트로 받은 토큰 저장
  late List<Widget> _pages;
  String? _investTypeName; // 투자성향 이름 저장

  final _myFunds = <Fund>[
    Fund(id: 1, name: '한국성장주식 A', rate: 3.2, balance: 5_500_000),
    Fund(id: 2, name: '글로벌채권 인덱스', rate: -1.1, balance: 4_000_000),
    Fund(id: 3, name: '미국기술주 펀드', rate: 6.5, balance: 6_200_000),
    Fund(id: 4, name: '친환경 인프라 펀드', rate: 1.7, balance: 2_800_000),
  ];

  void _buildPages() {
    _pages = [
      HomeScreen(
        myFunds: _myFunds,
        investType: '공격 투자형',
        userName: '뚜리',
        accessToken: _initialAccessToken, // 중요: 여기로 전달
        userService: UserService(),
      ),
      const MyFinanceScreen(),
      const FundListScreen(),
      const SizedBox.shrink(), // 전체 메뉴 자리
    ];
  }

  @override
  void initState() {
    super.initState();
    _initialAccessToken = widget.initialAccessToken; // ⬅ 생성자 값으로 세팅
    _buildPages(); // 초기(토큰 null일 수 있음) 1회 구성  > 바로 페이지 구성
    _loadUserInfo(); // ✅ 유저 정보 불러오기
  }

  Future<void> _loadUserInfo() async {
    String? token = _initialAccessToken;

    if (token == null || token.isEmpty) {
      const storage = FlutterSecureStorage();
      token = await storage.read(key: 'accessToken');
    }

    if (token == null || token.isEmpty) return;

    try {
      final svc = UserService();
      final me = await svc.getMe(token);
      setState(() {
        _investTypeName = me.typename.isNotEmpty ? me.typename : null;
        _initialAccessToken = token;
        _buildPages(); // 🔥 HomeScreen을 새로운 데이터로 다시 구성
      });
    } catch (e) {
      debugPrint("MainScaffold.getMe failed: $e");
    }
  }



  Future<void> _openFullMenu() async {
    // 1) 라우트 인자로 받은 토큰 우선 사용
    String? accessToken = _initialAccessToken;

    // 2) 없으면(앱 재시작 등) 스토리지에서 보조로 읽기
    if (accessToken == null || accessToken.isEmpty) {
      const storage = FlutterSecureStorage();
      accessToken = await storage.read(key: 'accessToken');
    }

    // 디버그
    final pre = (accessToken == null || accessToken.isEmpty)
        ? 'null'
        : accessToken.substring(0, math.min(12, accessToken.length));
    debugPrint('MainScaffold.accessToken? $pre...');

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: AppColors.bg,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
            child: Material(
              color: AppColors.bg,
              child: SafeArea(
                child: FullMenuOverlay(
                  userName: '이유저',
                  userId: '@user01',
                  accessToken: accessToken,      // ⬅ 여기로도 전달
                  userService: UserService(),    // (선택) 주입

                  onGoFundMain: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    setState(() => _index = 0);
                  },
                  onGoFundJoin: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    setState(() => _index = 2);
                  },
                  onGoInvestAnalysis: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    navigatorKey.currentState?.pushNamed('/invest-type');
                  },
                  onGoFAQ: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    navigatorKey.currentState?.pushNamed('/faq');
                  },
                  onGoGuide: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    navigatorKey.currentState?.pushNamed('/guide');
                  },
                  onGoMbti: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    navigatorKey.currentState?.pushNamed('/fund-mbti');
                  },
                  onGoForum: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  onLogout: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  onAsk: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.of(context).pushNamed('/qna/compose');
                  },
                  onMyQna: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.of(context).pushNamed('/qna/list');
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return ExitGuard(
  //     child: Scaffold(
  //       body: IndexedStack(index: _index, children: _pages),
  //       backgroundColor: Colors.white,
  //       bottomNavigationBar: CustomNavBar(
  //         currentIndex: _index,
  //         onTap: (i) {
  //           if (i == 3) {
  //             _openFullMenu();
  //             return;
  //           }
  //           setState(() => _index = i);
  //         },
  //       ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return ExitGuard(
      child: Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        backgroundColor: Colors.white,
        bottomNavigationBar: CustomNavBar(
          currentIndex: _index,
          onTap: (i) async {
            if (i == 3) {
              _openFullMenu();
              return;
            }

            if (i == 2) { // 👉 펀드 가입 탭
              if (_investTypeName == null || _investTypeName!.isEmpty) {
                final result = await showAppConfirmDialog(
                  context: context,
                  title: "안내",
                  message: "펀드 가입을 위해서는 투자성향 \n분석이 필요합니다 진행하시겠습니까?",
                  confirmText: "분석진행",
                  cancelText: "취소",
                  confirmColor: AppColors.primaryBlue,
                  onConfirm: () {
                    Navigator.pushNamed(context, AppRoutes.investType);
                  },
                );
                return; // 🚫 펀드 가입 탭 화면 이동 막음
              }
            }

            setState(() => _index = i); // 정상 이동
          },
        ),
      ),
    );
  }

}
