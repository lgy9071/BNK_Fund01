import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_front/core/constants/colors.dart';

import '../core/actions/auth_actions.dart';

const tossBlue = Color(0xFF0064FF);
Color pastel(Color c) => c.withOpacity(.12);

class FullMenuOverlay extends StatefulWidget {
  final String userName;
  final String userId;

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
  });

  @override
  State<FullMenuOverlay> createState() => _FullMenuOverlayState();
}

class _FullMenuOverlayState extends State<FullMenuOverlay> {
  double _dragAccum = 0;
  static const _kDismissThreshold = 80;

  @override
  void initState() {
    super.initState();
    _applySystemBars();
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
              onHorizontalDragUpdate: (d) {
                _dragAccum += d.delta.dx;
                if (_dragAccum > _kDismissThreshold) _maybePop();
              },
              onHorizontalDragEnd: (_) => _dragAccum = 0,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileCard(
                      userName: widget.userName,
                      userId: widget.userId,
                      onLogout: widget.onLogout,
                      onAsk: widget.onAsk,
                      onMyQna: widget.onMyQna,
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
                        title: '펀드 MBTI',
                        onTap: widget.onGoMbti,
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