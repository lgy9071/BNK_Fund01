import 'package:flutter/material.dart';
import 'models/fund.dart';
import 'screens/home_screen.dart';
import 'widgets/full_menu_overlay.dart';
import 'screens/fund_join_screen.dart';
import 'screens/my_finance_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BNK Fund',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0064FF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MainScaffold(),
    );
  }
}

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
                onGoFundMain: () { Navigator.of(context, rootNavigator: true).pop(); setState(() => _index = 0); },
                onGoFundJoin: () { Navigator.of(context, rootNavigator: true).pop(); setState(() => _index = 2); },
                onGoInvestAnalysis: () { Navigator.of(context, rootNavigator: true).pop(); },
                onGoFAQ: () { Navigator.of(context, rootNavigator: true).pop(); },
                onGoGuide: () { Navigator.of(context, rootNavigator: true).pop(); },
                onGoMbti: () { Navigator.of(context, rootNavigator: true).pop(); },
                onGoForum: () { Navigator.of(context, rootNavigator: true).pop(); },
                onEditProfile: () {},
                onAsk: () {},
                onMyQna: () {},
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(myFunds: _myFunds, investType: '공격 투자형', userName: '@@'),
      MyFinanceScreen(),
      const FundJoinScreen(),
      const SizedBox.shrink(),
    ];

    return Scaffold(
      body: _index == 3 ? pages[0] : pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == 3) {
            _openFullMenu();
            return;
          }
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(icon: Icon(Icons.account_balance), label: '내 금융'),
          NavigationDestination(icon: Icon(Icons.playlist_add), label: '펀드 가입'),
          NavigationDestination(icon: Icon(Icons.apps), label: '전체'),
        ],
      ),
    );
  }
}