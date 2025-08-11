import 'package:flutter/material.dart';
import 'package:mobile_front/utils/exit_popup.dart';
import '../models/fund.dart';
import '../screens/home_screen.dart';
import '../screens/my_finance_screen.dart';
import '../screens/fund_join_screen.dart';
import '../widgets/full_menu_overlay.dart';
import '../widgets/circle_nav_bar.dart';

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
      HomeScreen(myFunds: _myFunds, investType: '공격 투자형', userName: '@@'),
      const MyFinanceScreen(),
      const FundJoinScreen(),
      const SizedBox.shrink(), // 전체 메뉴 자리
    ];
  }

  Future<void> _openFullMenu() async {
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
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              child: FullMenuOverlay(
                userName: '이유저',
                userId: '@user01',
                onGoFundMain: () { Navigator.of(context, rootNavigator: true).pop(); setState(() => _index = 0); },
                onGoFundJoin: () { Navigator.of(context, rootNavigator: true).pop(); setState(() => _index = 2); },
                onGoInvestAnalysis: () { Navigator.of(context, rootNavigator: true).pop(); /* TODO */ },
                onGoFAQ: () { Navigator.of(context, rootNavigator: true).pop(); Navigator.of(context).pushNamed('/faq'); },
                onGoGuide: () { Navigator.of(context, rootNavigator: true).pop(); Navigator.of(context).pushNamed('/guide'); },
                onGoMbti: () { Navigator.of(context, rootNavigator: true).pop(); /* TODO */ },
                onGoForum: () { Navigator.of(context, rootNavigator: true).pop(); /* TODO */ },
                onLogout: () { Navigator.of(context, rootNavigator: true).pop(); /* TODO: logout */ },
                onAsk: () { Navigator.of(context, rootNavigator: true).pop(); Navigator.of(context).pushNamed('/qna/compose'); },
                onMyQna: () { Navigator.of(context, rootNavigator: true).pop(); Navigator.of(context).pushNamed('/qna/list'); },
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
      child:  Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: CircleNavBar(
        currentIndex: _index,
        onTap: (i) {
          if (i == 3) { _openFullMenu(); return; }
          setState(() => _index = i);
        },
      ),
    )
    );
  }
}