import 'package:flutter/material.dart';
import 'models/fund.dart';
import 'screens/home_screen.dart';
import 'widgets/full_menu_overlay.dart';
import 'screens/fund_join_screen.dart';
import 'screens/my_finance_screen.dart';
import 'dev_jiyong/main_home.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _mode = ThemeMode.light;
  void _toggleTheme() {
    setState(() {
      _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BNK Fund',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0064FF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0064FF),
          brightness: Brightness.dark,
        ),
      ),
      home: const MainScaffold(),
    );
  }
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

  final _myFunds = <Fund>[
    Fund(id: 1, name: '한국성장주식 A', rate: 3.2, balance: 5_500_000),
    Fund(id: 2, name: '글로벌채권 인덱스', rate: -1.1, balance: 4_000_000),
    Fund(id: 3, name: '미국기술주 펀드', rate: 6.5, balance: 6_200_000),
    Fund(id: 4, name: '친환경 인프라 펀드', rate: 1.7, balance: 2_800_000),
  ];

  late final List<Widget> _pages;  // <- 한 번만 생성

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(
        myFunds: _myFunds,
        investType: '공격 투자형',
        userName: '@@',
      ),
      const MyFinanceScreen(),
      const FundJoinScreen(),
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
                  // TODO: 이동 or 화면 열기
                },
                onGoFAQ: () { Navigator.of(context, rootNavigator: true).pop(); },
                onGoGuide: () { Navigator.of(context, rootNavigator: true).pop(); },
                onGoMbti: () { Navigator.of(context, rootNavigator: true).pop(); },
                onGoForum: () { Navigator.of(context, rootNavigator: true).pop(); },
                onEditProfile: () { Navigator.of(context, rootNavigator: true).pop(); },
                onAsk: () { Navigator.of(context, rootNavigator: true).pop(); },
                onMyQna: () { Navigator.of(context, rootNavigator: true).pop(); },
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
      // ★ IndexedStack으로 상태 보존 (4번 해결 포인트)
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == 3) {
            _openFullMenu(); // 인덱스 바꾸지 않고 메뉴만 띄움
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