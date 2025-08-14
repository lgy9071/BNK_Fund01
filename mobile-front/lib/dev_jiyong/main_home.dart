import 'package:flutter/material.dart';
import 'package:mobile_front/utils/exit_guard.dart';
import '../widgets/circle_nav_bar.dart';        // 동그라미 네브바
import '../models/fund.dart';
import '../screens/home_screen.dart';
import '../screens/my_finance_screen.dart';
import '../screens/fund_list_screen.dart';
import '../widgets/full_menu_overlay.dart';    // 전체 메뉴 오버레이(있다면)
import 'package:flutter/services.dart';
import 'package:mobile_front/core/routes/routes.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/models/fund.dart';
import 'package:mobile_front/screens/home_screen.dart';
import 'package:mobile_front/screens/my_finance_screen.dart';
import 'package:mobile_front/screens/fund_list_screen.dart';
import 'package:mobile_front/widgets/full_menu_overlay.dart';
import 'package:mobile_front/widgets/circle_nav_bar.dart';
import 'package:mobile_front/utils/exit_popup.dart';
import 'package:mobile_front/main.dart' show navigatorKey;

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;
  bool _exiting = false; // ← 재진입 방지 플래그

  // 데모/실제 데이터 연결
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
      HomeScreen(myFunds: _myFunds, investType: '공격 투자형', userName: '@@'),
      const MyFinanceScreen(),
      const FundListScreen(),          // ← main_join 기능을 여기로 흡수
      const SizedBox.shrink(),         // 전체(오버레이용 자리만 차지)
    ];
  }

  /// 오버레이 닫고 전역 라우팅 (합본/개인 동일!)
  void _go(String route) {
    Navigator.of(context, rootNavigator: true).pop(); // 오버레이 닫기
    // 다음 프레임에서 안전하게 push
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushNamed(route);
    });
  }

  Future<void> _openFullMenu() async {
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
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: Material(
            color: AppColors.bg,
            child: SafeArea(
              child: FullMenuOverlay(
                userName: '이유저',
                userId: '@user01',

                // 탭 전환(메인 내부 이동) — setState
                onGoFundMain: () { Navigator.of(context, rootNavigator: true).pop(); setState(() => _index = 0); },
                onGoFundJoin: () { Navigator.of(context, rootNavigator: true).pop(); setState(() => _index = 2); },

                // 전역 라우팅(새 화면) — 항상 navigatorKey 사용
                onGoInvestAnalysis: () => _go(AppRoutes.investType),
                onGoFAQ: () => _go(AppRoutes.faq),
                onGoGuide: () => _go(AppRoutes.guide),
                onGoMbti: () {},   // 추후 route 연결 시 _go('...')로
                onGoForum: () {},  // 추후 route 연결 시 _go('...')로

                onLogout: () { Navigator.of(context, rootNavigator: true).pop(); /* TODO: 로그아웃 처리 */ },

                // 내 문의/문의하기도 전역 라우팅으로 통일
                onAsk:   () => _go(AppRoutes.qnaCompose),
                onMyQna: () => _go(AppRoutes.qnaList),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExitGuard(
      child: Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: CircleNavBar(
          currentIndex: _index,
          onTap: (i) {
            if (i == 3) { _openFullMenu(); return; }
            setState(() => _index = i);
          },
        ),
      ),
    );
  }
}