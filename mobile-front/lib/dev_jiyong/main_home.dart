import 'package:flutter/material.dart';
import '../widgets/circle_nav_bar.dart';        // 동그라미 네브바
import '../models/fund.dart';
import '../screens/home_screen.dart';
import '../screens/my_finance_screen.dart';
import '../screens/fund_list_screen.dart';
import '../widgets/full_menu_overlay.dart';    // 전체 메뉴 오버레이(있다면)

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

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

  Future<void> _openFullMenu() async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
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
                  Navigator.of(context, rootNavigator: true).pop();
                  // TODO: 분석 화면 연결
                },
                onGoFAQ: () { Navigator.of(context, rootNavigator: true).pop(); },
                onGoGuide: () { Navigator.of(context, rootNavigator: true).pop(); },
                onGoMbti: () { Navigator.of(context, rootNavigator: true).pop(); },
                onGoForum: () { Navigator.of(context, rootNavigator: true).pop(); },

                // 🔐 로그아웃
                onLogout: () {
                  Navigator.of(context, rootNavigator: true).pop(); // 오버레이 닫기
                  // TODO: 토큰 삭제/로그아웃 처리
                  // Navigator.of(context).pushReplacementNamed('/login');
                },

                // 📨 1:1 문의 작성
                onAsk: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  Navigator.of(context).pushNamed('/qna/compose');
                },

                // 📁 내 문의 목록
                onMyQna: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  Navigator.of(context).pushNamed('/qna/list');
                },
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
      // 탭 상태 유지
      body: IndexedStack(index: _index, children: _pages),

      // 동그라미 네브바
      bottomNavigationBar: CircleNavBar(
        currentIndex: _index,
        onTap: (i) {
          if (i == 3) { // 전체
            _openFullMenu();
            return;
          }
          setState(() => _index = i);
        },
      ),
    );
  }
}