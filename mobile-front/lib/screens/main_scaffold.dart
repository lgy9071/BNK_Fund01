import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_front/utils/exit_popup.dart';
import '../core/routes/routes.dart';
import '../core/constants/colors.dart';
import '../models/fund.dart';
import '../screens/home_screen.dart';
import '../screens/my_finance_screen.dart';
import '../screens/fund_list_screen.dart';
import '../widgets/full_menu_overlay.dart';
import '../widgets/circle_nav_bar.dart';
import '../main.dart' show navigatorKey;

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

  final _myFunds = <Fund>[
    Fund(id: 1, name: '한국성장주식 A', rate: 3.2, balance: 5_500_000),
    Fund(id: 2, name: '글로벌채권 인덱스', rate: -1.1, balance: 4_000_000),
    Fund(id: 3, name: '미국기술주 펀드', rate: 6.5, balance: 6_200_000),
    Fund(id: 4, name: '친환경 인프라 펀드', rate: 1.7, balance: 2_800_000),
  ];

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(myFunds: _myFunds, investType: '공격 투자형', userName: '뚜리'),
      const MyFinanceScreen(),
      const FundListScreen(),
      const SizedBox.shrink(), // 전체 메뉴 자리
    ];
  }

  Future<void> _openFullMenu() async {
    // 열릴 때 시스템바 컬러/아이콘 강제
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.bg,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: AppColors.bg,              // 상태바 배경
              statusBarIconBrightness: Brightness.dark,  // 안드로이드 아이콘
              statusBarBrightness: Brightness.light,     // iOS
            ),
            child: Material(
              color: AppColors.bg, // 오버레이 뒷배경도 동일 톤
              child: SafeArea(
                child: FullMenuOverlay(
                  userName: '이유저',
                  userId: '@user01',
                  onGoFundMain: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    setState(() => _index = 0);
                  },
                  onGoFundJoin: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    setState(() => _index = 2);
                  },
                  onGoInvestAnalysis: () {
                    Navigator.of(context, rootNavigator: true).pop(); // 오버레이 닫기
                    navigatorKey.currentState?.pushNamed(             // 전역 push
                      AppRoutes.investType,
                      arguments: 1, // 여기 로그인 세션의 USER_ID로 교체. 임시 1
                    );
                  },
                  onGoFAQ: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    navigatorKey.currentState?.pushNamed(AppRoutes.faq);
                  },
                  onGoGuide: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    navigatorKey.currentState?.pushNamed(AppRoutes.guide);
                  },
                  onGoMbti: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    navigatorKey.currentState?.pushNamed(AppRoutes.fundMbti);
                  },
                  onGoForum: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  onLogout: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  onAsk: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.of(context).pushNamed(AppRoutes.qnaCompose);
                  },
                  onMyQna: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.of(context).pushNamed(AppRoutes.qnaList);
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await showExitPopup(context);
        }
      },
      child: Scaffold(
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
      ),
    );
  }
}