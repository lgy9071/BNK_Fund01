import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: CircleNavBar(
        currentIndex: _index,
        onTap: (i) {
          if (i == 3) {
            _openFullMenu();
            return;
          }
          setState(() => _index = i);
        },
      ),
    );
  }
}
