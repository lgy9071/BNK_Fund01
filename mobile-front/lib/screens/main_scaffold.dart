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
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;
  String? _accessToken; // 항상 SecureStorage에서 로드
  late List<Widget> _pages;
  String? _investTypeName; // 투자성향 이름 저장

  /// 홈 강제 새로고침 트리거 (값이 바뀌면 HomeScreen Key가 바뀌어 재생성됨)
  int _homeRefreshTick = 0;

  final _myFunds = <Fund>[
    Fund(id: 1, name: '한국성장주식 A', rate: 3.2, balance: 5_500_000),
    Fund(id: 2, name: '글로벌채권 인덱스', rate: -1.1, balance: 4_000_000),
    Fund(id: 3, name: '미국기술주 펀드', rate: 6.5, balance: 6_200_000),
    Fund(id: 4, name: '친환경 인프라 펀드', rate: 1.7, balance: 2_800_000),
  ];

  @override
  void initState() {
    super.initState();
    _buildPages();      // 초기 페이지 구성 (토큰 null일 수 있음)
    _loadUserInfo();    // SecureStorage에서 토큰 읽고 /me 호출
  }

  void _buildPages() {
    _pages = [
      HomeScreen(
        key: ValueKey('home-$_homeRefreshTick'),
        myFunds: _myFunds,
        investType: _investTypeName ?? '공격 투자형',
        userName: '@@',
        accessToken: _accessToken,      // 항상 storage에서 읽은 토큰 사용
        userService: UserService(),
        onStartInvestFlow: () async {
          final bool? result = await Navigator.pushNamed<bool?>(context, AppRoutes.investType);
          if (result == true) {
            if (!mounted) return;
            setState(() => _index = 0);   // 홈 탭으로 이동
            _bumpHomeRefresh();           // 홈 강제 리로드 (Key 변경)
            await _loadUserInfo();        // 서버 최신 데이터 재조회
          }
        },
      ),
      MyFinanceScreen(
        accessToken: _initialAccessToken,
        userService: UserService(),
      ),
      const FundListScreen(),
      const SizedBox.shrink(),
    ];
  }

  Future<void> _loadUserInfo() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'accessToken');

    if (token == null || token.isEmpty) {
      debugPrint("MainScaffold: no accessToken in storage");
      setState(() {
        _accessToken = null;
        _buildPages();
      });
      return;
    }

    try {
      final svc = UserService();
      final me = await svc.getMe(token);
      setState(() {
        _accessToken = token; // 🔥 토큰 상태 저장
        _investTypeName = me.typename.isNotEmpty ? me.typename : null;
        _bumpHomeRefresh();   // 🔥 토큰 로드 이후 홈을 재생성해서 HomeScreen이 새 토큰으로 초기화되도록
      });
    } catch (e) {
      debugPrint("MainScaffold.getMe failed: $e");
    }
  }

  void _bumpHomeRefresh() {
    _homeRefreshTick++;
    _buildPages(); // Key 반영을 위해 페이지 재구성
  }

  Future<void> _openFullMenu() async {
    // 우선 상태의 토큰 사용, 없으면 스토리지 보조 조회
    String? accessToken = _accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      const storage = FlutterSecureStorage();
      accessToken = await storage.read(key: 'accessToken');
    }

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
                  accessToken: accessToken,   // 메뉴 오버레이 기능에 토큰 전달
                  userService: UserService(),
                  onGoFundMain: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    setState(() => _index = 0);
                  },
                  onGoFundJoin: () async {
                    if (_investTypeName == null || _investTypeName!.isEmpty) {
                      final go = await showAppConfirmDialog(
                        context: context,
                        title: "안내",
                        message: "펀드 가입을 위해서는 투자성향 \n분석이 필요합니다 진행하시겠습니까?",
                        confirmText: "분석진행",
                        cancelText: "취소",
                        confirmColor: AppColors.primaryBlue,
                      );
                      if (go == true) {
                        final result = await Navigator.pushNamed(context, AppRoutes.investType);
                        if (result == true) {
                          setState(() => _index = 0);
                          _bumpHomeRefresh();
                          _loadUserInfo();
                        }
                      }
                      return;
                    }else{
                      Navigator.of(context, rootNavigator: true).pop();
                      setState(() => _index = 2);
                    }
                  },
                  onGoInvestAnalysis: () async {
                    Navigator.of(context, rootNavigator: true).pop();
                    final result = await navigatorKey.currentState?.pushNamed(AppRoutes.investType);
                    if (result == true) {
                      setState(() => _index = 0);
                      _bumpHomeRefresh();
                      _loadUserInfo();
                    }
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
                  onFundStatus: (){
                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.of(context).pushNamed(AppRoutes.fundStatus);
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

            // 같은 탭 재탭 → 홈 리로드
            if (_index == i) {
              if (i == 0) {
                _bumpHomeRefresh();
              }
              return;
            }

            // 펀드 가입 탭 가드
            if (i == 2) {
              if (_investTypeName == null || _investTypeName!.isEmpty) {
                final go = await showAppConfirmDialog(
                  context: context,
                  title: "안내",
                  message: "펀드 가입을 위해서는 투자성향 \n분석이 필요합니다 진행하시겠습니까?",
                  confirmText: "분석진행",
                  cancelText: "취소",
                  confirmColor: AppColors.primaryBlue,
                );
                if (go == true) {
                  final result = await Navigator.pushNamed(context, AppRoutes.investType);
                  if (result == true) {
                    setState(() => _index = 0);
                    _bumpHomeRefresh();
                    _loadUserInfo();
                  }
                }
                return;
              }
            }

            setState(() => _index = i); // 정상 이동
          },
        ),
      ),
    );
  }
}
