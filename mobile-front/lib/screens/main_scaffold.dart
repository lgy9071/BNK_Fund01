import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_front/core/routes/routes.dart';
import 'package:mobile_front/utils/exit_guard.dart';
import 'package:mobile_front/widgets/show_custom_confirm_dialog.dart';

import '../core/constants/colors.dart';
import '../core/services/fund_service.dart';
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
  String? _accessToken;
  String? _investTypeName;
  String? _userId;              // 🆕 userId 추가
  late List<Widget> _pages;

  /// 홈 강제 새로고침 트리거
  int _homeRefreshTick = 0;

  // 🔄 하드코딩된 데이터를 동적 데이터로 변경
  List<Fund> _myFunds = [];
  bool _fundsLoading = true;
  String? _fundsError;

  @override
  void initState() {
    super.initState();
    _buildPages();
    _loadUserInfo();
  }

  void _buildPages() {
    _pages = [
      HomeScreen(
        key: ValueKey('home-$_homeRefreshTick'),
        myFunds: _myFunds,
        fundsLoading: _fundsLoading,          // 🆕 로딩 상태 전달
        fundsError: _fundsError,              // 🆕 에러 상태 전달
        investType: _investTypeName ?? '공격투자형',
        userName: '@@',
        accessToken: _accessToken,
        userService: UserService(),
        onStartInvestFlow: () async {
          final bool? result = await Navigator.pushNamed<bool?>(context, AppRoutes.investType);
          if (result == true) {
            if (!mounted) return;
            setState(() => _index = 0);
            _bumpHomeRefresh();
            await _loadUserInfo();
          }
        },
        onRefreshFunds: _loadMyFunds,         // 🆕 펀드 새로고침 콜백
      ),
      MyFinanceScreen(
        accessToken: _accessToken,
        userService: UserService(),
        // myFunds: _myFunds,                    // 🆕 펀드 데이터 공유
        // fundsLoading: _fundsLoading,
      ),
      FundListScreen(
        accessToken: _accessToken,
        userService: UserService(),
      ),
      const SizedBox.shrink(),
    ];
  }

  /// 🆕 사용자 가입 펀드 목록 로드
  Future<void> _loadMyFunds() async {
    // 프레임 완료 후 상태 변경하도록 수정 (Build scheduled during frame 에러 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _fundsLoading = true;
          _fundsError = null;
        });
      }
    });

    try {
      // userId가 없으면 빈 리스트로 처리
      if (_userId == null || _userId!.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _myFunds = [];
              _fundsLoading = false;
            });
            _buildPages();
          }
        });
        return;
      }

      final fundService = FundService();
      final funds = await fundService.getMyFunds(_userId!);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _myFunds = funds;
            _fundsLoading = false;
            _fundsError = null;
          });
          _buildPages();
        }
      });

    } catch (e) {
      debugPrint('Failed to load my funds: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _myFunds = [];
            _fundsLoading = false;
            _fundsError = e.toString();
          });
          _buildPages();
        }
      });
    }
  }

  Future<void> _loadUserInfo() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'accessToken');

    if (token == null || token.isEmpty) {
      debugPrint("MainScaffold: no accessToken in storage");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _accessToken = null;
            _userId = null;          // 🔄 userId도 초기화
            _investTypeName = null;
            _myFunds = [];
            _fundsLoading = false;
          });
          _buildPages();
        }
      });
      return;
    }

    try {
      final svc = UserService();
      final me = await svc.getMe(token);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          setState(() {
            _accessToken = token;
            _userId = me.userId.toString(); // 🆕 userId 설정
            _investTypeName = me.typename.isNotEmpty ? me.typename : null;
          });

          _bumpHomeRefresh();

          // 🔄 userId 설정 후 펀드 데이터 로드
          await _loadMyFunds();
        }
      });

    } catch (e) {
      debugPrint("MainScaffold.getMe failed: $e");
    }
  }

  void _bumpHomeRefresh() {
    _homeRefreshTick++;
    _buildPages();
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
                  userName: '이윤저',
                  userId: '@user01',
                  accessToken: accessToken,
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
                    } else {
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
                  onFundStatus: () {
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
