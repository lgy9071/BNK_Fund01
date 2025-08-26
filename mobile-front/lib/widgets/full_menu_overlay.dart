import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_front/core/constants/api.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/core/services/review_api.dart';
import 'package:mobile_front/screens/fund_review/review_fund_list_screen.dart';
import 'package:mobile_front/widgets/show_custom_confirm_dialog.dart';
import '../core/actions/auth_actions.dart';
import '../screens/fund_mbti_flow.dart';

//서버에서 내정보를 가져오기 위한 의존성
import 'package:mobile_front/core/services/user_service.dart';
import 'package:mobile_front/models/user_profile.dart';
//import 'package:mobile_front/utils/session_manager.dart';

const tossBlue = Color(0xFF0064FF);
Color pastel(Color c) => c.withOpacity(.12);

class FullMenuOverlay extends StatefulWidget {
  final String userName;
  final String userId;

  final UserService? userService;
  final String? accessToken;

  final VoidCallback onGoFundMain;
  final VoidCallback onGoFundJoin;
  final VoidCallback onGoInvestAnalysis;

  final VoidCallback onGoFAQ;
  final VoidCallback onGoGuide;
  final VoidCallback onGoMbti;
  final VoidCallback onGoForum;

  final VoidCallback onLogout;
  final VoidCallback onAsk;
  final VoidCallback onMyQna;
  final VoidCallback onFundStatus;

  const FullMenuOverlay({
    super.key,
    required this.userName,
    required this.userId,
    required this.onGoFundMain,
    required this.onGoFundJoin,
    required this.onGoInvestAnalysis,
    required this.onGoFAQ,
    required this.onGoGuide,
    required this.onGoMbti,
    required this.onGoForum,
    required this.onLogout,
    required this.onAsk,
    required this.onMyQna,
    required this.onFundStatus,

    this.userService,
    this.accessToken,
  });

  @override
  State<FullMenuOverlay> createState() => _FullMenuOverlayState();
}

class _FullMenuOverlayState extends State<FullMenuOverlay> {
  double _dragAccum = 0;
  static const _kDismissThreshold = 80;

  // 프로필 비동기 로딩 Future
  Future<UserProfile?>? _meFuture;

  @override
  void initState() {
    super.initState();
    _applySystemBars();
    _meFuture = _loadMe(); // API 호출 시작
  }

  // SessionManager가 있으면 토큰을 얻어 사용, 실패해도 안전 폴백
  Future<UserProfile?> _loadMe() async {
    try {
      final svc = widget.userService ?? UserService();
      // 1) 우선 주입된 토큰 사용
      String? token = widget.accessToken;

      // 디버그용
      debugPrint('FullMenuOverlay.accessToken? ${
          token == null ? "null" : token.substring(0, math.min(12, token.length)) + "..."
      }');

      if (token == null || token.isEmpty) return null; // 토큰 없으면 패스

      // UserService가 token을 받는 시그니처라면 ↓ 사용
      return await svc.getMe(token);

      // 만약 UserService가 내부에서 dio(세션매니저)를 쓰는 형태라면:
      // return await svc.getMe();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _restoreSystemBars();
    super.dispose();
  }

  void _applySystemBars() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: AppColors.bg,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.bg,
    ));
  }

  // 필요 없으면 이 복원 로직은 제거(앱 전역에서 관리 시)
  void _restoreSystemBars() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  void _maybePop() => Navigator.of(context, rootNavigator: true).pop();

  // 터치/스크롤 시 세션 리셋(세션 매니저 없으면 조용히 무시)
  void _pingSession() {
    // no-op: SessionManager 싱글톤이 없으므로 아무 것도 하지 않음
  }

  Future<void> goToReviewWriteFlow(BuildContext context, ReviewApi api) async {
    final holdings = await api.getMyHoldingFunds();
    if (holdings.isEmpty) {
      await showAppConfirmDialog(
        context: context,
        title: '안내',
        message: '구매한 펀드가 없습니다.\n펀드 구매 후 이용해주세요.',
        confirmText: '확인',
        showCancel: false,
      );
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReviewFundListScreen(api: api, funds: holdings),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg, // 상태바/내비바와 톤 맞춤
      body: Stack(
        children: [
          // 본문(스와이프 닫기)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (_) => _pingSession(),
              onHorizontalDragUpdate: (d) {
                _dragAccum += d.delta.dx;
                _pingSession();
                if (_dragAccum > _kDismissThreshold) _maybePop();
              },
              onHorizontalDragEnd: (_) => _dragAccum = 0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 내정보 불러오기(FutureBuilder, 실패 시 props 폴백)
                    FutureBuilder<UserProfile?>(
                      future: _meFuture,
                      builder: (_, snap) {
                        final waiting = snap.connectionState == ConnectionState.waiting;

                        // 에러여도 props 폴백으로 카드 보여줄 거라서 여기서는 로그만
                        if (snap.hasError) {
                          debugPrint('getMe error: ${snap.error}');
                        }

                        final data = snap.data;
                        final name  = (data != null && data.name.isNotEmpty)  ? data.name  : widget.userName;
                        final idTxt = (data != null && data.email.isNotEmpty) ? data.email : widget.userId;

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, anim) {
                            final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
                            return FadeTransition(
                              opacity: curved,
                              child: SlideTransition(
                                position: Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero).animate(curved),
                                child: child,
                              ),
                            );
                          },
                          child: waiting
                              ? const _ProfileSkeleton(key: ValueKey('ske'))
                              : _ProfileCard(
                            key: const ValueKey('real'),
                            userName: name,
                            userId: idTxt,
                            onLogout: widget.onLogout,
                            onAsk: widget.onAsk,
                            onMyQna: widget.onMyQna,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    const _SectionTitle(title: '펀드 메뉴'),
                    const SizedBox(height: 8),
                    _MenuList(items: [
                      _MenuItemData(
                        title: '펀드 가입',
                        onTap: widget.onGoFundJoin,
                        assetPath: 'assets/icons/ic_join.png',
                      ),
                      _MenuItemData(
                        title: '투자성향분석',
                        onTap: widget.onGoInvestAnalysis,
                        assetPath: 'assets/icons/ic_analytics.png',
                      ),
                      _MenuItemData(
                        title: '리뷰 작성',
                        onTap: () {
                          final api = ReviewApi(
                            baseUrl: ApiConfig.baseUrl,
                            accessToken: widget.accessToken ?? '', // secureStorage에서 읽어온 토큰
                          );
                          goToReviewWriteFlow(context, api);
                        },
                        assetPath: 'assets/icons/ic_review.png',
                      ),
                    ]),
                    const SizedBox(height: 20),

                    const _SectionTitle(title: '고객 지원 메뉴'),
                    const SizedBox(height: 8),
                    _MenuList(items: [
                      _MenuItemData(
                        title: 'FAQ',
                        onTap: widget.onGoFAQ,
                        assetPath: 'assets/icons/ic_faq.png',
                      ),
                      _MenuItemData(
                        title: '펀드 이용 가이드',
                        onTap: widget.onGoGuide,
                        assetPath: 'assets/icons/ic_guide.png',
                      ),
                      _MenuItemData(
                        title: '펀드 시황',
                        onTap: widget.onFundStatus,
                        assetPath: 'assets/icons/ic_news.png',
                      ),
                      _MenuItemData(
                        title: '펀드 MBTI',
                        onTap: () {
                          // root 네비게이터를 먼저 잡아두고
                          final nav = Navigator.of(context, rootNavigator: true);

                          // 오버레이 닫기
                          nav.pop();

                          // 다음 프레임에 MBTI 화면으로 이동
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            nav.push(
                              MaterialPageRoute(builder: (_) => const FundMbtiFlowScreen()),
                            );
                          });
                        },
                        assetPath: 'assets/icons/ic_mbti.png',
                      ),
                      _MenuItemData(
                        title: '펀토방',
                        onTap: widget.onGoForum,
                        assetPath: 'assets/icons/ic_forum.png',
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 홈 버튼
                IconButton(
                  icon: const Icon(Icons.home_outlined, color: AppColors.fontColor),
                  tooltip: '홈',
                  onPressed: widget.onGoFundMain,
                ),
                // 닫기 버튼
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.fontColor),
                  tooltip: '닫기',
                  onPressed: _maybePop,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────────── 보조 위젯 ───────────── */

class _ProfileCard extends StatelessWidget {
  final String userName, userId;
  final VoidCallback onLogout, onAsk, onMyQna;
  const _ProfileCard({
    super.key,
    required this.userName,
    required this.userId,
    required this.onLogout,
    required this.onAsk,
    required this.onMyQna,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all( // 테두리 라인 추가
          color: Colors.grey.withOpacity(.3),
          width: 1,
        ),
      ),
      child: Card(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.all(6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFEFF4FF),
                    child: Icon(Icons.person, color: tossBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.fontColor)),
                        Text(userId,
                            style: TextStyle(
                                color: AppColors.fontColor.withOpacity(.7))),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: '닫기',
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
                          content: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '로그아웃',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 23,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF383E56),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                const Text(
                                  '정말 로그아웃 하시겠어요?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.4,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 25),
                                Row(
                                  children: [
                                    // 취소 버튼(왼쪽) - 디자인 동일
                                    Expanded(
                                      child: TextButton(
                                        onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
                                        style: TextButton.styleFrom(
                                          backgroundColor: const Color(0xFFF0F1F5),
                                          foregroundColor: const Color(0xFF383E56),
                                          shape: const StadiumBorder(),
                                          minimumSize: const Size.fromHeight(48),
                                        ),
                                        child: const Text(
                                          '취소',
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // 로그아웃 버튼(오른쪽) - 메인 컬러
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primaryBlue,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: const StadiumBorder(),
                                          minimumSize: const Size.fromHeight(48),
                                        ),
                                        child: const Text(
                                          '로그아웃',
                                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );

                      if (ok == true) {
                        await AuthActions.logout(context, callServer: true);
                      }
                    },
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onAsk,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.fontColor,
                        side: BorderSide(
                            color: AppColors.fontColor.withOpacity(.35)),
                      ),
                      child: const Text('문의하기'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: onMyQna,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF6F8FF),
                        foregroundColor: AppColors.fontColor,
                      ),
                      child: const Text('내 문의'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: AppColors.fontColor,
    ),
  );
}

class _MenuItemData {
  final String title;
  final VoidCallback onTap;
  final String assetPath;

  _MenuItemData({
    required this.title,
    required this.onTap,
    required this.assetPath
  });
}

class _MenuList extends StatelessWidget {
  final List<_MenuItemData> items;
  const _MenuList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(.3), width: 1),
      ),
      //
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              ListTile(
                leading: Image.asset(
                  items[i].assetPath,
                  width: 26, height: 26, fit: BoxFit.contain,
                ),
                title: Text(
                  items[i].title,
                  style: const TextStyle(color: AppColors.fontColor, fontSize: 16),
                ),
                trailing: Icon(Icons.chevron_right,
                    color: AppColors.fontColor.withOpacity(.54)),
                onTap: items[i].onTap,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              ),
              if (i != items.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Divider(height: 1, thickness: 1,
                      color: Colors.grey.withOpacity(.25)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(.3), width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 상단 프로필 행
            Row(
              children: [
                // 아바타 자리
                Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDEFF3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                // 이름/아이디 자리
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(width: 120, height: 16),
                      const SizedBox(height: 8),
                      _bar(width: 160, height: 14),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 로그아웃 버튼 자리
                _pill(width: 68, height: 32),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            // 하단 버튼 2개 자리
            Row(
              children: [
                Expanded(child: _pill(height: 44)),
                const SizedBox(width: 8),
                Expanded(child: _pill(height: 44)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _bar({required double width, required double height}) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFF3),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  static Widget _pill({double? width, required double height}) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
    );
  }
}
